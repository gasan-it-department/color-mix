import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/shell.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/features/color_studio/color_studio_screen.dart';
import 'package:colormix_studio/features/dashboard/dashboard_screen.dart';
import 'package:colormix_studio/features/formulation/formula_editor_screen.dart';
import 'package:colormix_studio/features/history/session_detail_screen.dart';
import 'package:colormix_studio/features/saved_formulas/saved_formulas_screen.dart';
import 'package:colormix_studio/features/scale/calibration_screen.dart';
import 'package:colormix_studio/features/scale/scale_screen.dart';
import 'package:colormix_studio/features/settings/settings_screen.dart';
import 'package:colormix_studio/features/weighing/weighing_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.home,
    routes: [
      // the four tabs keep their own stacks
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.colors,
                builder: (context, state) => const ColorStudioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.formulas,
                builder: (context, state) => const SavedFormulasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.scale,
                builder: (context, state) => const ScaleScreen(),
              ),
            ],
          ),
        ],
      ),
      // full screen on every size, opened from the app bar or the rail
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/weigh/:formulaId',
        builder: (context, state) =>
            WeighingScreen(formulaId: state.pathParameters['formulaId']!),
      ),
      GoRoute(
        path: '/formula/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormulaEditorScreen(formulaId: id == 'new' ? null : id);
        },
      ),
      GoRoute(
        path: Routes.calibrate,
        builder: (context, state) => const CalibrationScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (context, state) =>
            SessionDetailScreen(sessionId: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
