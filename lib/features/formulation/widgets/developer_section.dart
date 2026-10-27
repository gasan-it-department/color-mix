import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/formulation/formula_math.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

const developerVolumes = [10, 20, 30, 40];

/// ratio by weight (dye : developer) and, as a record only, the strength
class DeveloperSection extends StatelessWidget {
  const DeveloperSection({
    super.key,
    required this.mode,
    required this.presetRatio,
    required this.customController,
    required this.volume,
    required this.onMode,
    required this.onPreset,
    required this.onCustomChanged,
    required this.onVolume,
    required this.form,
    required this.onForm,
    this.error,
  });

  final DeveloperMode mode;
  final int? presetRatio;
  final TextEditingController customController;
  final int? volume;
  final ValueChanged<DeveloperMode> onMode;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustomChanged;
  final ValueChanged<int?> onVolume;

  /// cream or liquid, sets the pour hints when weighing
  final ProductForm form;
  final ValueChanged<ProductForm> onForm;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return SectionCard(
      title: 'Developer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratio by weight (dye : developer)', style: muted),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('No developer'),
                selected: mode == DeveloperMode.none,
                onSelected: (_) => onMode(DeveloperMode.none),
              ),
              for (final r in DeveloperRatio.presets)
                ChoiceChip(
                  label: Text(r.label),
                  selected:
                      mode == DeveloperMode.preset &&
                      presetRatio == r.hundredths,
                  onSelected: (_) => onPreset(r.hundredths),
                ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: mode == DeveloperMode.custom,
                onSelected: (_) => onMode(DeveloperMode.custom),
              ),
            ],
          ),
          if (mode == DeveloperMode.custom) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: TextField(
                controller: customController,
                onChanged: (_) => onCustomChanged(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Developer parts',
                  prefixText: '1 : ',
                  isDense: true,
                  helperText: 'Per 1 part dye',
                ),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (mode != DeveloperMode.none && mode != DeveloperMode.unset) ...[
            const SizedBox(height: 16),
            Text('Strength (for your records)', style: muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Not set'),
                  selected: volume == null,
                  onSelected: (_) => onVolume(null),
                ),
                for (final v in developerVolumes)
                  ChoiceChip(
                    label: Text('$v vol'),
                    selected: volume == v,
                    onSelected: (_) => onVolume(v),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Form', style: muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ProductForm.developerForms)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: form == f,
                    onSelected: (_) => onForm(f),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Use the ratio the dye maker gives for these products. These are '
            'weights: if the instructions give a ratio by volume, 1 mL isn\'t '
            'always 1 g.',
            style: muted,
          ),
        ],
      ),
    );
  }
}
