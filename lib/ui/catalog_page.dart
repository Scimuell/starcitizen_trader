import 'package:flutter/material.dart';

import '../db/app_db.dart';
import 'catalog_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.db});

  final AppDatabase db;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _q,
            decoration: const InputDecoration(
              labelText: 'Search catalog',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<CatalogItemRow>>(
            key: ValueKey(_q.text),
            future: widget.db.searchCatalog(_q.text.trim()),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const Center(child: Text('No items. Import a JSON catalog in Settings.'));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    title: Text(r.name),
                    subtitle: Text('Patch ${r.patch}'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CatalogDetailPage(db: widget.db, itemId: r.id),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
