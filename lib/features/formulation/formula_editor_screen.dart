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
import 'package:colormix_studio/features/saved_formulas/formula_providers.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';
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
      final dyeDg = ref.read(settingsProvider).defaultDyeDg;
      return _FormulaEditor(seed: FormulaSeed.fromTarget(target, dyeDg: dyeDg));
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
  }) : name = TextEditingController(text: name),
       percent = TextEditingController(text: percent);

  final String id;
  final int displayRgb;
  final TextEditingController name;
  final TextEditingController percent;

  void dispose() {
    name.dispose();
    percent.dispose();
  }
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
  final List<_Part> _parts = [];

  /// what reset goes back to: the starting point, then the last save
  late FormulaSeed _baseline;

  late DeveloperMode _devMode;
  int? _presetRatio;
  int? _volume;
  bool _saved = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _baseline = widget.seed;
    _saved = widget.seed.isSaved;
    _load(widget.seed);
  }

  @override
  void dispose() {
    _name.dispose();
    _dye.dispose();
    _notes.dispose();
    _customRatio.dispose();
    for (final p in _parts) {
      p.dispose();
    }
    super.dispose();
  }

  void _load(FormulaSeed s) {
    _name.text = s.name;
    _dye.text = decigramsText(s.dyeDg);
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
    _dirty = false;
  }

  FormulaInputs get _inputs => FormulaInputs(
    name: _name.text,
    dyeText: _dye.text,
    parts: [
      for (final p in _parts)
        PartInput(name: p.name.text, percentText: p.percent.text),
    ],
    developerMode: _devMode,
    presetRatioHundredths: _presetRatio,
    customRatioText: _customRatio.text,
    notes: _notes.text,
  );

  void _changed() => setState(() => _dirty = true);

  // ── edits ──

  void _stepDye(int deltaDg) {
    final current = parseDecigrams(_dye.text) ?? _baseline.dyeDg;
    final next = (current + deltaDg).clamp(0, scaleCapacityDg);
    _dye.text = decigramsText(next);
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

  Future<void> _save() async {
    final r = calculateFormula(_inputs);
    final messenger = ScaffoldMessenger.of(context);

    if (!r.canSave) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Fix the marked fields first.')),
        );
      return;
    }

    final now = DateTime.now();
    final s = widget.seed;
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
          ),
      ],
      totalDyeDg: r.dyeDg!,
      developerRatio: r.ratioHundredths == null
          ? null
          : DeveloperRatio(r.ratioHundredths!),
      developerVolume: _devMode == DeveloperMode.none ? null : _volume,
      developerDg: r.developerDg!,
      totalMixtureDg: r.mixtureDg!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: _baseline.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _saving = true);
    try {
      await ref.read(formulaRepositoryProvider).save(formula);
      if (!mounted) return;
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
            action: SnackBarAction(
              label: 'View all',
              onPressed: () => GoRouter.of(context).go(Routes.formulas),
            ),
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t save the formula. Try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      onSave: wide ? _save : null,
      saving: _saving,
    );

    final inputs = [
      _HeaderCard(
        seed: widget.seed,
        nameController: _name,
        nameError: r.errorFor(IssueField.name),
        onChanged: _changed,
      ),
      const SizedBox(height: 12),
      _DyeCard(
        controller: _dye,
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
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 12, 32),
                          children: inputs,
                        ),
                      ),
                      SizedBox(
                        width: 380,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 24, 32),
                          children: [result],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [...inputs, const SizedBox(height: 12), result],
              ),
        bottomNavigationBar: wide
            ? null
            : _SaveBar(mixtureDg: r.mixtureDg, saving: _saving, onSave: _save),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorFromRgb(seed.targetRgb),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target color',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      seed.targetLabel,
                      // two lines rather than cutting the hex off on phones
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
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
    required this.onChanged,
    required this.onStep,
    this.error,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<int> onStep;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Dye amount',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.outlined(
            tooltip: 'Less dye',
            onPressed: () => onStep(-50),
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
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                suffixText: 'g',
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
            onPressed: () => onStep(50),
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
              weightDg: r.weights?[i],
              nameError: r.errorFor(IssueField.partName, part: i),
              percentError: r.errorFor(IssueField.partPercent, part: i),
              onRemove: parts.length > 1 ? () => onRemove(i) : null,
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

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.mixtureDg,
    required this.saving,
    required this.onSave,
  });

  final int? mixtureDg;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
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
                      mixtureDg == null ? '—' : formatDecigrams(mixtureDg!),
                      style: theme.textTheme.titleLarge?.copyWith(
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
