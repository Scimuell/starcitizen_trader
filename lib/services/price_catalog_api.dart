import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PriceCatalogApiService {
  static const _kUrl = 'price_catalog_api_url';
  static const _kMethod = 'price_catalog_api_method';
  static const _kPostBody = 'price_catalog_api_post_body';
  static const _kRootKey = 'price_catalog_json_root_key';
  static const _kPatch = 'price_catalog_default_patch';
  static const _kAuth = 'price_catalog_auth';
  static const _kSecret = 'price_catalog_api_secret';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<String> getUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUrl) ?? '';
  }

  Future<void> setUrl(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUrl, v.trim());
  }

  Future<String> getMethod() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_kMethod) ?? 'get').toLowerCase();
  }

  Future<void> setMethod(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMethod, v.trim().toLowerCase());
  }

  Future<String> getPostBody() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPostBody) ?? '';
  }

  Future<void> setPostBody(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPostBody, v);
  }

  Future<String> getJsonRootKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRootKey) ?? '';
  }

  Future<void> setJsonRootKey(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRootKey, v.trim());
  }

  Future<String> getDefaultPatch() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPatch) ?? '4.7';
  }

  Future<void> setDefaultPatch(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPatch, v.trim());
  }

  Future<String> getAuthMode() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_kAuth) ?? 'none').toLowerCase();
  }

  Future<void> setAuthMode(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAuth, v.trim().toLowerCase());
  }

  Future<String?> getSecret() => _secure.read(key: _kSecret);

  Future<void> setSecret(String? v) async {
    if (v == null || v.trim().isEmpty) {
      await _secure.delete(key: _kSecret);
    } else {
      await _secure.write(key: _kSecret, value: v.trim());
    }
  }

  static const starcitizenApiComShipsCacheUrlTemplate =
      'https://api.starcitizen-api.com/{apikey}/v1/cache/ships';

  Future<Map<String, dynamic>> fetchCatalog() async {
    final urlTemplate = (await getUrl()).trim();
    if (urlTemplate.isEmpty) {
      throw StateError('Set the catalog API URL first.');
    }

    if (!urlTemplate.startsWith('https://') &&
        !urlTemplate.startsWith('http://')) {
      throw StateError('URL must start with https://');
    }

    final method = await getMethod();
    final rootKey = await getJsonRootKey();
    final defaultPatch = await getDefaultPatch();
    final authMode = await getAuthMode();
    final secret = await getSecret() ?? '';

    late final String urlResolved;

    if (authMode == 'path_key') {
      if (secret.isEmpty) {
        throw StateError('API key required.');
      }
      urlResolved = urlTemplate.replaceAll('{apikey}', secret.trim());
    } else {
      urlResolved = urlTemplate;
    }

    final uri = Uri.parse(urlResolved);

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final http.Response res =
        method == 'post'
            ? await http.post(uri, headers: headers)
            : await http.get(uri, headers: headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('HTTP ${res.statusCode}');
    }

    dynamic decoded = jsonDecode(res.body);

    if (decoded == null) {
      throw StateError('API returned null JSON');
    }

    final sc = tryNormalizeStarcitizenApiEnvelope(decoded);
    if (sc != null) return sc;

    return normalizeDecoded(
      decoded,
      rootKey: rootKey.isEmpty ? null : rootKey,
      defaultPatch: defaultPatch,
    );
  }

  static Map<String, dynamic>? tryNormalizeStarcitizenApiEnvelope(
    dynamic decoded,
  ) {
    if (decoded is! Map) return null;

    final m = Map<String, dynamic>.from(decoded);

    final s = m['success'];
    final ok = s == 1 || s == true || s == '1';
    if (!ok) return null;

    final data = m['data'];
    if (data is! List || data.isEmpty) return null;

    final first = data.firstWhere(
      (e) => e != null && e is Map,
      orElse: () => null,
    );

    if (first == null) return null;

    final fm = Map<String, dynamic>.from(first as Map);

    final looksLikeShip = fm.containsKey('name');

    if (!looksLikeShip) return null;

    final src = m['source']?.toString() ?? 'cache';

    return shipsPayloadToCatalog(data, sourceLabel: src);
  }

  static Map<String, dynamic> shipsPayloadToCatalog(
    List<dynamic> ships, {
    required String sourceLabel,
  }) {
    final safeItems =
        ships
            .where((raw) => raw != null && raw is Map)
            .map((raw) {
              final s = Map<String, dynamic>.from(raw as Map);

              final name = s['name']?.toString().trim();
              if (name == null || name.isEmpty) return null;

              final usd = s['price'];

              return {
                'name': name,
                'extra': {'pledge_usd': usd},
                'offers': [
                  {
                    'location': 'RSI',
                    'buy_auec': null,
                    'sell_auec': null,
                  },
                ],
              };
            })
            .where((e) => e != null)
            .cast<Map<String, dynamic>>()
            .toList();

    return {'patch': 'SC API ($sourceLabel)', 'items': safeItems};
  }

  static Map<String, dynamic> normalizeDecoded(
    dynamic decoded, {
    String? rootKey,
    required String defaultPatch,
  }) {
    dynamic root = decoded;

    if (decoded is Map && rootKey != null && rootKey.isNotEmpty) {
      root = decoded[rootKey];
      if (root == null) {
        throw StateError('Missing root key');
      }
    }

    if (root is List) {
      return {'patch': defaultPatch, 'items': root};
    }

    if (root is! Map) {
      throw StateError('Invalid JSON');
    }

    final m = Map<String, dynamic>.from(root);

    final items = m['items'] ?? m['data'];

    if (items is! List) {
      throw StateError('Missing items list');
    }

    return {'patch': defaultPatch, 'items': items};
  }
}