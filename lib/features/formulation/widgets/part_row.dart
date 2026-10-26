import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

/// one color: name, percentage, worked-out grams. two lines on phones
class PartRow extends StatelessWidget {
  const PartRow({
    super.key,
    required this.displayRgb,
    required this.nameController,
    required this.percentController,
    required this.onChanged,
    this.weightDg,
    this.nameError,
    this.percentError,
    this.onRemove,
  });

  final int displayRgb;
  final TextEditingController nameController;
  final TextEditingController percentController;
  final VoidCallback onChanged;
  final int? weightDg;
  final String? nameError;
  final String? percentError;

  /// null when it's the only color left
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = TextField(
      controller: nameController,
      onChanged: (_) => onChanged(),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Name or product',
        isDense: true,
        errorText: nameError,
      ),
    );

    final percent = TextField(
      controller: percentController,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      textAlign: TextAlign.end,
      decoration: InputDecoration(
        labelText: 'Share',
        suffixText: '%',
        isDense: true,
        errorText: percentError,
        errorMaxLines: 3,
      ),
    );

    final weight = SizedBox(
      width: 72,
      child: Text(
        weightDg == null ? '—' : formatDecigrams(weightDg!),
        textAlign: TextAlign.end,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    final remove = IconButton(
      tooltip: 'Remove color',
      onPressed: onRemove,
      icon: const Icon(Icons.close, size: 20),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 480) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ColorSwatchDot(rgb: displayRgb, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: name),
              const SizedBox(width: 12),
              SizedBox(width: 112, child: percent),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(top: 10), child: weight),
              remove,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ColorSwatchDot(rgb: displayRgb, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: name),
                remove,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 36),
                SizedBox(width: 120, child: percent),
                const Spacer(),
                Padding(padding: const EdgeInsets.only(top: 10), child: weight),
                const SizedBox(width: 48),
              ],
            ),
          ],
        );
      },
    );
  }
}
