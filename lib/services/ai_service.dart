import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiMessage {
  AiMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiService {
  static const _kProvider = 'ai_provider'; // openai | gemini
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';
  static const _kApiKey = 'ai_api_key';

  static const openAiDefaultBase = 'https://api.openai.com';
  static const geminiDefaultBase = 'https://generativelanguage.googleapis.com';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// `openai` (OpenAI-compatible `/v1/chat/completions`) or `gemini` (Google AI).
  Future<String> getProvider() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_kProvider) ?? 'openai').toLowerCase();
  }

  Future<void> setProvider(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kProvider, v.trim().toLowerCase());
  }

  Future<String> getBaseUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kBaseUrl) ?? 'https://api.openai.com';
  }

  Future<void> setBaseUrl(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBaseUrl, v.replaceAll(RegExp(r'/$'), ''));
  }

  Future<String> getModel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kModel) ?? 'gpt-4o-mini';
  }

  Future<void> setModel(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kModel, v.trim());
  }

  Future<String?> getApiKey() => _secure.read(key: _kApiKey);

  Future<void> setApiKey(String? v) async {
    if (v == null || v.trim().isEmpty) {
      await _secure.delete(key: _kApiKey);
    } else {
      await _secure.write(key: _kApiKey, value: v.trim());
    }
  }

  /// OpenAI-compatible chat, Google Gemini [generateContent](https://ai.google.dev/api/rest), etc.
  /// [temperature] optional; omit to use default 0.2.
  Future<String> completeChat({
    required List<AiMessage> messages,
    String? system,
    double? temperature,
  }) async {
    final provider = await getProvider();
    if (provider == 'gemini') {
      return _completeGemini(messages: messages, system: system, temperature: temperature);
    }
    return _completeOpenAiCompatible(messages: messages, system: system, temperature: temperature);
  }

  Future<String> _completeOpenAiCompatible({
    required List<AiMessage> messages,
    String? system,
    double? temperature,
  }) async {
    final key = await getApiKey();
    final base = (await getBaseUrl()).replaceAll(RegExp(r'/$'), '');
    final model = await getModel();
    final uri = Uri.parse('$base/v1/chat/completions');

    final payload = <String, dynamic>{
      'model': model,
      'messages': [
        if (system != null && system.isNotEmpty)
          {'role': 'system', 'content': system},
        ...messages.map((m) => m.toJson()),
      ],
      'temperature': temperature ?? 0.2,
    };

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (key != null && key.isNotEmpty) {
      headers['Authorization'] = 'Bearer $key';
    }

    final httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final client = IOClient(httpClient);
    final http.Response res;
    try {
      res = await client.post(uri, headers: headers, body: jsonEncode(payload));
    } finally {
      client.close();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('API error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    final first = choices?.isNotEmpty == true ? choices!.first as Map<String, dynamic> : null;
    final msg = first?['message'] as Map<String, dynamic>?;
    final content = msg?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw StateError('Empty model response.');
    }
    return content.trim();
  }

  /// Google Gemini (Google AI Studio API key). Key is sent as `?key=` query parameter.
  Future<String> _completeGemini({
    required List<AiMessage> messages,
    String? system,
    double? temperature,
  }) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError('Gemini requires an API key from Google AI Studio.');
    }
    var base = (await getBaseUrl()).replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) base = geminiDefaultBase;

    var model = (await getModel()).trim();
    if (model.startsWith('models/')) model = model.substring('models/'.length);
    if (model.isEmpty) model = 'gemini-2.0-flash';

    final path = '/v1beta/models/$model:generateContent';
    final uri = Uri.parse('$base$path').replace(queryParameters: {'key': key});

    final contents = <Map<String, dynamic>>[];
    for (final m in messages) {
      final role = m.role == 'user' ? 'user' : 'model';
      contents.add({
        'role': role,
        'parts': [
          {'text': m.content},
        ],
      });
    }

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature ?? 0.2,
      },
    };
    if (system != null && system.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': system},
        ],
      };
    }

    final httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final client = IOClient(httpClient);
    final http.Response res;
    try {
      res = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    } finally {
      client.close();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Gemini API error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final err = decoded['error'];
    if (err is Map) {
      throw StateError('Gemini: ${err['message'] ?? err}');
    }

    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw StateError(
        'Gemini returned no candidates (blocked or empty). ${decoded['promptFeedback'] ?? decoded}',
      );
    }

    final first = candidates.first as Map<String, dynamic>;
    final c = first['content'] as Map<String, dynamic>?;
    final parts = c?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw StateError('Gemini: empty content parts.');
    }

    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map && p['text'] != null) {
        buf.write(p['text']);
      }
    }
    final out = buf.toString().trim();
    if (out.isEmpty) throw StateError('Gemini: no text in response.');
    return out;
  }
}
