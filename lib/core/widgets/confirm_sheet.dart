import 'package:flutter/material.dart';

/// yes/no as a bottom sheet instead of a dialog. true only on confirm
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}
