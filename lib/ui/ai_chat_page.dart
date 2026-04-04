import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import 'rare_armor_page.dart' show rareArmorContextBlob;
import 'rare_guns_page.dart' show rareGunsContextBlob;
import 'rare_materials_page.dart' show rareMaterialsContextBlob;

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _ai = AiService();
  final _supa = SupabaseService.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Bubble>[];
  var _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _msgs.add(_Bubble(role: 'user', text: text));
      _ctrl.clear();
    });
    _scrollToEnd();

    try {
      String catalog;
      final supaEnabled = await _supa.isEnabled() && await _supa.isConfigured();

      if (supaEnabled) {
        // Smart mode: only fetch rows relevant to the query from Supabase
        // This keeps tokens minimal — only sends what OpenAI needs
        final supaResult = await _supa.searchForAiContext(text);
        if (supaResult.isNotEmpty) {
          catalog = supaResult;
        } else {
          // Fallback to local compressed if Supabase returned nothing
          catalog = await widget.db.catalogContextBlob();
        }
      } else {
        // No Supabase — use full local compressed catalog
        catalog = await widget.db.catalogContextBlob();
      }

      final logs = await widget.db.recentLogs(limit: 10);
      final logText = logs
          .map((e) => '${e.itemName}: ${e.price} aUEC @ ${e.loggedAt.toIso8601String()} (${e.logType})')
          .join('\n');

      final sourceNote = supaEnabled
          ? 'Data sourced from Supabase (relevant items only).'
          : 'Data sourced from full local catalog.';

      final system = '''
You are StarMarket AI, a Star Citizen trading assistant.
Answer using ONLY the context below. Currency is aUEC.
If the context doesn\'t contain the answer, say so clearly.
Do not make up prices or locations. Do not claim live data.
$sourceNote

Ship components (shields, quantum drives, coolers, missiles, ship weapons) are excluded.
If asked about ship parts, tell the user to check the Market tab directly.

CATALOG FORMAT: ItemName:MINBUYb/MAXSELLs[Location1,Location2,...]
b=buy price aUEC (what player pays to buy)
s=sell price aUEC (what player receives when selling)
-=not traded at that price type

CATALOG:
$catalog

RECENT USER PRICE LOGS:
$logText

${rareGunsContextBlob()}

${rareArmorContextBlob()}

${rareMaterialsContextBlob()}
''';

      final reply = await _ai.completeChat(
        system: system,
        messages: [
          ..._msgs
              .where((m) => m.role != 'err')
              .map((m) => AiMessage(
                  role: m.role == 'user' ? 'user' : 'assistant',
                  content: m.text)),
        ],
      );

      if (!mounted) return;
      setState(() => _msgs.add(_Bubble(role: 'assistant', text: reply)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _msgs.add(_Bubble(role: 'err', text: e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    return Column(
      children: [
        FutureBuilder<bool>(
          future: SupabaseService.instance.isEnabled(),
          builder: (context, snap) {
            final supaOn = snap.data == true;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: supaOn
                    ? cyan.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                    color: supaOn ? cyan.withValues(alpha: 0.4) : outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    supaOn ? Icons.cloud_done_outlined : Icons.storage_outlined,
                    size: 14,
                    color: supaOn ? cyan : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      supaOn
                          ? 'Supabase AI mode — smart context, minimal tokens'
                          : 'Local mode — full catalog sent per query',
                      style: TextStyle(
                          fontSize: 10,
                          color: supaOn
                              ? cyan
                              : Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length,
            itemBuilder: (context, i) {
              final m = _msgs[i];
              final isUser = m.role == 'user';
              final isErr = m.role == 'err';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.86),
                  decoration: BoxDecoration(
                    color: isErr
                        ? Theme.of(context).colorScheme.errorContainer
                        : isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(m.text,
                      style: TextStyle(
                          color: isErr
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : null)),
                ),
              );
            },
          ),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask about prices, weapons, armor, materials...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble {
  _Bubble({required this.role, required this.text});

  final String role;
  final String text;
}
