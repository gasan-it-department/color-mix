import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';

/// how to set up a camera reading, the button for it, and what the last one
/// said
class CameraPanel extends ConsumerWidget {
  const CameraPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final last = ref.watch(lastCameraReadingProvider);
    final target = ref.watch(colorTargetProvider);
    // only while the reading is still the target
    final showLast =
        last != null && target?.rgb == last.rgb && target!.isCustom;

    return SectionCard(
      title: 'Read from the camera',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Close, not exact. A phone camera changes every photo, so the '
            'hair lies on a card the app knows the color of, and the card '
            'tells it what to correct.',
            style: muted,
          ),
          const SizedBox(height: 14),
          const _Step(
            icon: Icons.description_outlined,
            text: 'Lay the hair on plain white paper or a gray card.',
          ),
          const _Step(
            icon: Icons.wb_sunny_outlined,
            text:
                'Even daylight is best. No flash, no direct sun, no shadow '
                'across it.',
          ),
          const _Step(
            icon: Icons.crop_free,
            text:
                'Hold the phone 15 to 20 cm above: hair fills the middle '
                'square, card shows in the four small ones.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push(Routes.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Open camera'),
          ),
          if (showLast) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorFromRgb(last.rgb!),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last reading, now the target', style: muted),
                      Text(
                        hexFromRgb(last.rgb!),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(studioModeProvider.notifier)
                      .set(StudioMode.custom),
                  child: const Text('Fine-tune'),
                ),
              ],
            ),
            for (final w in last.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  w,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.status.warning,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
