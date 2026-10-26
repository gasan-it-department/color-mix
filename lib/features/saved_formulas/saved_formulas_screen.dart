import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/saved_formulas/formula_tile.dart';

class SavedFormulasScreen extends ConsumerWidget {
  const SavedFormulasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formulas = ref.watch(formulasProvider);

    return AppPage(
      title: 'Saved formulas',
      body: switch (formulas) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No saved formulas yet',
          message:
              'Pick a target color, build the formula and save it. '
              'It will show up here.',
          action: FilledButton.tonal(
            onPressed: () => context.go(Routes.colors),
            child: const Text('New color formula'),
          ),
        ),
        AsyncData(:final value) => ListView.separated(
          padding: pagePadding(context),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(indent: 60),
          itemBuilder: (context, i) => FormulaTile(formula: value[i]),
        ),
        AsyncError() => const EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t load your formulas',
          message:
              'Close the app and open it again. Your saved formulas '
              'are still on this device.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
