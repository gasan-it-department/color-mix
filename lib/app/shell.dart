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

/// Persistent workspace navigation for a wide studio workbench.
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 240,
      color: scheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 44),
                child: BrandLockup(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 0, 14),
                child: Text(
                  'THE WORKSPACE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ),
              for (final (i, d) in _destinations.indexed)
                _SidebarItem(
                  icon: i == selected ? d.selectedIcon : d.icon,
                  label: d.label,
                  selected: i == selected,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your personal studio',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Formulas and sessions, saved on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Divider(),
              ),
              _SidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: false,
                onTap: () => context.push(Routes.settings),
              ),
            ],
          ),
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
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 50,
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
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (selected) ...[
                    Icon(Icons.arrow_forward, size: 17, color: fg),
                    const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
