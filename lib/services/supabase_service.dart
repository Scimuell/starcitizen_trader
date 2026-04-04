import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_db.dart';

/// Manages Supabase connection and catalog sync/search for AI context.
///
/// Supabase table schema (run this SQL in your Supabase dashboard):
///
/// ```sql
/// create table catalog_items (
///   id bigint generated always as identity primary key,
///   name text not null,
///   patch text not null default '4.7'
/// );
///
/// create table catalog_offers (
///   id bigint generated always as identity primary key,
///   item_name text not null,
///   location text not null,
///   buy_auec bigint,
///   sell_auec bigint
/// );
///
/// create index on catalog_offers (item_name);
///
/// -- Enable full-text search on item name
/// alter table catalog_offers add column search_vec tsvector
///   generated always as (to_tsvector('english', item_name || ' ' || location)) stored;
/// create index on catalog_offers using gin(search_vec);
/// ```
class SupabaseService {
  static const _kUrl = 'supabase_url';
  static const _kAnonKey = 'supabase_anon_key';
  static const _kEnabled = 'supabase_enabled';

  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  bool _initialized = false;

  Future<String> getUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUrl) ?? '';
  }

  Future<void> setUrl(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUrl, v.trim());
    _initialized = false;
  }

  Future<String?> getAnonKey() => _secure.read(key: _kAnonKey);

  Future<void> setAnonKey(String? v) async {
    if (v == null || v.trim().isEmpty) {
      await _secure.delete(key: _kAnonKey);
    } else {
      await _secure.write(key: _kAnonKey, value: v.trim());
    }
    _initialized = false;
  }

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, v);
  }

  Future<bool> isConfigured() async {
    final url = await getUrl();
    final key = await getAnonKey();
    return url.isNotEmpty && key != null && key.isNotEmpty;
  }

  /// Initialise Supabase client if not already done.
  Future<SupabaseClient?> _client() async {
    if (!await isConfigured()) return null;
    final url = await getUrl();
    final key = await getAnonKey();
    if (!_initialized) {
      try {
        await Supabase.initialize(url: url, anonKey: key!);
        _initialized = true;
      } catch (_) {
        // Already initialized — just grab the client
        _initialized = true;
      }
    }
    return Supabase.instance.client;
  }

  /// Upload the entire local SQLite catalog to Supabase.
  /// Clears existing rows first (upsert by item_name + location).
  Future<SupabaseSyncResult> uploadCatalog(AppDatabase db) async {
    final client = await _client();
    if (client == null) {
      return SupabaseSyncResult(success: false, message: 'Supabase not configured.');
    }

    try {
      // Fetch all items + offers from local DB
      const sql = '''
        SELECT ci.name, ci.patch, co.location, co.buy_auec, co.sell_auec
        FROM catalog_items ci
        LEFT JOIN catalog_offers co ON co.item_id = ci.id
        ORDER BY ci.name ASC
      ''';
      final rows = await db.rawQuery(sql);

      if (rows.isEmpty) {
        return SupabaseSyncResult(success: false, message: 'Local catalog is empty. Sync from UEX first.');
      }

      // Build upsert payload — flat rows (one per offer)
      final payload = rows
          .where((r) => r['location'] != null)
          .map((r) => {
                'item_name': r['name'] as String,
                'patch': r['patch'] as String? ?? '4.7',
                'location': r['location'] as String,
                'buy_auec': r['buy_auec'],
                'sell_auec': r['sell_auec'],
              })
          .toList();

      // Delete old data and re-insert in batches of 500
      await client.from('catalog_offers').delete().neq('id', 0);

      int uploaded = 0;
      const batchSize = 500;
      for (var i = 0; i < payload.length; i += batchSize) {
        final batch = payload.sublist(i, i + batchSize > payload.length ? payload.length : i + batchSize);
        await client.from('catalog_offers').insert(batch);
        uploaded += batch.length;
      }

      return SupabaseSyncResult(
        success: true,
        message: 'Uploaded $uploaded offer rows to Supabase.',
      );
    } catch (e) {
      return SupabaseSyncResult(success: false, message: 'Upload failed: $e');
    }
  }

  /// Search Supabase for items matching [query] and return a compact
  /// context string for the AI. Only fetches relevant rows — much cheaper
  /// than sending the full catalog.
  Future<String> searchForAiContext(String query) async {
    final client = await _client();
    if (client == null) return '';

    try {
      // Extract meaningful words from the query
      final words = query
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .take(5)
          .toList();

      if (words.isEmpty) return '';

      // Build ILIKE filter — search item_name for any of the keywords
      // e.g. "aluminum OR gold OR quantanium"
      List<Map<String, dynamic>> rows = [];

      for (final word in words) {
        final result = await client
            .from('catalog_offers')
            .select('item_name, location, buy_auec, sell_auec')
            .ilike('item_name', '%$word%')
            .limit(30);
        rows.addAll(List<Map<String, dynamic>>.from(result));
        if (rows.length >= 60) break;
      }

      if (rows.isEmpty) return '';

      // Deduplicate and compress into AI format
      final seen = <String>{};
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final name = r['item_name'] as String? ?? '';
        final loc = r['location'] as String? ?? '';
        final key = '$name|$loc';
        if (seen.contains(key)) continue;
        seen.add(key);
        grouped.putIfAbsent(name, () => []).add(r);
      }

      final buf = StringBuffer();
      for (final entry in grouped.entries) {
        int? minBuy, maxSell;
        final locs = <String>[];
        for (final o in entry.value) {
          final buy = o['buy_auec'];
          final sell = o['sell_auec'];
          if (buy != null) {
            final b = (buy as num).toInt();
            if (minBuy == null || b < minBuy) minBuy = b;
          }
          if (sell != null) {
            final s = (sell as num).toInt();
            if (maxSell == null || s > maxSell) maxSell = s;
          }
          final loc = (o['location'] as String? ?? '')
              .replaceAll(' — ', '/')
              .replaceAll('Terminal', 'T')
              .replaceAll('Station', 'Sta')
              .replaceAll('New Babbage', 'NB')
              .replaceAll('Lorville', 'LV')
              .replaceAll('Area18', 'A18');
          if (loc.isNotEmpty && !locs.contains(loc)) locs.add(loc);
        }
        buf.writeln('${entry.key}:${minBuy ?? '-'}b/${maxSell ?? '-'}s[${locs.take(5).join(',')}]');
      }
      return buf.toString();
    } catch (e) {
      return '';
    }
  }

  /// Test connection — returns null on success, error message on failure.
  Future<String?> testConnection() async {
    final client = await _client();
    if (client == null) return 'Supabase URL or anon key not set.';
    try {
      await client.from('catalog_offers').select('id').limit(1);
      return null;
    } catch (e) {
      return 'Connection failed: $e';
    }
  }
}

class SupabaseSyncResult {
  SupabaseSyncResult({required this.success, required this.message});
  final bool success;
  final String message;
}
