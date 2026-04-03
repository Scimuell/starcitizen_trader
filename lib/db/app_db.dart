import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

int? _asAuec(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9\-]'), ''));
  return null;
}

class PriceLogRow {
  PriceLogRow({
    required this.id,
    required this.itemName,
    required this.price,
    required this.location,
    required this.loggedAt,
    required this.logType,
    this.note,
  });

  final int id;
  final String itemName;
  final int price;
  final String? location;
  final DateTime loggedAt;
  final String logType;
  final String? note;
}

class AlertRow {
  AlertRow({
    required this.id,
    required this.itemName,
    required this.targetAuec,
    required this.fireWhen,
  });

  final int id;
  final String itemName;
  final int targetAuec;
  final String fireWhen;
}

class TradeRow {
  TradeRow({
    required this.id,
    required this.itemName,
    required this.buyAuec,
    required this.buyQty,
    required this.boughtAt,
    this.sellAuec,
    this.sellQty,
    this.soldAt,
    this.notes,
  });

  final int id;
  final String itemName;
  final int buyAuec;
  final int buyQty;
  final DateTime boughtAt;
  final int? sellAuec;
  final int? sellQty;
  final DateTime? soldAt;
  final String? notes;

  bool get isOpen => sellAuec == null || soldAt == null;

  int? profitAuec() {
    if (sellAuec == null || sellQty == null) return null;
    return sellAuec! * sellQty! - buyAuec * buyQty;
  }
}

class CatalogItemRow {
  CatalogItemRow({
    required this.id,
    required this.name,
    required this.patch,
    this.extra,
  });

  final int id;
  final String name;
  final String patch;
  final String? extra;
}

class CatalogOfferRow {
  CatalogOfferRow({
    required this.id,
    required this.itemId,
    required this.location,
    this.buyAuec,
    this.sellAuec,
  });

  final int id;
  final int itemId;
  final String location;
  final int? buyAuec;
  final int? sellAuec;
}

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'starcitizen_trader.sqlite');
    final db = await openDatabase(
      path,
      version: 1,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE catalog_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  patch TEXT NOT NULL,
  extra TEXT
);
''');
        await db.execute('''
CREATE TABLE catalog_offers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL,
  location TEXT NOT NULL,
  buy_auec INTEGER,
  sell_auec INTEGER,
  FOREIGN KEY (item_id) REFERENCES catalog_items (id) ON DELETE CASCADE
);
''');
        await db.execute('CREATE INDEX idx_catalog_offers_item ON catalog_offers(item_id);');

        await db.execute('''
CREATE TABLE price_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_name TEXT NOT NULL,
  price INTEGER NOT NULL,
  location TEXT,
  logged_at TEXT NOT NULL,
  note TEXT,
  log_type TEXT NOT NULL
);
''');
        await db.execute('CREATE INDEX idx_price_logs_item ON price_logs(item_name);');
        await db.execute('CREATE INDEX idx_price_logs_time ON price_logs(logged_at);');

        await db.execute('''
CREATE TABLE price_alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_name TEXT NOT NULL,
  target_auec INTEGER NOT NULL,
  fire_when TEXT NOT NULL
);
''');

        await db.execute('''
CREATE TABLE trades (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_name TEXT NOT NULL,
  buy_auec INTEGER NOT NULL,
  buy_qty INTEGER NOT NULL,
  bought_at TEXT NOT NULL,
  sell_auec INTEGER,
  sell_qty INTEGER,
  sold_at TEXT,
  notes TEXT
);
''');
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => _db.close();

  // --- Catalog ---

  Future<void> importCatalogJson(Map<String, dynamic> json) async {
    final patch = (json['patch'] as String?) ?? '4.7';
    final items = json['items'] as List<dynamic>? ?? [];
    await _db.transaction((txn) async {
      for (final raw in items) {
        if (raw == null || raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final name = (m['name'] as String?)?.trim();
        if (name == null || name.isEmpty) continue;
        final extra = m['extra'] != null ? jsonEncode(m['extra']) : null;
        final existing = await txn.query(
          'catalog_items',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );
        final int resolvedId;
        if (existing.isEmpty) {
          resolvedId = await txn.insert('catalog_items', {
            'name': name,
            'patch': patch,
            'extra': extra,
          });
        } else {
          resolvedId = existing.first['id'] as int;
          await txn.update(
            'catalog_items',
            {'patch': patch, if (extra != null) 'extra': extra},
            where: 'id = ?',
            whereArgs: [resolvedId],
          );
        }
        final offers = m['offers'] as List<dynamic>? ?? [];
        await txn.delete('catalog_offers', where: 'item_id = ?', whereArgs: [resolvedId]);
        for (final o in offers) {
          if (o == null || o is! Map) continue;
          final om = Map<String, dynamic>.from(o);
          final loc = (om['location'] as String?)?.trim() ?? '';
          if (loc.isEmpty) continue;
          final buy = _asAuec(om['buy_auec']) ?? _asAuec(om['buy']);
          final sell = _asAuec(om['sell_auec']) ?? _asAuec(om['sell']);
          await txn.insert('catalog_offers', {
            'item_id': resolvedId,
            'location': loc,
            'buy_auec': buy,
            'sell_auec': sell,
          });
        }
      }
    });
  }

  Future<void> clearCatalog() async {
    await _db.delete('catalog_offers');
    await _db.delete('catalog_items');
  }

  Future<int> catalogItemCount() async {
    final r = await _db.rawQuery('SELECT COUNT(1) AS c FROM catalog_items');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> priceLogCount() async {
    final r = await _db.rawQuery('SELECT COUNT(1) AS c FROM price_logs');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> tradeCount() async {
    final r = await _db.rawQuery('SELECT COUNT(1) AS c FROM trades');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<List<CatalogItemRow>> searchCatalog(String query, {int limit = 0}) async {
    final trimmed = query.trim();
    final List<Map<String, Object?>> rows;
    if (trimmed.isEmpty || trimmed == '%') {
      rows = await _db.query(
        'catalog_items',
        orderBy: 'name COLLATE NOCASE ASC',
      );
    } else {
      final like = '%${trimmed.replaceAll('%', '').replaceAll('_', '')}%';
      rows = await _db.query(
        'catalog_items',
        where: 'name LIKE ?',
        whereArgs: [like],
        orderBy: 'name COLLATE NOCASE ASC',
      );
    }
    return rows
        .map(
          (e) => CatalogItemRow(
            id: e['id'] as int,
            name: e['name'] as String,
            patch: e['patch'] as String,
            extra: e['extra'] as String?,
          ),
        )
        .toList();
  }

  Future<List<CatalogOfferRow>> offersForItem(int itemId) async {
    final rows = await _db.query(
      'catalog_offers',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'location COLLATE NOCASE ASC',
    );
    return rows
        .map(
          (e) => CatalogOfferRow(
            id: e['id'] as int,
            itemId: e['item_id'] as int,
            location: e['location'] as String,
            buyAuec: e['buy_auec'] as int?,
            sellAuec: e['sell_auec'] as int?,
          ),
        )
        .toList();
  }

  Future<CatalogItemRow?> catalogById(int id) async {
    final rows = await _db.query('catalog_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final e = rows.first;
    return CatalogItemRow(
      id: e['id'] as int,
      name: e['name'] as String,
      patch: e['patch'] as String,
      extra: e['extra'] as String?,
    );
  }

  /// Compact text for AI context.
  ///
  /// Uses a single JOIN query (avoids N+1 per-item round-trips).
  /// Returns the full catalog in a heavily compressed single-line-per-item
  /// format so the AI can see everything within token limits.
  /// Format: ItemName:BUYb/SELLs[Loc1,Loc2,...] — ~8x smaller than verbose.
  Future<String> catalogContextBlob({
    int charBudget = 40000,
    List<String> keywords = const [],
    bool matchedOnly = false,
  }) async {
    // Exclude ship components/missiles from AI context to save tokens.
    // These are still visible in the main Catalog tab.
    const _aiExcludePatterns = [
      'laser cannon', 'ballistic cannon', 'gatling', 'neutron repeater',
      'missile', 'torpedo', 'shield generator', 'power plant', 'quantum drive',
      'cooler', 'fuel intake', 'fuel tank', 'jump module', 'radar',
      'tractor beam', 'mining laser', 'salvage module', 'countermeasure',
      'decoy flare', 'noise field', 'emp', 'thruster', 'avionics',
      'flight computer', 'landing gear', 'quantum dampener',
    ];
    final excWhere = _aiExcludePatterns.map((_) => "LOWER(ci.name) NOT LIKE ?").join(' AND ');
    final excArgs = _aiExcludePatterns.map((k) => '%$k%').toList();

    final sql = '''
      SELECT ci.name, co.location, co.buy_auec, co.sell_auec
      FROM catalog_items ci
      LEFT JOIN catalog_offers co ON co.item_id = ci.id
      WHERE $excWhere
      ORDER BY ci.name COLLATE NOCASE ASC
    ''';
    final rows = await _db.rawQuery(sql, excArgs);
    if (rows.isEmpty) return '(catalog empty)';

    // Group offers by item name
    final grouped = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final name = row['name'] as String;
      grouped.putIfAbsent(name, () => []).add(row);
    }

    // Compress: one line per item
    // Format: Aluminum:363b/330s[TDD A18,TDD NB] or Titanium:—b/8300s[Shubin]
    final buf = StringBuffer();
    for (final entry in grouped.entries) {
      final name = entry.key;
      final offers = entry.value;

      // Collect unique buy/sell prices and locations
      int? minBuy, maxSell;
      final locs = <String>[];
      for (final o in offers) {
        final buy = o['buy_auec'];
        final sell = o['sell_auec'];
        final loc = (o['location'] as String? ?? '').trim();
        if (buy != null) {
          final b = buy is int ? buy : (buy as num).toInt();
          if (minBuy == null || b < minBuy) minBuy = b;
        }
        if (sell != null) {
          final s = sell is int ? sell : (sell as num).toInt();
          if (maxSell == null || s > maxSell) maxSell = s;
        }
        // Shorten location: strip common suffixes and long words
        final shortLoc = loc
            .replaceAll(' — ', '-')
            .replaceAll('Terminal', 'T')
            .replaceAll('Station', 'Sta')
            .replaceAll('Distribution', 'Dist')
            .replaceAll('Center', 'Ctr')
            .replaceAll('Outpost', 'OP');
        if (shortLoc.isNotEmpty && !locs.contains(shortLoc)) {
          locs.add(shortLoc);
        }
      }

      final buyStr = minBuy != null ? '${minBuy}b' : '-';
      final sellStr = maxSell != null ? '${maxSell}s' : '-';
      final locStr = locs.take(6).join(',');
      final line = '$name:$buyStr/$sellStr[$locStr]\n';
      buf.write(line);

      if (buf.length >= charBudget) break;
    }

    return buf.toString();
  }

  // --- Logs ---

  Future<int> insertLog({
    required String itemName,
    required int price,
    String? location,
    required DateTime loggedAt,
    required String logType,
    String? note,
  }) {
    return _db.insert('price_logs', {
      'item_name': itemName.trim(),
      'price': price,
      'location': location,
      'logged_at': loggedAt.toIso8601String(),
      'log_type': logType,
      'note': note,
    });
  }

  Future<List<PriceLogRow>> logsForItem(String itemName) async {
    final rows = await _db.query(
      'price_logs',
      where: 'item_name = ? COLLATE NOCASE',
      whereArgs: [itemName.trim()],
      orderBy: 'logged_at ASC',
    );
    return rows.map(_rowToLog).toList();
  }

  Future<List<PriceLogRow>> recentLogs({int limit = 25}) async {
    final rows = await _db.query('price_logs', orderBy: 'logged_at DESC', limit: limit);
    return rows.map(_rowToLog).toList();
  }

  PriceLogRow _rowToLog(Map<String, Object?> e) {
    return PriceLogRow(
      id: e['id'] as int,
      itemName: e['item_name'] as String,
      price: e['price'] as int,
      location: e['location'] as String?,
      loggedAt: DateTime.parse(e['logged_at'] as String),
      logType: e['log_type'] as String,
      note: e['note'] as String?,
    );
  }

  Future<PriceLogRow?> latestLogForItem(String itemName) async {
    final rows = await _db.query(
      'price_logs',
      where: 'item_name = ? COLLATE NOCASE',
      whereArgs: [itemName.trim()],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToLog(rows.first);
  }

  // --- Alerts ---

  Future<int> insertAlert({
    required String itemName,
    required int targetAuec,
    required String fireWhen,
  }) {
    return _db.insert('price_alerts', {
      'item_name': itemName.trim(),
      'target_auec': targetAuec,
      'fire_when': fireWhen,
    });
  }

  Future<void> deleteAlert(int id) => _db.delete('price_alerts', where: 'id = ?', whereArgs: [id]);

  Future<List<AlertRow>> allAlerts() async {
    final rows = await _db.query('price_alerts', orderBy: 'item_name COLLATE NOCASE ASC');
    return rows
        .map(
          (e) => AlertRow(
            id: e['id'] as int,
            itemName: e['item_name'] as String,
            targetAuec: e['target_auec'] as int,
            fireWhen: e['fire_when'] as String,
          ),
        )
        .toList();
  }

  Future<List<String>> evaluateTriggeredAlerts() async {
    final alerts = await allAlerts();
    final out = <String>[];
    for (final a in alerts) {
      final last = await latestLogForItem(a.itemName);
      if (last == null) continue;
      final hit = (a.fireWhen == 'below_or_equal' && last.price <= a.targetAuec) ||
          (a.fireWhen == 'above_or_equal' && last.price >= a.targetAuec);
      if (hit) {
        out.add(
          '${a.itemName}: latest log ${last.price} aUEC vs target ${a.targetAuec} (${a.fireWhen}).',
        );
      }
    }
    return out;
  }

  // --- Trades / profit ---

  Future<int> insertTrade({
    required String itemName,
    required int buyAuec,
    required int buyQty,
    required DateTime boughtAt,
    int? sellAuec,
    int? sellQty,
    DateTime? soldAt,
    String? notes,
  }) {
    return _db.insert('trades', {
      'item_name': itemName.trim(),
      'buy_auec': buyAuec,
      'buy_qty': buyQty,
      'bought_at': boughtAt.toIso8601String(),
      'sell_auec': sellAuec,
      'sell_qty': sellQty,
      'sold_at': soldAt?.toIso8601String(),
      'notes': notes,
    });
  }

  Future<void> deleteLog(int id) => _db.delete('price_logs', where: 'id = ?', whereArgs: [id]);

  Future<void> updateLog({
    required int id,
    required String itemName,
    required int price,
    String? location,
    required DateTime loggedAt,
    required String logType,
    String? note,
  }) async {
    await _db.update(
      'price_logs',
      {
        'item_name': itemName.trim(),
        'price': price,
        'location': location,
        'logged_at': loggedAt.toIso8601String(),
        'log_type': logType,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateAlert({
    required int id,
    required String itemName,
    required int targetAuec,
    required String fireWhen,
  }) async {
    await _db.update(
      'price_alerts',
      {
        'item_name': itemName.trim(),
        'target_auec': targetAuec,
        'fire_when': fireWhen,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTrade(int id) => _db.delete('trades', where: 'id = ?', whereArgs: [id]);

  Future<void> updateTradeSale({
    required int id,
    required int sellAuec,
    required int sellQty,
    required DateTime soldAt,
  }) async {
    await _db.update(
      'trades',
      {
        'sell_auec': sellAuec,
        'sell_qty': sellQty,
        'sold_at': soldAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTradeBuy({
    required int id,
    required String itemName,
    required int buyAuec,
    required int buyQty,
    required DateTime boughtAt,
    String? notes,
  }) async {
    await _db.update(
      'trades',
      {
        'item_name': itemName.trim(),
        'buy_auec': buyAuec,
        'buy_qty': buyQty,
        'bought_at': boughtAt.toIso8601String(),
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TradeRow>> allTrades() async {
    final rows = await _db.query('trades', orderBy: 'bought_at DESC');
    return rows.map(_rowToTrade).toList();
  }

  TradeRow _rowToTrade(Map<String, Object?> e) {
    return TradeRow(
      id: e['id'] as int,
      itemName: e['item_name'] as String,
      buyAuec: e['buy_auec'] as int,
      buyQty: e['buy_qty'] as int,
      boughtAt: DateTime.parse(e['bought_at'] as String),
      sellAuec: e['sell_auec'] as int?,
      sellQty: e['sell_qty'] as int?,
      soldAt: (e['sold_at'] as String?) != null ? DateTime.parse(e['sold_at'] as String) : null,
      notes: e['notes'] as String?,
    );
  }
}
