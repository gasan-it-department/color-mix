import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';

/// page scaffold shared by the tabs. on phones it adds the settings button
/// to the app bar since there's no rail to hold it.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.actions = const [],
    this.showSettings = true,
  });

  final String title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget> actions;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: narrow ? 64 : 84,
        titleSpacing: narrow ? 20 : 32,
        title:
            titleWidget ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!narrow) ...[
                  Text(
                    'COLORMIX / WORKSPACE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.6,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(title),
              ],
            ),
        actions: [
          ...actions,
          if (narrow && showSettings)
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Routes.settings),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.contentMaxWidth,
          ),
          child: body,
        ),
      ),
    );
  }
}

/// horizontal page padding, tighter on phones
EdgeInsets pagePadding(BuildContext context) {
  final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
  return EdgeInsets.fromLTRB(narrow ? 20 : 32, 12, narrow ? 20 : 32, 32);
}
