import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../db/app_db.dart';
import '../services/ai_service.dart';
import '../services/price_catalog_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ai = AiService();
  final _priceApi = PriceCatalogApiService();

  final _base = TextEditingController();
  final _model = TextEditingController();
  final _key = TextEditingController();

  final _catUrl = TextEditingController();
  final _catRootKey = TextEditingController();
  final _catPatch = TextEditingController();
  final _catPostBody = TextEditingController();
  final _catSecret = TextEditingController();

  var _showKey = false;
  var _showCatSecret = false;
  var _busy = false;
  String _aiProvider = 'openai';
  String _catMethod = 'get';
  String _catAuth = 'none';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _aiProvider = await _ai.getProvider();
    _base.text = await _ai.getBaseUrl();
    _model.text = await _ai.getModel();
    final k = await _ai.getApiKey();
    _key.text = k ?? '';

    _catUrl.text = await _priceApi.getUrl();
    _catRootKey.text = await _priceApi.getJsonRootKey();
    _catPatch.text = await _priceApi.getDefaultPatch();
    _catPostBody.text = await _priceApi.getPostBody();
    _catMethod = await _priceApi.getMethod();
    _catAuth = await _priceApi.getAuthMode();
    final cs = await _priceApi.getSecret();
    _catSecret.text = cs ?? '';

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _base.dispose();
    _model.dispose();
    _key.dispose();
    _catUrl.dispose();
    _catRootKey.dispose();
    _catPatch.dispose();
    _catPostBody.dispose();
    _catSecret.dispose();
    super.dispose();
  }

  Future<void> _saveAi() async {
    await _ai.setProvider(_aiProvider);
    await _ai.setBaseUrl(_base.text.trim());
    await _ai.setModel(_model.text.trim());
    await _ai.setApiKey(_key.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved AI settings.')));
    }
  }

  Future<void> _savePriceApi() async {
    await _priceApi.setUrl(_catUrl.text.trim());
    await _priceApi.setMethod(_catMethod);
    await _priceApi.setPostBody(_catPostBody.text);
    await _priceApi.setJsonRootKey(_catRootKey.text.trim());
    await _priceApi.setDefaultPatch(_catPatch.text.trim().isEmpty ? '4.7' : _catPatch.text.trim());
    await _priceApi.setAuthMode(_catAuth);
    await _priceApi.setSecret(_catSecret.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved price API settings.')));
    }
  }

  Future<void> _syncFromPriceApi() async {
    setState(() => _busy = true);
    try {
      await _savePriceApi();
      final map = await _priceApi.fetchCatalog();
      await widget.db.importCatalogJson(map);
      final count = await widget.db.catalogItemCount();
      final itemList = map['items'] as List?;
      final firstName = (itemList != null && itemList.isNotEmpty)
          ? (itemList.first['name']?.toString() ?? 'no name field')
          : 'list empty';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synced. DB has $count items. First: $firstName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCatalog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear catalog?'),
        content: const Text('This removes all catalog items and offers from the local database. Your logs, alerts and trades are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await widget.db.clearCatalog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalog cleared.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFile() async {
    setState(() => _busy = true);
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (r == null || r.files.isEmpty) return;
      final f = r.files.single;
      final path = f.path;
      final String txt;
      if (path != null) {
        txt = await File(path).readAsString();
      } else if (f.bytes != null) {
        txt = utf8.decode(f.bytes!);
      } else {
        throw StateError('Could not read file (no path/bytes).');
      }
      final map = jsonDecode(txt) as Map<String, dynamic>;
      await widget.db.importCatalogJson(map);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalog import complete.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reloadSeed() async {
    setState(() => _busy = true);
    try {
      final raw = await rootBundle.loadString('assets/catalog_seed.json');
      await widget.db.importCatalogJson(jsonDecode(raw) as Map<String, dynamic>);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seed catalog merged again.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seed reload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('AI (chat)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _aiProvider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI-compatible (Chat Completions)')),
                DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (Google AI Studio)')),
              ],
              onChanged: (v) {
                setState(() {
                  _aiProvider = v ?? 'openai';
                  if (_aiProvider == 'gemini') {
                    if (_base.text.contains('openai') || _base.text.trim().isEmpty) {
                      _base.text = AiService.geminiDefaultBase;
                    }
                    if (_model.text.toLowerCase().contains('gpt') || _model.text.trim().isEmpty) {
                      _model.text = 'gemini-2.0-flash';
                    }
                  } else {
                    if (_base.text.contains('generativelanguage.googleapis.com') || _base.text.trim().isEmpty) {
                      _base.text = AiService.openAiDefaultBase;
                    }
                    if (_model.text.toLowerCase().startsWith('gemini')) {
                      _model.text = 'gpt-4o-mini';
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _base,
              decoration: InputDecoration(
                labelText: 'API base URL',
                helperText: _aiProvider == 'gemini'
                    ? 'Use: ${AiService.geminiDefaultBase}'
                    : 'Examples: https://api.openai.com or http://10.0.2.2:1234 (emulator → PC)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _model,
              decoration: InputDecoration(
                labelText: 'Model name',
                helperText: _aiProvider == 'gemini'
                    ? 'e.g. gemini-2.0-flash, gemini-1.5-flash (see Google AI Studio)'
                    : 'e.g. gpt-4o-mini',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _key,
              obscureText: !_showKey,
              decoration: InputDecoration(
                labelText: _aiProvider == 'gemini' ? 'Gemini API key (Google AI Studio)' : 'API key',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showKey = !_showKey),
                  icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveAi,
              child: const Text('Save AI settings'),
            ),
            const SizedBox(height: 24),
            Text('Price catalog API (your site)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Sync commodity/item prices (aUEC) via UEX, or ship specs via StarCitizen-API.com. '
              'Tap a preset below to auto-fill the URL and auth settings, then paste your API key.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Quick fill preset:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _catMethod = 'get';
                      _catAuth = 'path_key';
                      _catUrl.text = PriceCatalogApiService.starcitizenApiComShipsCacheUrlTemplate;
                      _catRootKey.clear();
                    });
                  },
                  child: const Text('SC-API Ships (USD)'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _catMethod = 'get';
                      _catAuth = 'bearer';
                      _catUrl.text = PriceCatalogApiService.uexCommoditiesPricesAllUrl;
                      _catRootKey.clear();
                    });
                  },
                  child: const Text('UEX Commodities (aUEC)'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _catMethod = 'get';
                      _catAuth = 'bearer';
                      _catUrl.text = PriceCatalogApiService.uexItemsPricesAllUrl;
                      _catRootKey.clear();
                    });
                  },
                  child: const Text('UEX Items (aUEC)'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _catUrl,
              decoration: const InputDecoration(
                labelText: 'Catalog URL',
                hintText: 'https://example.com/v1/prices.json',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _catMethod,
              decoration: const InputDecoration(labelText: 'HTTP method'),
              items: const [
                DropdownMenuItem(value: 'get', child: Text('GET')),
                DropdownMenuItem(value: 'post', child: Text('POST')),
              ],
              onChanged: (v) => setState(() => _catMethod = v ?? 'get'),
            ),
            if (_catMethod == 'post') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _catPostBody,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'POST JSON body (optional)',
                  alignLabelWithHint: true,
                  hintText: '{}\nor leave empty',
                ),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _catAuth,
              decoration: const InputDecoration(labelText: 'API auth'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'bearer', child: Text('Authorization: Bearer …')),
                DropdownMenuItem(value: 'x_api_key', child: Text('X-Api-Key header')),
                DropdownMenuItem(
                  value: 'path_key',
                  child: Text('Key in URL ({apikey}) — StarCitizen-API.com'),
                ),
              ],
              onChanged: (v) => setState(() => _catAuth = v ?? 'none'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catSecret,
              obscureText: !_showCatSecret,
              decoration: InputDecoration(
                labelText: 'API token / key',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showCatSecret = !_showCatSecret),
                  icon: Icon(_showCatSecret ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catRootKey,
              decoration: const InputDecoration(
                labelText: 'JSON root key (optional)',
                helperText: 'If the payload is like {"result":{...}}, put: result',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catPatch,
              decoration: const InputDecoration(
                labelText: 'Default patch label',
                helperText: 'Used if the JSON has no "patch" field',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _savePriceApi,
                    child: const Text('Save API settings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _syncFromPriceApi,
                    child: const Text('Sync now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Catalog file (offline)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Import a JSON file in the same shape as the API (patch + items with offers), or re-merge the bundled seed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _importFile,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Import catalog JSON…'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _reloadSeed,
              child: const Text('Re-import bundled seed (examples only)'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _clearCatalog,
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Clear entire catalog…'),
            ),
            if (_busy) const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
