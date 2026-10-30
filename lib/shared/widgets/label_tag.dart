import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';

enum TagTone { neutral, accent, warning, success }

/// Compact informational label: 'Demo only', 'Custom color'...
class LabelTag extends StatelessWidget {
  const LabelTag(this.text, {super.key, this.tone = TagTone.neutral});

  final String text;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.status;

    final (bg, fg) = switch (tone) {
      TagTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      TagTone.accent => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TagTone.warning => (status.warningWash, status.warning),
      TagTone.success => (status.successWash, status.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
