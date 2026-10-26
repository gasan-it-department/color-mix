import 'package:flutter/material.dart';

import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// the three levels the blueprint wants kept apart
Future<void> showLabelsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => const _LabelsSheet(),
  );
}

class _LabelsSheet extends StatelessWidget {
  const _LabelsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What the labels mean', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          const _Item(
            tag: LabelTag('Visual target', tone: TagTone.accent),
            text:
                'The color on screen. It shows what you\'re aiming for, '
                'not what the dye will do on hair.',
          ),
          const _Item(
            tag: LabelTag('Demo only', tone: TagTone.warning),
            text:
                'Example percentages so you can try the app. Not tested '
                'with real products.',
          ),
          const _Item(
            tag: LabelTag('Validated', tone: TagTone.success),
            text:
                'A formula a professional has tested with the real '
                'products. This prototype doesn\'t have any yet.',
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.tag, required this.text});

  final Widget tag;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tag,
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
