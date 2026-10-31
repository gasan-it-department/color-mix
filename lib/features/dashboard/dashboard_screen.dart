import 'dart:math' as math;

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
    final narrow = isNarrow(context);
    return AppPage(
      title: 'Home',
      titleWidget: narrow ? const BrandLockup() : null,
      body: ListView(
        padding: pagePadding(context),
        children: [
          const _StudioWelcome(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 760) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentFormulas()),
                    SizedBox(width: 20),
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
          const SizedBox(height: 24),
          Text(
            'Made for the mixing bench. Your formulas stay on this device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioWelcome extends StatelessWidget {
  const _StudioWelcome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 700;
          return Padding(
            padding: EdgeInsets.all(wide ? 32 : 22),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A LITTLE COLOR. A LOT OF POSSIBILITY.',
                        style: context.type.eyebrow.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your next color\nstarts here.',
                        style:
                            (wide
                                    ? theme.textTheme.displayMedium
                                    : theme.textTheme.headlineLarge)
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: wide ? 44 : 32,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 370),
                        child: Text(
                          'Choose a target shade, build your formula, and follow every gram.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.go(Routes.colors),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New color formula'),
                          ),
                          TextButton.icon(
                            onPressed: () => context.go(Routes.formulas),
                            icon: const Icon(Icons.arrow_outward, size: 16),
                            label: const Text('Saved formulas'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: 24),
                  const Expanded(
                    flex: 3,
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height: 250,
                        child: CustomPaint(painter: _SwatchFanPainter()),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Decorative paper swatches, separate from the target-color UI.
class _SwatchFanPainter extends CustomPainter {
  const _SwatchFanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF75543F),
      Color(0xFFB58064),
      Color(0xFFD1AB94),
      Color(0xFFE7CCAE),
    ];
    final scale = math.min(size.width / 280, size.height / 250);
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.86);
    canvas.scale(scale);
    for (var i = 0; i < colors.length; i++) {
      canvas.save();
      canvas.rotate((-30 + i * 22) * math.pi / 180);
      final paper = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-40, -206, 82, 216),
        const Radius.circular(9),
      );
      // a line, not a shadow, keeps each paper apart from the one under it
      canvas
        ..drawRRect(paper, Paint()..color = const Color(0xFFFAF6EC))
        ..drawRRect(
          paper,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFFCFC8B6),
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-34, -200, 70, 158),
          const Radius.circular(5),
        ),
        Paint()..color = colors[i],
      );
      canvas.drawLine(
        const Offset(-26, -26),
        const Offset(12, -26),
        Paint()
          ..color = const Color(0xFFB3AB99)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        const Offset(-26, -18),
        const Offset(-5, -18),
        Paint()
          ..color = const Color(0xFFD9D3C5)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset.zero,
        4,
        Paint()..color = const Color(0xFF8F947B),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwatchFanPainter oldDelegate) => false;
}

class _RecentFormulas extends ConsumerWidget {
  const _RecentFormulas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFormulasProvider);
    final hasAny = recent.value?.isNotEmpty ?? false;
    return SectionCard(
      title: 'Recent formulas',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          message: 'Save a mix you love and come back to it here.',
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

class _ScaleStatusCard extends ConsumerWidget {
  const _ScaleStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleProvider);
    final connected = scale.isConnected;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      title: 'At the mixing bench',
      padding: const EdgeInsets.all(20),
      trailing: Icon(Icons.sensors_outlined, size: 22, color: scheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? context.status.success : scheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected ? 'Connected' : 'Not connected',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            connected ? scale.device!.info.name : 'Connect your ColorMix scale, or explore the process with the simulator.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
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
