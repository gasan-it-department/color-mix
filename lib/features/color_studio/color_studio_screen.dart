import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/color_studio/widgets/custom_picker.dart';
import 'package:colormix_studio/features/color_studio/widgets/labels_sheet.dart';
import 'package:colormix_studio/features/color_studio/widgets/palette_grid.dart';
import 'package:colormix_studio/features/color_studio/widgets/recipe_panel.dart';
import 'package:colormix_studio/features/color_studio/widgets/target_card.dart';

/// two panes from 840 px (picker | target + recipe), on phones the target
/// sits in a pinned strip and the recipe opens in a sheet
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
                    padding: EdgeInsets.fromLTRB(24, 8, 12, 24),
                  ),
                ),
                SizedBox(width: 360, child: _SidePane()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TargetStrip(),
              Expanded(
                child: _PickerPane(
                  padding: pagePadding(context).copyWith(top: 16),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 24),
      children: const [TargetCard(), SizedBox(height: 12), RecipePanel()],
    );
  }
}

class _PickerPane extends ConsumerWidget {
  const _PickerPane({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(studioModeProvider);

    return ListView(
      padding: padding,
      children: [
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
              icon: Icon(Icons.colorize_outlined),
              label: Text('Custom color'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) =>
              ref.read(studioModeProvider.notifier).set(s.first),
        ),
        const SizedBox(height: 16),
        switch (mode) {
          StudioMode.palette => const PaletteGrid(),
          StudioMode.custom => const CustomPicker(),
        },
      ],
    );
  }
}
