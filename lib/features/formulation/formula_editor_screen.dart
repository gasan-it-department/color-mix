import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/constants/app_info.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/core/widgets/confirm_sheet.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/features/formulation/formula_seed.dart';
import 'package:colormix_studio/features/formulation/widgets/developer_section.dart';
import 'package:colormix_studio/features/formulation/widgets/part_row.dart';
import 'package:colormix_studio/features/formulation/widgets/result_card.dart';
import 'package:colormix_studio/features/history/session_tile.dart';
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/features/weighing/session_repository.dart';
import 'package:colormix_studio/features/weighing/start_weighing_sheet.dart';
import 'package:colormix_studio/features/weighing/weighing_state.dart'
    show developerRgb;
import 'package:colormix_studio/shared/models/color_formula.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';
import 'package:colormix_studio/shared/widgets/label_tag.dart';

/// new formula for the picked color, or a saved one by id
class FormulaEditorScreen extends ConsumerWidget {
  const FormulaEditorScreen({super.key, this.formulaId});

  final String? formulaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = formulaId;

    if (id == null) {
      final target = ref.read(colorTargetProvider);
      if (target == null) {
        return _Message(
          title: 'Pick a target color first',
          message:
              'Choose a demo shade or your own color, then create the '
              'formula from there.',
          action: FilledButton.tonal(
            onPressed: () => context.go(Routes.colors),
            child: const Text('Choose a color'),
          ),
        );
      }
      final settings = ref.read(settingsProvider);
      return _FormulaEditor(
        seed: FormulaSeed.fromTarget(
          target,
          dyeDg: settings.defaultDyeDg,
          unit: settings.formulaUnit,
        ),
      );
    }

    return switch (ref.watch(formulaByIdProvider(id))) {
      AsyncData(value: final f?) => _FormulaEditor(
        seed: FormulaSeed.fromFormula(f),
      ),
      AsyncData() => const _Message(
        title: 'Formula not found',
        message: 'It may have been deleted.',
      ),
      AsyncError() => const _Message(
        title: 'Couldn\'t open this formula',
        message:
            'Go back and try again. Your saved formulas are still on '
            'this device.',
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formula')),
      body: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: title,
        message: message,
        action: action,
      ),
    );
  }
}

// ── editor ─────────────────────────────────────────────────

class _Part {
  _Part({
    required this.id,
    required this.displayRgb,
    String name = '',
    String percent = '',
    this.form = ProductForm.cream,
    int? densityMilli,
  }) : name = TextEditingController(text: name),
       percent = TextEditingController(text: percent),
       density = TextEditingController(
         text: densityMilli == null ? '' : densityText(densityMilli),
       );

  final String id;
  final int displayRgb;
  final TextEditingController name;
  final TextEditingController percent;

  /// g per mL, empty = the form's figure
  final TextEditingController density;
  ProductForm form;

  void dispose() {
    name.dispose();
    percent.dispose();
    density.dispose();
  }
}

/// what goes in a density field: null when it's empty or not a number,
/// which saves as "the form's figure"
int? _typedDensity(TextEditingController c) {
  final d = parseDensityMilli(c.text);
  return d != null && d >= minDensityMilli && d <= maxDensityMilli ? d : null;
}

class _FormulaEditor extends ConsumerStatefulWidget {
  const _FormulaEditor({required this.seed});

  final FormulaSeed seed;

  @override
  ConsumerState<_FormulaEditor> createState() => _FormulaEditorState();
}

class _FormulaEditorState extends ConsumerState<_FormulaEditor> {
  final _name = TextEditingController();
  final _dye = TextEditingController();
  final _notes = TextEditingController();
  final _customRatio = TextEditingController();
  final _devDensity = TextEditingController();
  final List<_Part> _parts = [];

  MeasureUnit _unit = MeasureUnit.g;

  /// the exact grams behind the dye field while it only shows a conversion
  /// (opened, or the unit switched). typing in the field drops it
  int? _pinnedDyeDg;
  String? _pinnedDyeText;

  /// the seed this editor opened with. a new formula's seed gets a fresh id
  /// every time the route rebuilds (coming back from weighing does that), so
  /// widget.seed can't be trusted after the first build
  late final FormulaSeed _seed;

  /// what reset goes back to: the starting point, then the last save
  late FormulaSeed _baseline;

  late DeveloperMode _devMode;
  int? _presetRatio;
  int? _volume;
  ProductForm _devForm = ProductForm.cream;
  bool _saved = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seed = widget.seed;
    _baseline = _seed;
    _saved = _seed.isSaved;
    _load(_seed);
  }

  @override
  void dispose() {
    _name.dispose();
    _dye.dispose();
    _notes.dispose();
    _customRatio.dispose();
    _devDensity.dispose();
    for (final p in _parts) {
      p.dispose();
    }
    super.dispose();
  }

  void _load(FormulaSeed s) {
    _name.text = s.name;
    _unit = s.unit;
    _notes.text = s.notes;
    for (final p in _parts) {
      p.dispose();
    }
    _parts
      ..clear()
      ..addAll([
        for (final p in s.parts)
          _Part(
            id: p.id,
            displayRgb: p.displayRgb,
            name: p.name,
            percent: p.percentHundredths == null
                ? ''
                : percentText(p.percentHundredths!),
            form: p.form,
            densityMilli: p.densityMilli,
          ),
      ]);
    _devMode = s.developerMode;
    _presetRatio = s.developerMode == DeveloperMode.preset
        ? s.ratioHundredths
        : null;
    _customRatio.text =
        s.developerMode == DeveloperMode.custom && s.ratioHundredths != null
        ? ratioText(s.ratioHundredths!)
        : '';
    _volume = s.developerVolume;
    _devForm = s.developerForm;
    _devDensity.text = s.developerDensityMilli == null
        ? ''
        : densityText(s.developerDensityMilli!);
    // everything else has to be in place first: a volume depends on the
    // colors' shares and densities
    _showDye(s.dyeDg);
    _dirty = false;
  }

  FormulaInputs _inputsWith({int? pinnedDyeDg}) => FormulaInputs(
    name: _name.text,
    dyeText: _dye.text,
    parts: [
      for (final p in _parts)
        PartInput(
          name: p.name.text,
          percentText: p.percent.text,
          form: p.form,
          densityText: p.density.text,
        ),
    ],
    developerMode: _devMode,
    presetRatioHundredths: _presetRatio,
    customRatioText: _customRatio.text,
    notes: _notes.text,
    unit: _unit,
    developerForm: _devForm,
    developerDensityText: _devDensity.text,
    pinnedDyeDg: pinnedDyeDg,
  );

  FormulaInputs get _inputs {
    final pinned = _dye.text == _pinnedDyeText ? _pinnedDyeDg : null;
    final withPin = _inputsWith(pinnedDyeDg: pinned);
    if (pinned == null || !_unit.isVolume) return withPin;
    // a volume moves with the densities, forms and shares. once the pinned
    // grams don't come to what the field says any more, the field wins
    final v = calculateFormula(withPin).dyeValue;
    return v != null && _unit.fieldTextOf(v) == _dye.text
        ? withPin
        : _inputsWith();
  }

  /// [dyeDg] written into the dye field in the current unit, and pinned
  /// so the rounding of the display doesn't change the recipe
  void _showDye(int dyeDg) {
    final r = calculateFormula(_inputsWith(pinnedDyeDg: dyeDg));
    final v = r.dyeValue ?? _unit.fromMg(dyeDg * 100);
    _dye.text = _unit.fieldTextOf(v);
    _pinnedDyeDg = dyeDg;
    _pinnedDyeText = _dye.text;
  }

  void _changed() => setState(() => _dirty = true);

  // ── edits ──

  /// − and + move by the unit's step: 5 g, 0.25 oz, 5 mL, 0.25 fl oz
  void _stepDye(int direction) {
    final current = _unit.parse(_dye.text) ?? 0;
    final next = current + direction * _unit.step;
    _dye.text = _unit.fieldTextOf(next < 0 ? 0 : next);
    _changed();
  }

  /// same grams, shown in another unit. the unit sticks for new formulas
  void _setUnit(MeasureUnit unit) {
    if (unit == _unit) return;
    final dyeDg = calculateFormula(_inputs).dyeDg;
    _unit = unit;
    // a dye amount that isn't valid stays as typed, there's nothing to
    // convert
    if (dyeDg != null) _showDye(dyeDg);
    unawaited(ref.read(settingsProvider.notifier).setFormulaUnit(unit));
    _changed();
  }

  void _addPart() {
    if (_parts.length >= maxParts) return;
    final used = _parts.map((p) => p.name.text.trim()).toSet();
    var slot = slotNames.indexWhere((n) => !used.contains(n));
    if (slot < 0) slot = _parts.length;

    // hand the new color whatever share is left
    final r = calculateFormula(_inputs);
    final left = fullPercent - r.percentSum;

    _parts.add(
      _Part(
        id: newId(),
        displayRgb: slotColors[slot],
        name: slotNames[slot],
        percent: left > 0 ? percentText(left) : '',
      ),
    );
    _changed();
  }

  void _removePart(int i) {
    _parts.removeAt(i).dispose();
    _changed();
  }

  void _splitEvenly() {
    final shares = evenSplit(_parts.length);
    for (final (i, p) in _parts.indexed) {
      p.percent.text = percentText(shares[i]);
    }
    _changed();
  }

  Future<void> _reset() async {
    if (_dirty) {
      final ok = await showConfirmSheet(
        context,
        title: 'Reset the formula?',
        message: _saved
            ? 'Everything goes back to how it was last saved.'
            : 'Everything goes back to how it started.',
        confirmLabel: 'Reset',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _load(_baseline));
  }

  // ── save ──

  /// true once it's in the database
  Future<bool> _save() async {
    final r = calculateFormula(_inputs);
    final messenger = ScaffoldMessenger.of(context);

    if (!r.canSave) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Fix the marked fields first.')),
        );
      return false;
    }

    final now = DateTime.now();
    final s = _seed;
    final formula = ColorFormula(
      id: s.id,
      name: _name.text.trim(),
      targetRgb: s.targetRgb,
      presetId: s.presetId,
      isDemo: s.isDemo,
      ingredients: [
        for (final (i, p) in _parts.indexed)
          FormulaIngredient(
            id: p.id,
            name: p.name.text.trim(),
            percentHundredths: r.percents[i]!,
            requiredDg: r.weights![i],
            displayRgb: p.displayRgb,
            form: p.form,
            densityMilli: _typedDensity(p.density),
          ),
      ],
      totalDyeDg: r.dyeDg!,
      developerRatio: r.ratioHundredths == null
          ? null
          : DeveloperRatio(r.ratioHundredths!),
      developerVolume: _devMode == DeveloperMode.none ? null : _volume,
      developerForm: _devForm,
      developerDensityMilli: _typedDensity(_devDensity),
      unit: _unit,
      developerDg: r.developerDg!,
      totalMixtureDg: r.mixtureDg!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: _baseline.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _saving = true);
    try {
      await ref.read(formulaRepositoryProvider).save(formula);
      if (!mounted) return true;
      setState(() {
        _saved = true;
        _dirty = false;
        _baseline = FormulaSeed.fromFormula(formula);
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Formula saved'),
            // an action makes it stay until tapped, this one's only a shortcut
            persist: false,
            action: SnackBarAction(
              label: 'View all',
              onPressed: () => GoRouter.of(context).go(Routes.formulas),
            ),
          ),
        );
      return true;
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t save the formula. Try again.'),
          ),
        );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// weighing works on the saved formula, so save first if needed
  Future<void> _startWeighing() async {
    if (_dirty || !_saved) {
      if (!await _save()) return;
    }
    final formula = await ref.read(formulaRepositoryProvider).find(_seed.id);
    if (formula == null || !mounted) return;
    await showStartWeighingSheet(context, formula);
  }

  Future<void> _leave() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Leave without saving?',
      message: 'Your changes to this formula will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (ok && mounted) {
      setState(() => _dirty = false);
      Navigator.of(context).pop();
    }
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final r = calculateFormula(_inputs);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final result = ResultCard(
      partNames: [for (final p in _parts) p.name.text],
      partColors: [for (final p in _parts) p.displayRgb],
      result: r,
      developerMode: _devMode,
      onSave: wide ? () => _save() : null,
      onStartWeighing: r.canSave ? _startWeighing : null,
      saving: _saving,
    );
    // nothing to show before the first save
    final history = _saved
        ? _HistoryCard(formulaId: _seed.id)
        : const SizedBox.shrink();

    final inputs = [
      _HeaderCard(
        seed: _seed,
        nameController: _name,
        nameError: r.errorFor(IssueField.name),
        onChanged: _changed,
      ),
      const SizedBox(height: 12),
      _DyeCard(
        controller: _dye,
        unit: _unit,
        onUnit: _setUnit,
        error: r.errorFor(IssueField.dye),
        onChanged: _changed,
        onStep: _stepDye,
      ),
      const SizedBox(height: 12),
      _ColorsCard(
        parts: _parts,
        result: r,
        onChanged: _changed,
        onAdd: _addPart,
        onRemove: _removePart,
        onSplit: _splitEvenly,
      ),
      const SizedBox(height: 12),
      DeveloperSection(
        mode: _devMode,
        presetRatio: _presetRatio,
        customController: _customRatio,
        volume: _volume,
        form: _devForm,
        onForm: (f) {
          _devForm = f;
          _changed();
        },
        error: r.errorFor(IssueField.developer),
        onMode: (m) {
          _devMode = m;
          if (m != DeveloperMode.preset) _presetRatio = null;
          _changed();
        },
        onPreset: (ratio) {
          _devMode = DeveloperMode.preset;
          _presetRatio = ratio;
          _changed();
        },
        onCustomChanged: _changed,
        onVolume: (v) {
          _volume = v;
          _changed();
        },
      ),
      // only needed to turn grams into mL, out of the way otherwise
      if (_unit.isVolume) ...[
        const SizedBox(height: 12),
        _DensityCard(
          unit: _unit,
          parts: _parts,
          result: r,
          showDeveloper: _devMode != DeveloperMode.none,
          developerForm: _devForm,
          developerController: _devDensity,
          onChanged: _changed,
        ),
      ],
      const SizedBox(height: 12),
      SectionCard(
        title: 'Notes',
        child: TextField(
          controller: _notes,
          onChanged: (_) => _changed(),
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Optional, e.g. client, starting level, processing time',
            errorText: r.errorFor(IssueField.notes),
          ),
        ),
      ),
    ];

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_saved ? 'Edit formula' : 'New formula'),
          actions: [
            IconButton(
              tooltip: 'Reset',
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: wide
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(32, 16, 12, 32),
                          children: inputs,
                        ),
                      ),
                      SizedBox(
                        width: 380,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 16, 32, 32),
                          children: [result, history],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ...inputs,
                  const SizedBox(height: 12),
                  result,
                  history,
                ],
              ),
        bottomNavigationBar: wide
            ? null
            : _SaveBar(
                mixture: r.mixtureAmount,
                saving: _saving,
                onSave: () => _save(),
              ),
      ),
    );
  }
}

// ── sections ───────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.seed,
    required this.nameController,
    required this.onChanged,
    this.nameError,
  });

  final FormulaSeed seed;
  final TextEditingController nameController;
  final VoidCallback onChanged;
  final String? nameError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorFromRgb(seed.targetRgb),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target color',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      seed.targetLabel,
                      // two lines rather than cutting the hex off on phones
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (seed.isDemo)
                const LabelTag('Demo recipe', tone: TagTone.warning),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Formula name',
              errorText: nameError,
            ),
          ),
          if (seed.isDemo) ...[
            const SizedBox(height: 10),
            Text(
              'Started from a demo recipe. Check the percentages against the '
              'real products before using it on a client.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DyeCard extends StatelessWidget {
  const _DyeCard({
    required this.controller,
    required this.unit,
    required this.onUnit,
    required this.onChanged,
    required this.onStep,
    this.error,
  });

  final TextEditingController controller;
  final MeasureUnit unit;
  final ValueChanged<MeasureUnit> onUnit;
  final VoidCallback onChanged;

  /// -1 or +1, a step of the unit
  final ValueChanged<int> onStep;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // in the field, like a color's form: what the number means
    final unitMenu = PopupMenuButton<MeasureUnit>(
      tooltip: 'Unit',
      initialValue: unit,
      onSelected: onUnit,
      itemBuilder: (_) => [
        for (final u in MeasureUnit.values)
          PopupMenuItem(
            value: u,
            child: Text(u.isVolume ? '${u.symbol}  (by volume)' : u.symbol),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unit.symbol,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    return SectionCard(
      title: 'Dye amount',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.outlined(
            tooltip: 'Less dye',
            onPressed: () => onStep(-1),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              ],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'StudioSans',
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                suffixIcon: unitMenu,
                suffixIconConstraints: const BoxConstraints(minHeight: 32),
                helperText: 'All colors together, not counting developer',
                helperMaxLines: 2,
                errorText: error,
                errorMaxLines: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            tooltip: 'More dye',
            onPressed: () => onStep(1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ColorsCard extends StatelessWidget {
  const _ColorsCard({
    required this.parts,
    required this.result,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onSplit,
  });

  final List<_Part> parts;
  final FormulaResult result;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    final r = result;

    return SectionCard(
      title: 'Colors',
      trailing: parts.length > 1
          ? TextButton(onPressed: onSplit, child: const Text('Split evenly'))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in parts.indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
            PartRow(
              key: ValueKey(p.id),
              displayRgb: p.displayRgb,
              nameController: p.name,
              percentController: p.percent,
              onChanged: onChanged,
              amount: r.partAmount(i),
              nameError: r.errorFor(IssueField.partName, part: i),
              percentError: r.errorFor(IssueField.partPercent, part: i),
              onRemove: parts.length > 1 ? () => onRemove(i) : null,
              form: p.form,
              onForm: (f) {
                p.form = f;
                onChanged();
              },
            ),
          ],
          const SizedBox(height: 12),
          // wraps on narrow phones once the total grows to '33.3% · 66.7% left'
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              if (parts.length < maxParts)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add color'),
                ),
              _PercentTotal(sum: r.percentSum),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentTotal extends StatelessWidget {
  const _PercentTotal({required this.sum});

  final int sum;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ok = sum == fullPercent;

    final text = ok
        ? 'Total 100%'
        : sum < fullPercent
        ? 'Total ${formatPercentHundredths(sum)} · ${formatPercentHundredths(fullPercent - sum)} left'
        : 'Total ${formatPercentHundredths(sum)} · ${formatPercentHundredths(sum - fullPercent)} over';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.error_outline,
          size: 18,
          color: ok ? context.status.success : scheme.error,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ok ? null : scheme.error,
          ),
        ),
      ],
    );
  }
}

/// past weighings of this formula, the newest few
class _HistoryCard extends ConsumerStatefulWidget {
  const _HistoryCard({required this.formulaId});

  final String formulaId;

  @override
  ConsumerState<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<_HistoryCard> {
  static const _few = 3;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider(widget.formulaId)).value;
    if (sessions == null) return const SizedBox.shrink();
    final shown = _all ? sessions : sessions.take(_few).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        title: 'Weighing history',
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: sessions.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Not weighed yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in shown)
                    SessionTile(session: s, showFormula: false),
                  if (sessions.length > _few)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _all = !_all),
                        child: Text(
                          _all ? 'Show fewer' : 'Show all ${sessions.length}',
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// only with mL or fl oz: how each product's grams turn into a volume.
/// empty fields use the form's usual figure, shown as the hint
class _DensityCard extends StatelessWidget {
  const _DensityCard({
    required this.unit,
    required this.parts,
    required this.result,
    required this.showDeveloper,
    required this.developerForm,
    required this.developerController,
    required this.onChanged,
  });

  final MeasureUnit unit;
  final List<_Part> parts;
  final FormulaResult result;
  final bool showDeveloper;
  final ProductForm developerForm;
  final TextEditingController developerController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget row({
      required Widget leading,
      required String name,
      required ProductForm form,
      required TextEditingController controller,
      String? error,
    }) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 10), child: leading),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  name.trim().isEmpty ? 'Unnamed color' : name.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: densityText(form.densityMilli),
                  suffix: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('g/mL'),
                  ),
                  // there's no label to float. always keeps the suffix
                  // showing while the field is empty, the hint alone reads
                  // as a bare number
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: error,
                  errorMaxLines: 4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Density',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The scale weighs grams, so ${unit.symbol} goes through each '
            'product\'s weight per mL. Creams and developers are close to '
            '1.00, a loose powder about half. The product sheet has the real '
            'figure. Shares and the developer ratio stay by weight.',
            style: muted,
          ),
          for (final (i, p) in parts.indexed)
            row(
              leading: ColorSwatchDot(rgb: p.displayRgb, size: 20),
              name: p.name.text,
              form: p.form,
              controller: p.density,
              error: result.errorFor(IssueField.partDensity, part: i),
            ),
          if (showDeveloper)
            row(
              leading: const ColorSwatchDot(rgb: developerRgb, size: 20),
              name: 'Developer',
              form: developerForm,
              controller: developerController,
              error: result.errorFor(IssueField.developerDensity),
            ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.mixture,
    required this.saving,
    required this.onSave,
  });

  /// already in the formula's unit
  final String mixture;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mixture',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      mixture,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'StudioSans',
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving…' : 'Save formula'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
