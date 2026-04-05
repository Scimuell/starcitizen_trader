import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_db.dart';

/// Manages Supabase connection, catalog upload, and smart AI context search.
///
/// Run this SQL in your Supabase SQL Editor before using:
/// ```sql
/// create table catalog_offers (
///   id bigint generated always as identity primary key,
///   item_name text not null,
///   patch text default '4.7',
///   location text not null,
///   buy_auec bigint,
///   sell_auec bigint
/// );
/// create index on catalog_offers (item_name);
/// create index on catalog_offers (location);
///
/// create table sc_locations (
///   id bigint generated always as identity primary key,
///   location_name text not null unique,
///   system_name text not null,
///   location_type text,
///   parent_location text,
///   aliases text,
///   notes text
/// );
/// create index on sc_locations (location_name);
/// create index on sc_locations (system_name);
///
/// create table sc_location_distances (
///   id bigint generated always as identity primary key,
///   from_location text not null,
///   to_location text not null,
///   distance_rank int not null,
///   distance_label text,
///   travel_note text
/// );
/// create index on sc_location_distances (from_location);
/// create index on sc_location_distances (to_location);
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

  Future<SupabaseClient?> _client() async {
    if (!await isConfigured()) return null;
    final url = await getUrl();
    final key = await getAnonKey();
    if (!_initialized) {
      try {
        await Supabase.initialize(url: url, anonKey: key!);
      } catch (_) {}
      _initialized = true;
    }
    return Supabase.instance.client;
  }

  /// Upload entire local catalog to Supabase in batches.
  /// Only needs to be done once — data persists in the cloud.
  Future<SupabaseSyncResult> uploadCatalog(AppDatabase db) async {
    final client = await _client();
    if (client == null) {
      return SupabaseSyncResult(success: false, message: 'Supabase not configured.');
    }
    try {
      const sql = '''
        SELECT ci.name, ci.patch, co.location, co.buy_auec, co.sell_auec
        FROM catalog_items ci
        LEFT JOIN catalog_offers co ON co.item_id = ci.id
        ORDER BY ci.name ASC
      ''';
      final rows = await db.rawQuery(sql);
      if (rows.isEmpty) {
        return SupabaseSyncResult(success: false, message: 'Local catalog empty. Sync from UEX first.');
      }

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

      // Clear old data
      await client.from('catalog_offers').delete().neq('id', 0);

      // Upload in batches of 500
      int uploaded = 0;
      const batchSize = 500;
      for (var i = 0; i < payload.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, payload.length);
        await client.from('catalog_offers').insert(payload.sublist(i, end));
        uploaded += end - i;
      }

      return SupabaseSyncResult(success: true, message: 'Uploaded $uploaded rows to Supabase.');
    } catch (e) {
      return SupabaseSyncResult(success: false, message: 'Upload failed: $e');
    }
  }

  // Maps common player shorthand to actual location strings in the DB
  static const _locationAliases = <String, List<String>>{
    // Stanton - Hurston
    'lorville': ['lorville', 'hurston'],
    'hurston': ['lorville', 'hurston', 'everus'],
    'everus': ['everus harbor'],
    'hdms': ['hdms'],
    // Stanton - Crusader
    'orison': ['orison', 'crusader', 'seraphim'],
    'crusader': ['orison', 'crusader', 'seraphim', 'cellin', 'daymar', 'yela'],
    'grim hex': ['grim hex', 'yela'],
    // Stanton - ArcCorp
    'area18': ['area18', 'area 18', 'arccorp'],
    'arccorp': ['area18', 'area 18', 'arccorp', 'baijini', 'lyria', 'wala'],
    'baijini': ['baijini point'],
    'casaba': ['casaba'],
    'dumpers': ['dumper'],
    // Stanton - microTech
    'new babbage': ['new babbage', 'microtech'],
    'microtech': ['new babbage', 'microtech', 'tressler', 'calliope', 'clio'],
    'port tressler': ['port tressler'],
    // Pyro system (separate!)
    'pyro': ['pyro', 'checkmate', 'ruin station', 'orbituary'],
    'checkmate': ['checkmate station'],
    'ruin': ['ruin station'],
    'orbituary': ['orbituary'],
  };

  static const _stopWords = {
    'the', 'and', 'for', 'are', 'where', 'what', 'how', 'buy', 'sell',
    'find', 'get', 'can', 'closest', 'close', 'near', 'from', 'best',
    'good', 'cheap', 'price', 'cost', 'much', 'want', 'need', 'place',
    'station', 'terminal', 'location', 'please', 'would', 'could',
  };

  List<String> _extractLocationTerms(String query) {
    final q = query.toLowerCase();
    final locationTerms = <String>[];
    for (final entry in _locationAliases.entries) {
      if (q.contains(entry.key)) {
        locationTerms.addAll(entry.value);
      }
    }
    return locationTerms.toSet().toList();
  }

  Future<String> _buildLocationContext(
    SupabaseClient client,
    List<String> locationTerms,
  ) async {
    if (locationTerms.isEmpty) return '';

    try {
      final locationRows = <Map<String, dynamic>>[];
      final distanceRows = <Map<String, dynamic>>[];

      for (final term in locationTerms.take(4)) {
        final locResult = await client
            .from('sc_locations')
            .select(
              'location_name, system_name, location_type, parent_location, aliases, notes',
            )
            .or(
              'location_name.ilike.%$term%,aliases.ilike.%$term%,parent_location.ilike.%$term%',
            )
            .limit(8);
        locationRows.addAll(List<Map<String, dynamic>>.from(locResult));

        final distResult = await client
            .from('sc_location_distances')
            .select(
              'from_location, to_location, distance_rank, distance_label, travel_note',
            )
            .or(
              'from_location.ilike.%$term%,to_location.ilike.%$term%',
            )
            .order('distance_rank', ascending: true)
            .limit(12);
        distanceRows.addAll(List<Map<String, dynamic>>.from(distResult));
      }

      if (locationRows.isEmpty && distanceRows.isEmpty) return '';

      final dedupedLocations = <String, Map<String, dynamic>>{};
      for (final row in locationRows) {
        final key = (row['location_name'] as String? ?? '').trim().toLowerCase();
        if (key.isNotEmpty) dedupedLocations[key] = row;
      }

      final seenDistances = <String>{};
      final dedupedDistances = <Map<String, dynamic>>[];
      for (final row in distanceRows) {
        final key =
            '${row['from_location']}|${row['to_location']}|${row['distance_rank']}';
        if (seenDistances.add(key)) dedupedDistances.add(row);
      }

      final buf = StringBuffer();
      buf.writeln('LOCATION CONTEXT FROM SUPABASE:');

      if (dedupedLocations.isNotEmpty) {
        for (final row in dedupedLocations.values.take(10)) {
          final name = row['location_name'] as String? ?? '';
          final system = row['system_name'] as String? ?? '';
          final type = row['location_type'] as String? ?? '';
          final parent = row['parent_location'] as String? ?? '';
          final aliases = row['aliases'] as String? ?? '';
          final notes = row['notes'] as String? ?? '';
          buf.write('- $name');
          if (type.isNotEmpty) buf.write(' [$type]');
          if (system.isNotEmpty) buf.write(' in $system');
          if (parent.isNotEmpty) buf.write(', near/under $parent');
          if (aliases.isNotEmpty) buf.write(', aliases: $aliases');
          if (notes.isNotEmpty) buf.write(', notes: $notes');
          buf.writeln();
        }
      }

      if (dedupedDistances.isNotEmpty) {
        buf.writeln('DISTANCE RELATIONSHIPS:');
        for (final row in dedupedDistances.take(16)) {
          final from = row['from_location'] as String? ?? '';
          final to = row['to_location'] as String? ?? '';
          final rank = row['distance_rank']?.toString() ?? '';
          final label = row['distance_label'] as String? ?? '';
          final note = row['travel_note'] as String? ?? '';
          buf.write('- $from -> $to');
          if (rank.isNotEmpty) buf.write(' (rank $rank');
          if (label.isNotEmpty) {
            if (rank.isNotEmpty) {
              buf.write(', $label');
            } else {
              buf.write(' ($label');
            }
          }
          if (rank.isNotEmpty || label.isNotEmpty) buf.write(')');
          if (note.isNotEmpty) buf.write(': $note');
          buf.writeln();
        }
      }

      return buf.toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Smart search — understands location context like "closest to Orison".
  /// Returns compressed context string for the AI.
  Future<String> searchForAiContext(String query) async {
    final client = await _client();
    if (client == null) return '';

    try {
      final locationTerms = _extractLocationTerms(query);
      final locationContext = await _buildLocationContext(client, locationTerms);

      // Extract potential item-name words
      final words = query
          .toLowerCase()
          .split(RegExp(r'[\s\W]+'))
          .where((w) => w.length > 2 && !_stopWords.contains(w))
          .take(6)
          .toList();

      if (words.isEmpty && locationTerms.isEmpty) return '';

      final allRows = <Map<String, dynamic>>[];

      if (words.isEmpty && locationTerms.isNotEmpty) {
        // "What can I buy in Orison?" — show everything at that location
        for (final loc in locationTerms.take(3)) {
          final r = await client
              .from('catalog_offers')
              .select('item_name, location, buy_auec, sell_auec')
              .ilike('location', '%$loc%')
              .limit(50);
          allRows.addAll(List<Map<String, dynamic>>.from(r));
        }
      } else {
        // "Where can I buy X near Y?" — search by item name, sort by location match
        for (final word in words) {
          final r = await client
              .from('catalog_offers')
              .select('item_name, location, buy_auec, sell_auec')
              .ilike('item_name', '%$word%')
              .limit(60);
          allRows.addAll(List<Map<String, dynamic>>.from(r));
        }
      }

      if (allRows.isEmpty) return '';

      // Deduplicate
      final seen = <String>{};
      final deduped = <Map<String, dynamic>>[];
      for (final r in allRows) {
        final key = '${r['item_name']}|${r['location']}';
        if (seen.add(key)) deduped.add(r);
      }

      // Sort: if location terms present, put matching locations first
      if (locationTerms.isNotEmpty) {
        deduped.sort((a, b) {
          final aLoc = (a['location'] as String? ?? '').toLowerCase();
          final bLoc = (b['location'] as String? ?? '').toLowerCase();
          final aMatch = locationTerms.any((t) => aLoc.contains(t)) ? 0 : 1;
          final bMatch = locationTerms.any((t) => bLoc.contains(t)) ? 0 : 1;
          return aMatch.compareTo(bMatch);
        });
      }

      // Group by item name and compress
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final r in deduped) {
        grouped.putIfAbsent(r['item_name'] as String, () => []).add(r);
      }

      final buf = StringBuffer();
      for (final entry in grouped.entries.take(60)) {
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
          final loc = (o['location'] as String? ?? '').trim();
          if (loc.isNotEmpty && !locs.contains(loc)) locs.add(loc);
        }
        buf.writeln('${entry.key}:${minBuy ?? '-'}b/${maxSell ?? '-'}s[${locs.take(6).join(' | ')}]');
      }

      if (locationContext.isNotEmpty) {
        buf.writeln();
        buf.writeln(locationContext);
      }

      return buf.toString().trim();
    } catch (e) {
      return '(Supabase search error: $e)';
    }
  }

  /// Test connection — returns null on success, error string on failure.
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
