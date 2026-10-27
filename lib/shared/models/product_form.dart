import 'dart:math';

/// how a product comes out of its tube, bottle or tub. everything is still
/// weighed in grams, the form only changes when the weighing screen says to
/// slow down and what it suggests while pouring. no volume conversion: 1 mL
/// of a liquid isn't 1 g, and guessing densities would be worse than asking
/// for grams
enum ProductForm {
  /// the default, what most tube colors and many developers are. a gram,
  /// or a tenth of the step, before the target: what weighing always used
  cream(
    label: 'Cream',
    approachMinMg: 1000,
    approachPercent: 10,
    pourHint: 'Squeeze it in steadily.',
    slowHint: 'Small squeezes now, the last bit clings to the tube.',
  ),

  /// runs fast and keeps dripping after you stop, so slow down sooner
  liquid(
    label: 'Liquid',
    approachMinMg: 2000,
    approachPercent: 15,
    pourHint: 'Pour slowly, it runs fast.',
    slowHint: 'A few drops at a time now, it keeps dripping after you stop.',
  ),

  /// goes in by the spoonful and a spoonful can be several grams, so slow
  /// down a little sooner than a cream. settles straight away
  powder(
    label: 'Powder',
    approachMinMg: 1500,
    approachPercent: 10,
    pourHint: 'Spoon it in.',
    slowHint: 'Small pinches or the tip of the spoon now.',
  );

  const ProductForm({
    required this.label,
    required this.approachMinMg,
    required this.approachPercent,
    required this.pourHint,
    required this.slowHint,
  });

  final String label;

  /// the slow-down band before the target is the bigger of these two
  final int approachMinMg;
  final int approachPercent;

  /// shown under "Keep pouring"
  final String pourHint;

  /// shown under "Almost there, slow down"
  final String slowHint;

  /// how far before the target the screen turns amber, for a step of
  /// [targetMg]
  int approachMg(int targetMg) =>
      max(approachMinMg, targetMg * approachPercent ~/ 100);

  /// developer comes as a cream or a liquid, there's no powder developer
  static const developerForms = [ProductForm.cream, ProductForm.liquid];
}
