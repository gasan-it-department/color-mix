import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colormix_studio/shared/models/product_form.dart';
import 'package:colormix_studio/shared/widgets/color_swatch_dot.dart';

/// one color: name, percentage, worked-out grams, and whether it's a cream,
/// liquid or powder. two lines on phones
class PartRow extends StatelessWidget {
  const PartRow({
    super.key,
    required this.displayRgb,
    required this.nameController,
    required this.percentController,
    required this.onChanged,
    required this.form,
    required this.onForm,
    this.amount = '—',
    this.nameError,
    this.percentError,
    this.onRemove,
  });

  final int displayRgb;
  final TextEditingController nameController;
  final TextEditingController percentController;
  final VoidCallback onChanged;
  final ProductForm form;
  final ValueChanged<ProductForm> onForm;

  /// worked out, already in the formula's unit: '30.0 g', '1.06 oz'
  final String amount;
  final String? nameError;
  final String? percentError;

  /// null when it's the only color left
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // inside the name field: it's a property of the product, and phones have
    // no room for another field on the row
    final formMenu = PopupMenuButton<ProductForm>(
      tooltip: 'Product form',
      initialValue: form,
      onSelected: onForm,
      itemBuilder: (_) => [
        for (final f in ProductForm.values)
          PopupMenuItem(value: f, child: Text(f.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              form.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    final name = TextField(
      controller: nameController,
      onChanged: (_) => onChanged(),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Name or product',
        isDense: true,
        errorText: nameError,
        suffixIcon: formMenu,
        suffixIconConstraints: const BoxConstraints(minHeight: 32),
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

    final weight = Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        amount,
        textAlign: TextAlign.end,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
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
                Expanded(child: percent),
                const SizedBox(width: 12),
                Padding(padding: const EdgeInsets.only(top: 10), child: weight),
                const SizedBox(width: 8),
              ],
            ),
          ],
        );
      },
    );
  }
}
