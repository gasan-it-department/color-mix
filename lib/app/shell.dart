import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/shared/widgets/brand_mark.dart';

typedef _Destination = ({IconData icon, IconData selectedIcon, String label});

const List<_Destination> _destinations = [
  (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  (icon: Icons.palette_outlined, selectedIcon: Icons.palette, label: 'Colors'),
  (
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Formulas',
  ),
  (icon: Icons.scale_outlined, selectedIcon: Icons.scale, label: 'Scale'),
];

/// bottom bar on phones, side rail from 600 px, rail with labels from 1100 px.
/// settings lives in the app bar (phones) or at the bottom of the rail.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) {
    // tapping the current tab again pops it back to its root
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scheme = Theme.of(context).colorScheme;

    if (width < Breakpoints.rail) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final nav = width >= Breakpoints.sidebar
        ? _Sidebar(selected: shell.currentIndex, onSelect: _select)
        : _rail(context);

    return Scaffold(
      body: Row(
        children: [
          nav,
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(child: shell),
        ],
      ),
    );
  }

  Widget _rail(BuildContext context) {
    return NavigationRail(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: _select,
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.fromLTRB(4, 12, 4, 20),
        child: BrandMark(size: 32),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Routes.settings),
            ),
          ),
        ),
      ),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

/// gmail-style sidebar for wide screens: whole row is the pill, the
/// selected one gets the rose wash and bold label
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: BrandLockup(),
            ),
            for (final (i, d) in _destinations.indexed)
              _SidebarItem(
                icon: i == selected ? d.selectedIcon : d.icon,
                label: d.label,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: false,
              onTap: () => context.push(Routes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
