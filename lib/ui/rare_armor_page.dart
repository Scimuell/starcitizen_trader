import 'package:flutter/material.dart';

/// Static data — update this list when new rare sets are found in-game.
const _kRareArmors = [
  _ArmorSet(
    name: 'Artimex',
    type: 'Light',
    rarity: 'Rare',
    description:
        'A light armor staple of Hurston, worn by guards in the business district. Low protection but great movement speed.',
    locations: [
      _Location('Hurston Distribution Centers', 'Loot crates & guard drops. Disable Comm Array first.', _Risk.medium),
      _Location('Hurston Bunkers', 'Looted off guard NPCs during bunker missions.', _Risk.medium),
    ],
  ),
  _ArmorSet(
    name: 'Carnifex',
    type: 'Heavy',
    rarity: 'Boss Loot',
    description:
        'Boss armor looted off the Contested Zone boss at Checkmate Station. Boss rotates spawns with the Pyrotechnic set — clear and wait if it\'s not up.',
    locations: [
      _Location('Checkmate Station – Contested Zone', 'Kill the CZ boss. Be ready for PvP.', _Risk.extreme),
    ],
  ),
  _ArmorSet(
    name: 'Corbel',
    type: 'Heavy',
    rarity: 'Rare',
    description:
        'Added in patch 4.3.1. A solid heavy set found deep inside the ASD research facility.',
    locations: [
      _Location('ASD Onyx Research Facilities – Research Wing, Site B', 'Take the Site B elevator down. Multiple loot boxes throughout.', _Risk.high),
    ],
  ),
  _ArmorSet(
    name: 'Geist (ASD Edition)',
    type: 'Light / Stealth',
    rarity: 'Rare',
    description:
        'Black camo with red accents, stealth-oriented build. Found in the ASD Onyx Research Facilities and Onyx-type Distribution Centers.',
    locations: [
      _Location('ASD Onyx Research Facilities', 'Both Engineering and Research wings. Specific crate routes.', _Risk.high),
      _Location('Industrial / Onyx Distribution Centers', 'Repeatedly farmed crate routes.', _Risk.medium),
    ],
  ),
  _ArmorSet(
    name: 'Palatino Prototype',
    type: 'Heavy',
    rarity: 'Very Rare',
    description:
        'A bold futuristic heavy battle suit introduced in patch 4.3.2. Low spawn rate — orange armor crates hidden in hostile Distribution Centers.',
    locations: [
      _Location('Dupree Distribution Center', 'Orange crates hidden in non-obvious spots. Low spawn rate, revisit boxes.', _Risk.high),
      _Location('Greycat Industrial Distribution Center', 'Same hidden orange crate system as Dupree.', _Risk.high),
    ],
  ),
  _ArmorSet(
    name: 'Morozov Pyrotechnic',
    type: 'Heavy',
    rarity: 'Boss Loot',
    description:
        'CZ boss armor that rotates with Carnifex. Can also be farmed in ASD facilities near the ship spawn area.',
    locations: [
      _Location('Checkmate Station – Contested Zone', 'CZ boss drop. Rotates with Carnifex.', _Risk.extreme),
      _Location('ASD Facilities', 'Secondary farm spot near ship spawn.', _Risk.high),
    ],
  ),
  _ArmorSet(
    name: 'Antium',
    type: 'Medium',
    rarity: 'Rare',
    description:
        'Tactical look, popular for mid-tier combat. Found in orbital station storage and supervisor offices.',
    locations: [
      _Location('Orbital Station Storage Rooms', 'Restricted areas — may need access cards.', _Risk.medium),
      _Location('Supervisor Offices (various stations)', 'Sometimes tied to access-card missions.', _Risk.medium),
    ],
  ),
  _ArmorSet(
    name: 'Righteous',
    type: 'Medium / Heavy',
    rarity: 'Rare',
    description:
        'Found on rare loot crate spawns across Pyro derelict outposts. Good for Pyro loot run routes.',
    locations: [
      _Location('Pyro Derelict Outposts', 'Rare loot crate spawn. Run multiple outposts.', _Risk.high),
    ],
  ),
  _ArmorSet(
    name: 'Justified',
    type: 'Medium',
    rarity: 'Uncommon',
    description:
        'More common than Palatino but still worth farming. Often in the same loot pool as Righteous.',
    locations: [
      _Location('Pyro Outposts', 'Same loot pool as Righteous.', _Risk.high),
      _Location('Hostile Bunkers', 'Standard bunker loot pool.', _Risk.medium),
    ],
  ),
  _ArmorSet(
    name: 'ADP Heavy (Various Colors)',
    type: 'Heavy',
    rarity: 'Uncommon',
    description:
        'Reliable heavy armor looted off NPCs in bunker missions. Chain bunker contracts for efficient farming.',
    locations: [
      _Location('Security Post Kareah', 'Loot off dead NPCs during mercenary missions.', _Risk.medium),
      _Location('Hurston Bunkers', 'Chain bunker contracts for consistent drops.', _Risk.medium),
    ],
  ),
  _ArmorSet(
    name: 'Inquisitor',
    type: 'Heavy',
    rarity: 'Uncommon',
    description:
        'Easier to complete than Palatino. Drops from elite NPCs and loot crates in Distribution Centers and bunkers.',
    locations: [
      _Location('Distribution Centers (various)', 'Elite NPC drops and loot crates.', _Risk.medium),
      _Location('Bunker Missions', 'Standard bunker loot pool.', _Risk.medium),
    ],
  ),
];

/// Builds a plain-text summary for the AI context window.
String rareArmorContextBlob() {
  final buf = StringBuffer();
  buf.writeln('=== RARE ARMOR REFERENCE ===');
  for (final a in _kRareArmors) {
    buf.writeln('${a.name} | ${a.type} | ${a.rarity}');
    buf.writeln('  ${a.description}');
    for (final l in a.locations) {
      buf.writeln('  Location: ${l.name} — ${l.notes} [Risk: ${l.risk.label}]');
    }
  }
  buf.writeln('=== END RARE ARMOR ===');
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

class _Location {
  const _Location(this.name, this.notes, this.risk);
  final String name;
  final String notes;
  final _Risk risk;
}

class _ArmorSet {
  const _ArmorSet({
    required this.name,
    required this.type,
    required this.rarity,
    required this.description,
    required this.locations,
  });
  final String name;
  final String type;
  final String rarity;
  final String description;
  final List<_Location> locations;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class RareArmorPage extends StatefulWidget {
  const RareArmorPage({super.key});

  @override
  State<RareArmorPage> createState() => _RareArmorPageState();
}

class _RareArmorPageState extends State<RareArmorPage> {
  String _filter = '';
  String _rarityFilter = 'All';

  Color _armorChipColor(String r, BuildContext context) {
    switch (r) {
      case 'Boss Loot': return const Color(0xFFFF6B35);
      case 'Very Rare': return const Color(0xFFB44FFF);
      case 'Rare': return const Color(0xFF4FC3F7);
      case 'Uncommon': return const Color(0xFF00FF9C);
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;

    final filtered = _kRareArmors.where((a) {
      final matchesText = _filter.isEmpty ||
          a.name.toLowerCase().contains(_filter) ||
          a.type.toLowerCase().contains(_filter) ||
          a.rarity.toLowerCase().contains(_filter) ||
          a.locations.any((l) => l.name.toLowerCase().contains(_filter));
      final matchesRarity = _rarityFilter == 'All' || a.rarity == _rarityFilter;
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
                hintText: 'SEARCH ARMOUR...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _filter = ''),
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Boss Loot', 'Very Rare', 'Rare', 'Uncommon'].map((r) {
                final selected = _rarityFilter == r;
                final color = _armorChipColor(r, context);
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
                Icon(Icons.info_outline, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Long-press any card to copy location to clipboard. AI Advisor can answer questions about these sets.',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No armor matches "$_filter"',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ArmorCard(armor: filtered[i], cyan: cyan, outline: outline),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArmorCard extends StatelessWidget {
  const _ArmorCard({required this.armor, required this.cyan, required this.outline});
  final _ArmorSet armor;
  final Color cyan;
  final Color outline;

  Color _rarityColor(BuildContext context) {
    switch (armor.rarity) {
      case 'Boss Loot':
        return const Color(0xFFFF6B35);
      case 'Very Rare':
        return const Color(0xFFB44FFF);
      case 'Rare':
        return const Color(0xFF4FC3F7);
      case 'Uncommon':
        return const Color(0xFF00FF9C);
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
    return Container(
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
                  child: Text(
                    armor.name.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1, color: rarityColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.15),
                    border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(armor.rarity.toUpperCase(),
                      style: TextStyle(color: rarityColor, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
                    border: Border.all(color: outline.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(armor.type.toUpperCase(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Text(armor.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
          // Locations
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHERE TO FIND', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: cyan.withValues(alpha: 0.7), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ...armor.locations.map((l) {
                  final riskColor = _riskColor(l.risk);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(
                                '${l.notes}  •  Risk: ${l.risk.label}',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
