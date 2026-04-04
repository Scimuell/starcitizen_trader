import 'package:flutter/material.dart';

import '../db/app_db.dart';
import 'ai_chat_page.dart';
import 'catalog_page.dart';
import 'dashboard_page.dart';
import 'rare_armor_page.dart';
import 'rare_guns_page.dart';
import 'rare_materials_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.db});

  final AppDatabase db;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlerts(reason: 'open'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAlerts(reason: 'resume');
    }
  }

  Future<void> _checkAlerts({required String reason}) async {
    final lines = await widget.db.evaluateTriggeredAlerts();
    if (!mounted || lines.isEmpty) return;
    final cyan = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          reason == 'open' ? 'PRICE ALERTS' : 'PRICE ALERTS',
          style: TextStyle(color: cyan, letterSpacing: 3),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('> ', style: TextStyle(color: cyan, fontFamily: 'monospace')),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('DISMISS')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        db: widget.db,
        onOpenAlerts: () {},
        onOpenProfit: () {},
      ),
      CatalogPage(db: widget.db),
      AiChatPage(db: widget.db),
      const RareGunsPage(),
      const RareArmorPage(),
      const RareMaterialsPage(),
    ];

    const titles = ['OVERVIEW', 'MARKET DATA', 'AI ADVISOR', 'WEAPONS', 'ARMOUR', 'MATERIALS'];

    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(title: titles[_index.clamp(0, 5)]),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => SettingsPage(db: widget.db)),
              );
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 9,
                letterSpacing: 0.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              );
            }),
          ),
          child: NavigationBar(
          selectedIndex: _index.clamp(0, 5),
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'OVERVIEW'),
            NavigationDestination(icon: Icon(Icons.dataset_outlined), selectedIcon: Icon(Icons.dataset), label: 'MARKET'),
            NavigationDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal), label: 'AI'),
            NavigationDestination(icon: Icon(Icons.gps_fixed_outlined), selectedIcon: Icon(Icons.gps_fixed), label: 'WEAPONS'),
            NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'ARMOUR'),
            NavigationDestination(icon: Icon(Icons.diamond_outlined), selectedIcon: Icon(Icons.diamond), label: 'MATS'),
          ],
        ),
        ),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SC-style diamond logo mark
        CustomPaint(
          size: const Size(16, 16),
          painter: _DiamondPainter(color: cyan),
        ),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
    // Inner cross lines like SC logo
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), linePaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
  }

  @override
  bool shouldRepaint(_DiamondPainter old) => old.color != color;
}
