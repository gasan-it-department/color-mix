import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/scale_providers.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/saved_formulas/formula_tile.dart';
import 'package:colormix_studio/shared/widgets/brand_mark.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;

    return AppPage(
      title: 'Home',
      // the rail already shows the brand on wider screens
      titleWidget: narrow ? const BrandLockup() : null,
      body: ListView(
        padding: pagePadding(context),
        children: [
          const _QuickActions(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 760) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentFormulas()),
                    SizedBox(width: 16),
                    Expanded(flex: 2, child: _ScaleStatusCard()),
                  ],
                );
              }
              return const Column(
                children: [
                  _ScaleStatusCard(),
                  SizedBox(height: 16),
                  _RecentFormulas(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── quick actions ──────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final newFormula = _ActionTile(
      icon: Icons.add,
      label: 'New color formula',
      caption: 'Pick a target and set the amounts',
      tinted: true,
      onTap: () => context.go(Routes.colors),
    );
    final connect = _ActionTile(
      icon: Icons.bluetooth,
      label: 'Connect scale',
      caption: 'ColorMix scale or simulator',
      onTap: () => context.go(Routes.scale),
    );
    final saved = _ActionTile(
      icon: Icons.receipt_long_outlined,
      label: 'Saved formulas',
      caption: 'Reuse and weigh again',
      onTap: () => context.go(Routes.formulas),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 640) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: newFormula),
                const SizedBox(width: 12),
                Expanded(child: connect),
                const SizedBox(width: 12),
                Expanded(child: saved),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            newFormula,
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: connect),
                  const SizedBox(width: 12),
                  Expanded(child: saved),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  /// the main action gets the pale rose wash, the rest stay outlined
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = tinted ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: tinted ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: tinted
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: tinted ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tinted
                      ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── recent formulas ────────────────────────────────────────

class _RecentFormulas extends ConsumerWidget {
  const _RecentFormulas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFormulasProvider);
    final hasAny = recent.value?.isNotEmpty ?? false;

    return SectionCard(
      title: 'Recent formulas',
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      trailing: hasAny
          ? TextButton(
              onPressed: () => context.go(Routes.formulas),
              child: const Text('View all'),
            )
          : null,
      child: switch (recent) {
        AsyncData(:final value) when value.isEmpty => const EmptyState(
          compact: true,
          icon: Icons.receipt_long_outlined,
          title: 'No saved formulas yet',
          message: 'Formulas you save will show up here.',
        ),
        AsyncData(:final value) => Column(
          children: [for (final f in value) FormulaTile(formula: f)],
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Couldn\'t load recent formulas.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

// ── scale status ───────────────────────────────────────────

class _ScaleStatusCard extends ConsumerWidget {
  const _ScaleStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleProvider);
    final connected = scale.isConnected;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SectionCard(
      title: 'Scale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? context.status.success : scheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                connected ? 'Connected' : 'Not connected',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            connected
                ? scale.device!.info.name
                : 'Connect the ColorMix scale, or use the simulated scale '
                      'to practice.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go(Routes.scale),
            icon: const Icon(Icons.bluetooth_searching, size: 18),
            label: Text(connected ? 'Manage scale' : 'Connect scale'),
          ),
        ],
      ),
    );
  }
}
