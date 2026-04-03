import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Static rare/useful materials reference — update as new spots are discovered.
const _kMaterials = [
  _MaterialEntry(
    name: 'Quantainium',
    category: 'Commodity',
    rarity: 'Very Rare',
    description:
        'The most valuable tradeable commodity in the game. Extremely unstable — your ship will explode if it takes damage while carrying it. Only found at Lagrange mining sites. High risk, enormous reward.',
    tips: 'Use a dedicated mining ship. Fly carefully — no combat. Sell ASAP at a major hub.',
    locations: [
      _MatLocation('Aaron Halo Asteroid Belt', 'Minable in the belt around Stanton. Best yield per run.', _Risk.high),
      _MatLocation('Lagrange Point Mining Sites', 'Yela, Cellin, Daymar asteroid fields.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '127,000–140,000 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Luminite',
    category: 'Commodity',
    rarity: 'Rare',
    description:
        'High-value mineral used in advanced manufacturing. Sells for millions per haul when mined in bulk.',
    tips: 'Often found alongside Quantainium. Use a Prospector or Mole for efficient extraction.',
    locations: [
      _MatLocation('Aaron Halo Asteroid Belt', 'Best concentration in the belt.', _Risk.high),
      _MatLocation('Yela Asteroid Field', 'Solid secondary source.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '5,100,000+ aUEC per full haul',
  ),
  _MaterialEntry(
    name: 'Gold',
    category: 'Commodity',
    rarity: 'Uncommon',
    description:
        'Reliable mid-tier mining commodity. Consistent demand at most trade hubs. Good for beginners.',
    tips: 'Mine at Yela or Cellin. Sell at TDD Lorville or New Babbage for best rates.',
    locations: [
      _MatLocation('Yela Asteroid Field', 'Common spawn, easy to find.', _Risk.medium),
      _MatLocation('Cellin Surface', 'Ground mining viable.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '21,700 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Taranite',
    category: 'Commodity',
    rarity: 'Rare',
    description:
        'Dense, high-value ore. Sells well and is easier to find than Quantainium. A safer high-profit alternative.',
    tips: 'Target medium-sized asteroid deposits in the belt. Less volatile than Quantainium.',
    locations: [
      _MatLocation('Aaron Halo Belt', 'Primary source.', _Risk.high),
      _MatLocation('Microtech Moons', 'Secondary ground source.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '92,800 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Agricium',
    category: 'Commodity',
    rarity: 'Uncommon',
    description:
        'Agricultural raw material with decent trade margins. Easier to haul than mining commodities.',
    tips: 'Buy at agricultural outposts, sell at industrial hubs.',
    locations: [
      _MatLocation('Hurston Agricultural Outposts', 'Buy low here.', _Risk.medium),
      _MatLocation('TDD New Babbage', 'Sell for profit.', _Risk.medium),
    ],
    buyRange: '7,700 aUEC/unit',
    sellRange: '9,200+ aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Diamond',
    category: 'Commodity',
    rarity: 'Uncommon',
    description:
        'Classic high-value gem mineral. Consistent buyer demand. Good secondary mining target.',
    tips: 'Often in the same rocks as Gold. Multi-mineral hauls increase profit.',
    locations: [
      _MatLocation('Yela & Cellin Asteroid Fields', 'Common co-spawn with Gold.', _Risk.medium),
      _MatLocation('Aaron Halo Belt', 'Higher concentration.', _Risk.high),
    ],
    buyRange: null,
    sellRange: '7,600 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Laranite',
    category: 'Commodity',
    rarity: 'Rare',
    description:
        'High density, high value ore. Rarer than Gold but much more profitable per unit. Worth scanning for specifically.',
    tips: 'Use enhanced scanner on your mining ship. Sells well at TDD Lorville.',
    locations: [
      _MatLocation('Aaron Halo Belt', 'Best source.', _Risk.high),
      _MatLocation('Daymar Surface', 'Ground mining option.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '38,200 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Hadanite',
    category: 'Gem',
    rarity: 'Very Rare',
    description:
        'Extremely rare gem found only in specific cave systems. Cannot be mined with ships — hand mining only. One of the highest value per-unit items in the game.',
    tips: 'Use the Pyro Opal Cave near Wala or Daymar caves. Bring a multitool with a mining attachment.',
    locations: [
      _MatLocation('Wala Cave Systems', 'Best known spawn. Requires EVA and cave navigation.', _Risk.high),
      _MatLocation('Daymar Caves', 'Secondary spawn, less consistent.', _Risk.high),
      _MatLocation('Pyro Asteroid Caves', 'Newer spawn added in Pyro update.', _Risk.extreme),
    ],
    buyRange: null,
    sellRange: '542,000 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Aphorite',
    category: 'Gem',
    rarity: 'Rare',
    description:
        'Hand-minable gem found in cave systems. Very high value, compact carry — great for solo runs on foot.',
    tips: 'Prioritise over ground-mined ores when doing cave runs. Sells quickly.',
    locations: [
      _MatLocation('Microtech Moon Caves', 'Consistent spawn.', _Risk.medium),
      _MatLocation('Yela Cave Systems', 'Good secondary source.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '136,100 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Dolivine',
    category: 'Gem',
    rarity: 'Rare',
    description:
        'Cave gem with solid sell price. Often found alongside Aphorite in the same deposits.',
    tips: 'Run cave loops — collect everything, sort by value later.',
    locations: [
      _MatLocation('Cellin Caves', 'Reliable spawn.', _Risk.medium),
      _MatLocation('Hurston Moon Caves', 'Secondary source.', _Risk.medium),
    ],
    buyRange: null,
    sellRange: '146,400 aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Medical Supplies',
    category: 'Trade Good',
    rarity: 'Common',
    description:
        'High-demand trade good with good margins between systems. Essential for trading routes.',
    tips: 'Buy at Lorville medical district, sell at remote outposts for margin.',
    locations: [
      _MatLocation('Lorville — CentroMed', 'Primary buyer source.', _Risk.medium),
      _MatLocation('Various Outposts', 'Sell destination.', _Risk.medium),
    ],
    buyRange: '5,200 aUEC/unit',
    sellRange: '6,800+ aUEC/unit',
  ),
  _MaterialEntry(
    name: 'Stims',
    category: 'Trade Good',
    rarity: 'Common',
    description:
        'Illegal in some jurisdictions but high margin. Carry risk of scan/contraband seizure.',
    tips: 'Only run stim routes if you know the legal status at your destination.',
    locations: [
      _MatLocation('Grim HEX', 'Primary buy location.', _Risk.high),
      _MatLocation('Pyro Outlaw Stations', 'Good secondary source.', _Risk.extreme),
    ],
    buyRange: '38,600 aUEC/unit',
    sellRange: '55,000+ aUEC/unit',
  ),
];

/// Plain-text blob for AI context.
String rareMaterialsContextBlob() {
  final buf = StringBuffer();
  buf.writeln('=== RARE & USEFUL MATERIALS REFERENCE ===');
  for (final m in _kMaterials) {
    buf.writeln('${m.name} | ${m.category} | ${m.rarity}');
    buf.writeln('  ${m.description}');
    if (m.buyRange != null) buf.writeln('  Buy: ${m.buyRange}');
    if (m.sellRange != null) buf.writeln('  Sell: ${m.sellRange}');
    buf.writeln('  Tip: ${m.tips}');
    for (final l in m.locations) {
      buf.writeln('  Location: ${l.name} — ${l.notes} [Risk: ${l.risk.label}]');
    }
  }
  buf.writeln('=== END MATERIALS ===');
  return buf.toString();
}

// ─── Data model ──────────────────────────────────────────────────────────────

enum _Risk {
  medium('Medium'),
  high('High'),
  extreme('Extreme / PvP');

  const _Risk(this.label);
  final String label;
}

class _MatLocation {
  const _MatLocation(this.name, this.notes, this.risk);
  final String name;
  final String notes;
  final _Risk risk;
}

class _MaterialEntry {
  const _MaterialEntry({
    required this.name,
    required this.category,
    required this.rarity,
    required this.description,
    required this.tips,
    required this.locations,
    required this.buyRange,
    required this.sellRange,
  });
  final String name;
  final String category;
  final String rarity;
  final String description;
  final String tips;
  final List<_MatLocation> locations;
  final String? buyRange;
  final String? sellRange;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class RareMaterialsPage extends StatefulWidget {
  const RareMaterialsPage({super.key});

  @override
  State<RareMaterialsPage> createState() => _RareMaterialsPageState();
}

class _RareMaterialsPageState extends State<RareMaterialsPage> {
  String _filter = '';
  String _rarityFilter = 'All';

  Color _matChipColor(String r, BuildContext context) {
    switch (r) {
      case 'Very Rare': return const Color(0xFFB44FFF);
      case 'Rare': return const Color(0xFF4FC3F7);
      case 'Uncommon': return const Color(0xFF00FF9C);
      case 'Common': return Theme.of(context).colorScheme.onSurface;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    final filtered = _kMaterials.where((m) {
      final matchesText = _filter.isEmpty ||
          m.name.toLowerCase().contains(_filter) ||
          m.category.toLowerCase().contains(_filter) ||
          m.rarity.toLowerCase().contains(_filter) ||
          m.locations.any((l) => l.name.toLowerCase().contains(_filter));
      final matchesRarity = _rarityFilter == 'All' || m.rarity == _rarityFilter;
      return matchesText && matchesRarity;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'SEARCH MATERIALS...',
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                    letterSpacing: 1),
                prefixIcon: Icon(Icons.search, size: 18, color: cyan),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _filter = ''),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Very Rare', 'Rare', 'Uncommon', 'Common'].map((r) {
                final selected = _rarityFilter == r;
                final color = _matChipColor(r, context);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _rarityFilter = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(color: selected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(r.toUpperCase(),
                          style: TextStyle(
                              color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10, letterSpacing: 1.5,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Long-press any card to copy location. AI Advisor knows all materials listed here.',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No materials match "$_filter"',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _MaterialCard(mat: filtered[i], cyan: cyan, outline: outline),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.mat, required this.cyan, required this.outline});
  final _MaterialEntry mat;
  final Color cyan;
  final Color outline;

  Color _rarityColor(BuildContext context) {
    switch (mat.rarity) {
      case 'Very Rare':
        return const Color(0xFFB44FFF);
      case 'Rare':
        return const Color(0xFF4FC3F7);
      case 'Uncommon':
        return const Color(0xFF00FF9C);
      case 'Common':
        return Theme.of(context).colorScheme.onSurface;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Color _riskColor(_Risk risk) {
    switch (risk) {
      case _Risk.extreme:
        return const Color(0xFFFF4444);
      case _Risk.high:
        return const Color(0xFFFF9800);
      case _Risk.medium:
        return const Color(0xFFFFEB3B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(context);
    return GestureDetector(
      onLongPress: () {
        final locationText = mat.locations.map((l) => l.name).join(', ');
        Clipboard.setData(ClipboardData(text: '${mat.name}: $locationText'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location copied to clipboard')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Container(width: 3, height: 20, color: rarityColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mat.name.toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1,
                              color: rarityColor),
                        ),
                        Text(
                          mat.category,
                          style: TextStyle(
                              fontSize: 10,
                              color: rarityColor.withValues(alpha: 0.7),
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(mat.rarity.toUpperCase(),
                        style: TextStyle(
                            color: rarityColor,
                            fontSize: 9,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(mat.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85))),
            ),
            // Prices
            if (mat.buyRange != null || mat.sellRange != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Row(
                  children: [
                    if (mat.buyRange != null) ...[
                      _PriceChip(label: 'BUY', value: mat.buyRange!, color: cyan),
                      const SizedBox(width: 8),
                    ],
                    if (mat.sellRange != null)
                      _PriceChip(
                          label: 'SELL', value: mat.sellRange!, color: const Color(0xFF00FF9C)),
                  ],
                ),
              ),
            // Tip
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TIP  ',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: const Color(0xFFFFEB3B).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(mat.tips,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65))),
                  ),
                ],
              ),
            ),
            // Locations
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Column(
                crossAxi