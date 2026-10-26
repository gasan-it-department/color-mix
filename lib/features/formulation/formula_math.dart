// pure formula maths, no flutter, no db, no bluetooth.
// weights in decigrams (0.1 g), percentages in hundredths (10000 = 100%),
// developer ratio in hundredths of a part (150 = 1:1.5).

import 'package:colormix_studio/core/utils/weight_format.dart';
import 'package:colormix_studio/shared/models/color_formula.dart';

const maxParts = 3;
const fullPercent = 10000;

/// the 1 kg load cell
const scaleCapacityDg = 10000;

/// over this the bowl may not fit under the 1 kg limit
const bowlRoomWarningDg = 7000;

const minRatioHundredths = 10;
const maxRatioHundredths = 500;

// ── parsing ────────────────────────────────────────────────

/// '60' -> 600, '62.5' -> 625, '60.' -> 600 (still typing). null if it isn't
/// a plain number with at most one decimal
int? parseDecigrams(String text) => _parseFixed(text, 1);

/// '50' -> 5000, '33.3' -> 3330, '33.33' -> 3333
int? parsePercentHundredths(String text) => _parseFixed(text, 2);

/// '1.5' -> 150
int? parseRatioHundredths(String text) => _parseFixed(text, 2);

int? _parseFixed(String text, int decimals) {
  final t = text.trim().replaceAll(',', '.');
  final m = RegExp(r'^(\d{1,6})(?:\.(\d*))?$').firstMatch(t);
  if (m == null) return null;
  final frac = m.group(2) ?? '';
  if (frac.length > decimals) return null;

  var scale = 1;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  final fracValue = frac.isEmpty ? 0 : int.parse(frac.padRight(decimals, '0'));
  return int.parse(m.group(1)!) * scale + fracValue;
}

/// 600 -> '60', 625 -> '62.5'. for putting numbers back in text fields
String decigramsText(int dg) =>
    dg % 10 == 0 ? '${dg ~/ 10}' : formatDecigrams(dg, unit: false);

/// 5000 -> '50', 3330 -> '33.3', 3333 -> '33.33'
String percentText(int hundredths) =>
    formatPercentHundredths(hundredths).replaceAll('%', '');

String ratioText(int hundredths) =>
    DeveloperRatio(hundredths).label.substring(2);

// ── splitting ──────────────────────────────────────────────

/// splits [total] in proportion to [weights] so the parts add up to exactly
/// [total]: everyone gets the floor of their share, the leftover units go to
/// the biggest remainders, ties to the earlier part.
List<int> largestRemainder(int total, List<int> weights) {
  final sumW = weights.fold(0, (a, b) => a + b);
  if (sumW <= 0) throw ArgumentError('weights must add up to more than 0');
  if (total < 0) throw ArgumentError('total must not be negative');

  final parts = <int>[];
  final remainders = <int>[];
  for (final w in weights) {
    final exact = total * w;
    parts.add(exact ~/ sumW);
    remainders.add(exact % sumW);
  }

  var left = total - parts.fold(0, (a, b) => a + b);
  final order = List.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = remainders[b].compareTo(remainders[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (final i in order) {
    if (left == 0) break;
    parts[i]++;
    left--;
  }
  return parts;
}

/// dye weight per color. percentages must make exactly 100%
List<int> colorWeights(int dyeDg, List<int> percentHundredths) {
  final sum = percentHundredths.fold(0, (a, b) => a + b);
  if (sum != fullPercent) {
    throw ArgumentError('percentages add up to $sum, not $fullPercent');
  }
  return largestRemainder(dyeDg, percentHundredths);
}

/// rounded half up to the nearest 0.1 g
int developerWeight(int dyeDg, int ratioHundredths) =>
    (dyeDg * ratioHundredths + 50) ~/ 100;

/// 1 color 100%, 2 colors 50/50, 3 colors 33.34/33.33/33.33
List<int> evenSplit(int count) =>
    largestRemainder(fullPercent, List.filled(count, 1));

/// same formula, new dye amount. percentages and ratio stay as they are
ColorFormula rescaleFormula(ColorFormula f, int newDyeDg, {DateTime? now}) {
  final weights = colorWeights(newDyeDg, [
    for (final i in f.ingredients) i.percentHundredths,
  ]);
  final developerDg = f.developerRatio == null
      ? 0
      : developerWeight(newDyeDg, f.developerRatio!.hundredths);

  return f.copyWith(
    ingredients: [
      for (final (i, ing) in f.ingredients.indexed)
        ing.copyWith(requiredDg: weights[i]),
    ],
    totalDyeDg: newDyeDg,
    developerDg: developerDg,
    totalMixtureDg: newDyeDg + developerDg,
    updatedAt: now ?? f.updatedAt,
  );
}

// ── checking a draft ───────────────────────────────────────

enum DeveloperMode {
  /// nothing picked yet, the stylist has to choose
  unset,
  none,
  preset,
  custom,
}

class PartInput {
  const PartInput({required this.name, required this.percentText});

  final String name;
  final String percentText;
}

class FormulaInputs {
  const FormulaInputs({
    required this.name,
    required this.dyeText,
    required this.parts,
    required this.developerMode,
    this.presetRatioHundredths,
    this.customRatioText = '',
    this.notes = '',
  });

  final String name;
  final String dyeText;
  final List<PartInput> parts;
  final DeveloperMode developerMode;
  final int? presetRatioHundredths;
  final String customRatioText;
  final String notes;
}

enum IssueField {
  name,
  dye,
  partName,
  partPercent,
  total,
  developer,
  mixture,
  notes,
}

class FormulaIssue {
  const FormulaIssue(
    this.field,
    this.message, {
    this.part,
    this.blocking = true,
  });

  final IssueField field;
  final String message;

  /// which color row, for part issues
  final int? part;

  /// false = a warning, saving still works
  final bool blocking;
}

class FormulaResult {
  const FormulaResult({
    required this.issues,
    required this.percents,
    required this.percentSum,
    this.dyeDg,
    this.weights,
    this.ratioHundredths,
    this.developerDg,
    this.mixtureDg,
  });

  final List<FormulaIssue> issues;

  /// parsed per color, null where the text isn't a number
  final List<int?> percents;
  final int percentSum;
  final int? dyeDg;

  /// per color, only when everything needed is valid
  final List<int>? weights;
  final int? ratioHundredths;
  final int? developerDg;
  final int? mixtureDg;

  bool get canSave => !issues.any((i) => i.blocking);

  /// first blocking message for a field (and color row)
  String? errorFor(IssueField field, {int? part}) {
    for (final i in issues) {
      if (i.field == field && i.part == part && i.blocking) return i.message;
    }
    return null;
  }
}

/// everything the editor shows, worked out from what's typed
FormulaResult calculateFormula(FormulaInputs input) {
  final issues = <FormulaIssue>[];

  // name
  final name = input.name.trim();
  if (name.isEmpty) {
    issues.add(const FormulaIssue(IssueField.name, 'Give the formula a name.'));
  } else if (name.length > 60) {
    issues.add(
      const FormulaIssue(IssueField.name, 'Keep the name under 60 characters.'),
    );
  }

  // dye amount
  final dyeDg = parseDecigrams(input.dyeText);
  if (dyeDg == null) {
    issues.add(
      const FormulaIssue(
        IssueField.dye,
        'Enter the dye amount in grams, like 60 or 62.5.',
      ),
    );
  } else if (dyeDg == 0) {
    issues.add(
      const FormulaIssue(
        IssueField.dye,
        'The dye amount has to be more than 0 g.',
      ),
    );
  } else if (dyeDg > scaleCapacityDg) {
    issues.add(
      const FormulaIssue(
        IssueField.dye,
        'That\'s more than the 1 kg scale can weigh.',
      ),
    );
  }
  final dyeOk = dyeDg != null && dyeDg > 0 && dyeDg <= scaleCapacityDg;

  // colors
  if (input.parts.isEmpty) {
    issues.add(const FormulaIssue(IssueField.total, 'Add at least one color.'));
  }
  final percents = <int?>[];
  var partsOk = input.parts.isNotEmpty && input.parts.length <= maxParts;
  for (final (i, p) in input.parts.indexed) {
    if (p.name.trim().isEmpty) {
      issues.add(
        FormulaIssue(IssueField.partName, 'Name this color.', part: i),
      );
    }
    final pct = parsePercentHundredths(p.percentText);
    percents.add(pct);
    if (pct == null) {
      partsOk = false;
      issues.add(
        FormulaIssue(
          IssueField.partPercent,
          'Enter a percentage, like 50 or 33.3.',
          part: i,
        ),
      );
    } else if (pct == 0) {
      partsOk = false;
      issues.add(
        FormulaIssue(
          IssueField.partPercent,
          'Use more than 0%, or remove this color.',
          part: i,
        ),
      );
    } else if (pct > fullPercent) {
      partsOk = false;
      issues.add(
        FormulaIssue(
          IssueField.partPercent,
          'Can\'t be more than 100%.',
          part: i,
        ),
      );
    }
  }

  final percentSum = percents.fold(0, (a, b) => a + (b ?? 0));
  if (partsOk && percentSum != fullPercent) {
    partsOk = false;
    final sum = formatPercentHundredths(percentSum);
    issues.add(
      FormulaIssue(
        IssueField.total,
        percentSum < fullPercent
            ? 'The colors add up to $sum. They need to make exactly 100%.'
            : 'The colors add up to $sum, over 100%. They need to make '
                  'exactly 100%.',
      ),
    );
  }

  List<int>? weights;
  if (partsOk && dyeOk) {
    weights = colorWeights(dyeDg, [for (final p in percents) p!]);
    for (final (i, w) in weights.indexed) {
      if (w == 0) {
        final label = input.parts[i].name.trim().isEmpty
            ? 'This color'
            : input.parts[i].name.trim();
        issues.add(
          FormulaIssue(
            IssueField.partPercent,
            '$label works out to 0.0 g. Raise its percentage or the dye amount.',
            part: i,
          ),
        );
      }
    }
  }

  // developer
  int? ratio;
  switch (input.developerMode) {
    case DeveloperMode.unset:
      issues.add(
        const FormulaIssue(
          IssueField.developer,
          'Choose the developer ratio from the dye\'s instructions, or No '
          'developer.',
        ),
      );
    case DeveloperMode.none:
      ratio = null;
    case DeveloperMode.preset:
      ratio = input.presetRatioHundredths;
      if (ratio == null) {
        issues.add(
          const FormulaIssue(IssueField.developer, 'Choose a developer ratio.'),
        );
      }
    case DeveloperMode.custom:
      final r = parseRatioHundredths(input.customRatioText);
      if (r == null) {
        issues.add(
          const FormulaIssue(
            IssueField.developer,
            'Enter how many parts developer go with 1 part dye, like 1.5.',
          ),
        );
      } else if (r < minRatioHundredths || r > maxRatioHundredths) {
        issues.add(
          const FormulaIssue(
            IssueField.developer,
            'Use a ratio between 1:0.1 and 1:5.',
          ),
        );
      } else {
        ratio = r;
      }
  }
  final developerKnown =
      input.developerMode == DeveloperMode.none || ratio != null;

  int? developerDg;
  int? mixtureDg;
  if (dyeOk && developerKnown) {
    developerDg = ratio == null ? 0 : developerWeight(dyeDg, ratio);
    mixtureDg = dyeDg + developerDg;
    final mixture = formatDecigrams(mixtureDg);
    if (mixtureDg > scaleCapacityDg) {
      issues.add(
        FormulaIssue(
          IssueField.mixture,
          'The mixture would be $mixture, more than the 1 kg scale can weigh. '
          'Use less dye.',
        ),
      );
    } else if (mixtureDg > bowlRoomWarningDg) {
      issues.add(
        FormulaIssue(
          IssueField.mixture,
          'The mixture is $mixture. That leaves little room for the bowl on '
          'a 1 kg scale.',
          blocking: false,
        ),
      );
    }
  }

  if (input.notes.length > 500) {
    issues.add(
      const FormulaIssue(IssueField.notes, 'Keep notes under 500 characters.'),
    );
  }

  return FormulaResult(
    issues: issues,
    percents: percents,
    percentSum: percentSum,
    dyeDg: dyeOk ? dyeDg : null,
    weights: weights,
    ratioHundredths: ratio,
    developerDg: developerDg,
    mixtureDg: mixtureDg,
  );
}
