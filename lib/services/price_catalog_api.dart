import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches catalog JSON from **your** price API and normalizes it for [AppDatabase.importCatalogJson].
///
/// Expected item shape (per entry in `items`):
/// `name`, `offers[]` with `location`, optional `buy_auec` / `sell_auec` (or `buy` / `sell`).
class PriceCatalogApiService {
  static const _kUrl = 'price_catalog_api_url';
  static const _kMethod = 'price_catalog_api_method'; // get | post
  static const _kPostBody = 'price_catalog_api_post_body';
  static const _kRootKey = 'price_catalog_json_root_key';
  static const _kPatch = 'price_catalog_default_patch';
  static const _kAuth = 'price_catalog_auth'; // none | bearer | x_api_key
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

  /// `none` | `bearer` | `x_api_key` | `path_key` ([StarCitizen-API.com](https://starcitizen-api.com/) style: `.../{apikey}/v1/...`)
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

  /// Template for [starcitizen-api.com](https://api.starcitizen-api.com/) ships list (`cache` does not count against your daily `live` quota).
  static const starcitizenApiComShipsCacheUrlTemplate =
      'https://api.starcitizen-api.com/{apikey}/v1/cache/ships';

  /// Performs HTTP request and returns a map suitable for [importCatalogJson].
  Future<Map<String, dynamic>> fetchCatalog() async {
    final urlTemplate = (await getUrl()).trim();
    if (urlTemplate.isEmpty) {
      throw StateError('Set the catalog API URL first.');
    }
    if (!urlTemplate.startsWith('https://') && !urlTemplate.startsWith('http://')) {
      throw StateError(
        'URL must start with https:// — stored value is: "$urlTemplate"\n'
        'Go to Settings, clear the Catalog URL field, and re-enter:\n'
        'https://api.starcitizen-api.com/{apikey}/v1/cache/ships',
      );
    }
    final method = await getMethod();
    final rootKey = await getJsonRootKey();
    final defaultPatch = await getDefaultPatch();
    final authMode = await getAuthMode();
    final secret = await getSecret() ?? '';

    late final String urlResolved;
    if (authMode == 'path_key') {
      if (secret.isEmpty) {
        throw StateError('Paste your API key into “API token / key” when using key-in-URL mode.');
      }
      if (!urlTemplate.contains('{apikey}')) {
        throw StateError(
          'URL must contain the text {apikey} where the key goes (StarCitizen-API.com uses this pattern).',
        );
      }
      // Star Citizen keys are alphanumeric; do not encode (encoding can break path matching).
      urlResolved = urlTemplate.replaceAll('{apikey}', secret.trim());
    } else {
      urlResolved = urlTemplate;
    }

    if (urlResolved.contains('{apikey}')) {
      throw StateError(
        'Catalog URL still contains {apikey}. Set API auth to “Key in URL ({apikey}) — StarCitizen-API.com”, '
        'paste your key in “API token / key”, tap Save API settings, then Sync now. '
        '(While auth is “None”, the placeholder is sent literally and sync will fail.)',
      );
    }

    final uri = Uri.parse(urlResolved);

    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'StarcitizenTrader/0.1 (+local price sync)',
    };

    if (authMode == 'bearer' && secret.isNotEmpty) {
      headers['Authorization'] = 'Bearer $secret';
    } else if (authMode == 'x_api_key' && secret.isNotEmpty) {
      headers['X-Api-Key'] = secret;
    }

    // Use a custom HttpClient to work around Android DNS lookup failures
    // that affect Flutter's default HTTP client on some devices/OS versions.
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final client = IOClient(httpClient);

    final http.Response res;
    try {
      if (method == 'post') {
        final body = await getPostBody();
        if (body.trim().isNotEmpty) {
          headers['Content-Type'] = 'application/json';
          try {
            jsonDecode(body);
          } catch (_) {
            throw StateError('POST body must be valid JSON (or leave empty).');
          }
          res = await client.post(uri, headers: headers, body: body.trim());
        } else {
          res = await client.post(uri, headers: headers);
        }
      } else {
        res = await client.get(uri, headers: headers);
      }
    } finally {
      client.close();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('HTTP ${res.statusCode}: ${res.body.length > 500 ? res.body.substring(0, 500) : res.body}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (e) {
      throw StateError('Response is not JSON: $e');
    }

    if (decoded is Map) {
      final mm = Map<String, dynamic>.from(decoded);
      final ok = mm['success'];
      if (ok == 0 || ok == false || ok == '0') {
        throw StateError('API reported failure: ${mm['message'] ?? mm['error'] ?? jsonEncode(mm)}');
      }
      final isOk = ok == 1 || ok == true || ok == '1';
      final data = mm['data'];
      if (isOk && data is List && data.isEmpty) {
        throw StateError(
          'Star Citizen API returned an empty ship list. Usually: invalid API key, or cache not populated yet. '
          'Confirm your key on starcitizen-api.com, or try changing the URL to …/v1/live/ships once (uses daily quota), then back to cache.',
        );
      }
    }

    final sc = tryNormalizeStarcitizenApiEnvelope(decoded);
    if (sc != null) return sc;

    return normalizeDecoded(decoded, rootKey: rootKey.isEmpty ? null : rootKey, defaultPatch: defaultPatch);
  }

  /// [starcitizen-api.com](https://starcitizen-api.com/) wraps lists in `{ success, data, source }`.
  /// We map **ships** payloads into catalog rows (pledge **USD**, not in-game aUEC).
  static Map<String, dynamic>? tryNormalizeStarcitizenApiEnvelope(dynamic decoded) {
    if (decoded is! Map) return null;
    final m = Map<String, dynamic>.from(decoded);
    final s = m['success'];
    // Accept success==1/true, OR no success field at all (some API responses omit it)
    final ok = s == null || s == 1 || s == true || s == '1';
    if (!ok) return null;
    final data = m['data'];
    if (data == null || data is! List || data.isEmpty) return null;
    final first = data.first;
    if (first is! Map) return null;
    final fm = Map<String, dynamic>.from(first);
    // Ship objects always have a name; fields vary by API version.
    final looksLikeShip = fm.containsKey('name') &&
        (fm.containsKey('id') ||
            fm.containsKey('scm_speed') ||
            fm.containsKey('chassis_id') ||
            fm.containsKey('cargocapacity') ||
            fm.containsKey('production_status') ||
            fm.containsKey('price'));
    if (!looksLikeShip) return null;

    final src = m['source']?.toString() ?? 'cache';
    return shipsPayloadToCatalog(data, sourceLabel: src);
  }

  static Map<String, dynamic> shipsPayloadToCatalog(List<dynamic> ships, {required String sourceLabel}) {
    return {
      'patch': 'SC-API ships ($sourceLabel)',
      'items': ships.map((raw) {
        final s = Map<String, dynamic>.from(raw as Map);
        final name = s['name']?.toString().trim();
        if (name == null || name.isEmpty) {
          return {'name': 'Unknown ship', 'extra': s, 'offers': <Map<String, dynamic>>[]};
        }
        final usd = s['price'];
        final usdLabel = usd == null ? 'unknown USD' : '${usd} USD (pledge; not aUEC)';
        return {
          'name': name,
          'extra': {
            'starcitizen_api': 'ships',
            'pledge_usd': usd,
            'focus': s['focus'],
            'production_status': s['production_status'],
            'id': s['id'],
          },
          'offers': [
            {
              'location': 'RSI website — $usdLabel',
              'buy_auec': null,
              'sell_auec': null,
            },
          ],
        };
      }).toList(),
    };
  }

  /// Exposed for tests: unwrap optional root key, enforce `patch` + `items` list.
  static Map<String, dynamic> normalizeDecoded(
    dynamic decoded, {
    String? rootKey,
    required String defaultPatch,
  }) {
    dynamic root = decoded;

    if (decoded is Map && rootKey != null && rootKey.isNotEmpty) {
      final v = decoded[rootKey];
      if (v == null) {
        throw StateError('JSON has no key "$rootKey".');
      }
      root = v;
    }

    if (root is List) {
      return {'patch': defaultPatch, 'items': root};
    }

    if (root is! Map) {
      throw StateError('Catalog JSON must be an object or array (got null or unexpected type).');
    }

    final m = Map<String, dynamic>.from(root);

    if (m['items'] is List) {
      return {
        'patch': (m['patch'] as String?)?.trim().isNotEmpty == true ? m['patch'] as String : defaultPatch,
        'items': m['items'],
      };
    }

    if (m['data'] is List) {
      return {
        'patch': (m['patch'] as String?)?.trim().isNotEmpty == true ? m['patch'] as String : defaultPatch,
        'items': m['data'],
      };
    }

    throw StateError(
      'Catalog JSON must include an "items" array (or "data" array). Got ${m.keys.take(8).join(", ")}',
    );
  }
}
