import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/color_studio/widgets/custom_picker.dart';
import 'package:colormix_studio/features/color_studio/widgets/labels_sheet.dart';
import 'package:colormix_studio/features/color_studio/widgets/palette_grid.dart';
import 'package:colormix_studio/features/color_studio/widgets/recipe_panel.dart';
import 'package:colormix_studio/features/color_studio/widgets/target_card.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';

/// A shade library beside a live target on desktop. On phones, keep the
/// current target in view while the shade library scrolls underneath it.
class ColorStudioScreen extends StatelessWidget {
  const ColorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Color Studio',
      actions: [
        IconButton(
          tooltip: 'What the labels mean',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showLabelsSheet(context),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 840) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PickerPane(
                    showIntro: true,
                    padding: EdgeInsets.fromLTRB(32, 12, 28, 32),
                  ),
                ),
                SizedBox(width: 344, child: _SidePane()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TargetStrip(),
              Expanded(
                child: _PickerPane(
                  padding: pagePadding(context).copyWith(top: 8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidePane extends StatelessWidget {
  const _SidePane();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 24, 24),
      children: const [TargetCard(), SizedBox(height: 16), RecipePanel()],
    );
  }
}

class _PickerPane extends ConsumerWidget {
  const _PickerPane({required this.padding, this.showIntro = false});

  final EdgeInsets padding;
  final bool showIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(studioModeProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: padding,
      children: [
        if (showIntro) ...[
          Text(
            'A shade to start with.',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontFamily: 'StudioSerif',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${demoShades.length} demo shades. Or a color of your own.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],
        SegmentedButton<StudioMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(
              value: StudioMode.palette,
              icon: Icon(Icons.palette_outlined),
              label: Text('Demo palette'),
            ),
            ButtonSegment(
              value: StudioMode.custom,
              icon: Icon(Icons.tune),
              label: Text('Custom color'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) =>
              ref.read(studioModeProvider.notifier).set(s.first),
        ),
        SizedBox(height: showIntro ? 24 : 16),
        switch (mode) {
          StudioMode.palette => const PaletteGrid(),
          StudioMode.custom => const CustomPicker(),
        },
      ],
    );
  }
}
