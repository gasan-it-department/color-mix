import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/features/history/session_tile.dart';
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/saved_formulas/formula_tile.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/start_weighing_sheet.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/models/weighing_session.dart';

enum SavedView { formulas, history }

/// saved formulas and every weighing session, one search box for both
class SavedFormulasScreen extends ConsumerStatefulWidget {
  const SavedFormulasScreen({super.key});

  @override
  ConsumerState<SavedFormulasScreen> createState() =>
      _SavedFormulasScreenState();
}

class _SavedFormulasScreenState extends ConsumerState<SavedFormulasScreen> {
  final _search = TextEditingController();
  var _view = SavedView.formulas;

  String get _query => _search.text.trim().toLowerCase();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _formulaMatches(ColorFormula f) {
    final q = _query;
    if (q.isEmpty) return true;
    return f.name.toLowerCase().contains(q) ||
        (f.notes?.toLowerCase().contains(q) ?? false);
  }

  bool _sessionMatches(WeighingSession s) {
    final q = _query;
    if (q.isEmpty) return true;
    return s.formulaName.toLowerCase().contains(q) ||
        s.deviceName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.rail;
    final pad = pagePadding(context);

    final switcher = SegmentedButton<SavedView>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: SavedView.formulas, label: Text('Formulas')),
        ButtonSegment(value: SavedView.history, label: Text('History')),
      ],
      selected: {_view},
      onSelectionChanged: (v) => setState(() => _view = v.single),
    );

    final search = TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: _view == SavedView.formulas
            ? 'Search names and notes'
            : 'Search formula or scale',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(_search.clear),
              ),
      ),
    );

    return AppPage(
      title: 'Saved formulas',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad.left, 8, pad.right, 8),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [switcher, const SizedBox(height: 10), search],
                  )
                : Row(
                    children: [
                      switcher,
                      const Spacer(),
                      SizedBox(width: 320, child: search),
                    ],
                  ),
          ),
          Expanded(
            child: _view == SavedView.formulas
                ? _formulas(context, pad)
                : _history(context, pad),
          ),
        ],
      ),
    );
  }

  Widget _formulas(BuildContext context, EdgeInsets pad) {
    return switch (ref.watch(formulasProvider)) {
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
      AsyncData(:final value) => _list(
        pad,
        value.where(_formulaMatches).toList(),
        (f) => FormulaTile(
          formula: f,
          menu: _FormulaMenu(formula: f),
        ),
      ),
      AsyncError() => const EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn\'t load your formulas',
        message:
            'Close the app and open it again. Your saved formulas '
            'are still on this device.',
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _history(BuildContext context, EdgeInsets pad) {
    return switch (ref.watch(sessionsProvider(null))) {
      AsyncData(:final value) when value.isEmpty => const EmptyState(
        icon: Icons.history,
        title: 'No weighing sessions yet',
        message:
            'Weigh a saved formula and the session shows up here, '
            'finished or not.',
      ),
      AsyncData(:final value) => _list(
        pad,
        value.where(_sessionMatches).toList(),
        (s) => SessionTile(session: s),
      ),
      AsyncError() => const EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn\'t load the history',
        message: 'Close the app and open it again.',
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _list<T>(EdgeInsets pad, List<T> items, Widget Function(T) tile) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nothing matches "${_search.text.trim()}"',
        message: _view == SavedView.formulas
            ? 'Search looks at formula names and notes.'
            : 'Search looks at formula and scale names.',
        action: TextButton(
          onPressed: () => setState(_search.clear),
          child: const Text('Clear search'),
        ),
      );
    }
    return ListView.separated(
      padding: pad.copyWith(top: 0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 60),
      itemBuilder: (context, i) => tile(items[i]),
    );
  }
}

enum _FormulaAction { weigh, duplicate, delete }

class _FormulaMenu extends ConsumerWidget {
  const _FormulaMenu({required this.formula});

  final ColorFormula formula;

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final copy = await ref
        .read(formulaRepositoryProvider)
        .duplicate(formula.id);
    if (copy == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied as "${copy.name}"'),
          persist: false,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => router.push(Routes.formula(copy.id)),
          ),
        ),
      );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(formulaRepositoryProvider);
    final ok = await showConfirmSheet(
      context,
      title: 'Delete "${formula.name}"?',
      message:
          'The formula goes for good. Weighing sessions made with it stay '
          'in History.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(formula.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Deleted "${formula.name}"')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PopupMenuItem<_FormulaAction> item(
      _FormulaAction value,
      IconData icon,
      String label, {
      Color? color,
    }) {
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );
    }

    return PopupMenuButton<_FormulaAction>(
      tooltip: 'More for ${formula.name}',
      icon: const Icon(Icons.more_vert),
      onSelected: (a) => switch (a) {
        _FormulaAction.weigh => showStartWeighingSheet(context, formula),
        _FormulaAction.duplicate => _duplicate(context, ref),
        _FormulaAction.delete => _delete(context, ref),
      },
      itemBuilder: (context) => [
        item(_FormulaAction.weigh, Icons.scale_outlined, 'Weigh'),
        item(_FormulaAction.duplicate, Icons.copy_outlined, 'Duplicate'),
        item(
          _FormulaAction.delete,
          Icons.delete_outline,
          'Delete',
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}
