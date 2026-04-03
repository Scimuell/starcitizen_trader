import 'package:flutter/material.dart';

import '../db/app_db.dart';
import 'catalog_detail_page.dart';

const _kCategories = [
  'ALL', 'COMMODITIES', 'WEAPONS', 'AMMO', 'CLOTHING',
  'MEDICAL', 'FOOD', 'UTILITY', 'SHIP PARTS', 'OTHER',
];

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _q = TextEditingController();
  String _category = 'ALL';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        // Search bar
        Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: TextField(
            controller: _q,
            decoration: InputDecoration(
              hintText: 'SEARCH MARKET...',
              hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                  letterSpacing: 1),
              prefixIcon: Icon(Icons.search, color: cyan, size: 18),
              suffixIcon: _q.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: Theme.of(context).colorScheme.onSurface, size: 16),
                      onPressed: () => setState(() => _q.clear()),
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 13, letterSpacing: 1),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Category filter chips
        Container(
          color: surface,
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            children: _kCategories.map((cat) {
              final selected = _category == cat;
              final chipColor = _categoryColor(cat, cyan);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? chipColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                          color: selected
                              ? chipColor
                              : outline.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? chipColor
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Divider(height: 1, color: outline),
        // Item list
        Expanded(
          child: FutureBuilder<List<CatalogItemRow>>(
            key: ValueKey('${_q.text}_$_category'),
            future: widget.db.searchCatalog(_q.text.trim(), category: _category),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator(color: cyan));
              }
              final rows = snap.data!;
              if (rows.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dataset_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _q.text.isEmpty && _category == 'ALL'
                            ? 'NO CATALOG DATA'
                            : 'NO RESULTS',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 2,
                            fontSize: 12),
                      ),
                      if (_q.text.isEmpty && _category == 'ALL') ...[
                        const SizedBox(height: 4),
                        Text('Sync from Settings to load market data',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 11)),
                      ],
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final catLabel = AppDatabase.inferCategory(r.name);
                  final catColor = _categoryColor(catLabel, cyan);
                  return Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CatalogDetailPage(db: widget.db, itemId: r.id),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                  width: 2,
                                  height: 32,
                                  color: catColor.withValues(alpha: 0.5)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.1),
                                            border: Border.all(
                                                color: catColor.withValues(alpha: 0.3)),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Text(catLabel,
                                              style: TextStyle(
                                                  color: catColor,
                                                  fontSize: 9,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('PATCH ${r.patch}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.4),
                                                letterSpacing: 1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: cyan.withValues(alpha: 0.5), size: 18),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: outline),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String cat, Color cyan) {
    switch (cat) {
      case 'WEAPONS': return const Color(0xFFFF4C6A);
      case 'AMMO': return const Color(0xFFFF9800);
      case 'SHIP PARTS': return const Color(0xFF7B8CDE);
      case 'CLOTHING': return const Color(0xFFB44FFF);
      case 'MEDICAL': return const Color(0xFF00FF9C);
      case 'FOOD': return const Color(0xFFFFEB3B);
      case 'COMMODITIES': return const Color(0xFFFFD700);
      case 'UTILITY': return const Color(0xFF4FC3F7);
      case 'OTHER': return const Color(0xFF9E9E9E);
      default: return cyan;
    }
  }
}
