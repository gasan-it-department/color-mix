import 'dart:math' as math;

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/core/widgets/section_card.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';

/// wheel (hue ring + saturation/brightness square), three sliders for fine
/// moves, hex in, rgb out. hsv lives here so the hue survives greys, every
/// change goes straight to the target so the preview is live.
class CustomPicker extends ConsumerStatefulWidget {
  const CustomPicker({super.key});

  @override
  ConsumerState<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends ConsumerState<CustomPicker> {
  late HSVColor _hsv;
  final _hex = TextEditingController();
  final _hexFocus = FocusNode();
  String? _hexError;

  /// tells the wheel to take our colour, only after a change it didn't make
  bool _syncWheel = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(colorTargetProvider);
    final start = current?.rgb ?? 0xB76E79;
    _hsv = HSVColor.fromColor(colorFromRgb(start));
    _hex.text = _digits(start);
    // nothing picked yet: what the wheel shows becomes the target, so the
    // preview and the picker agree. a picked shade stays until it's edited
    if (current == null) {
      Future.microtask(() {
        if (mounted) ref.read(colorTargetProvider.notifier).pickCustom(start);
      });
    }
    _hexFocus.addListener(() {
      if (!_hexFocus.hasFocus) _commitHex();
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  int get _rgb => rgbFromColor(_hsv.toColor());

  static String _digits(int rgb) => hexFromRgb(rgb).substring(1);

  void _apply(HSVColor next, {bool fromWheel = false, bool fromHex = false}) {
    setState(() {
      _hsv = next;
      _syncWheel = !fromWheel;
      if (!fromHex) {
        _hex.text = _digits(_rgb);
        _hexError = null;
      }
    });
    ref.read(colorTargetProvider.notifier).pickCustom(_rgb);
  }

  void _onWheel(Color color) {
    var next = HSVColor.fromColor(color);
    // greys and black have no hue, keep ours so the hue slider doesn't jump
    if (next.saturation == 0 || next.value == 0) next = next.withHue(_hsv.hue);
    _apply(next, fromWheel: true);
  }

  void _onHexChanged(String text) {
    if (text.replaceAll('#', '').length != 6) return;
    final rgb = rgbFromHex(text);
    if (rgb == null) return;
    _hexError = null;
    _apply(HSVColor.fromColor(colorFromRgb(rgb)), fromHex: true);
  }

  void _commitHex() {
    final rgb = rgbFromHex(_hex.text);
    if (rgb == null) {
      setState(() => _hexError = 'Use 6 characters, like B76E79');
      return;
    }
    if (rgb == _rgb) {
      // tidy shorthand or lowercase back to the full form
      setState(() {
        _hex.text = _digits(rgb);
        _hexError = null;
      });
      return;
    }
    _apply(HSVColor.fromColor(colorFromRgb(rgb)));
  }

  @override
  Widget build(BuildContext context) {
    final sync = _syncWheel;
    if (sync) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncWheel = false);
    }

    final color = _hsv.toColor();
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 560;
          final wheelSize = wide ? 240.0 : math.min(c.maxWidth, 280.0);

          final wheel = SizedBox.square(
            dimension: wheelSize,
            child: ColorWheelPicker(
              color: color,
              onChanged: _onWheel,
              onWheel: (_) {},
              wheelWidth: 20,
              wheelSquarePadding: 8,
              wheelSquareBorderRadius: 10,
              borderColor: scheme.outlineVariant,
              hasBorder: true,
              shouldUpdate: sync,
            ),
          );

          final controls = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HsvSlider(
                label: 'Hue',
                valueText: '${_hsv.hue.round()}°',
                value: _hsv.hue,
                max: 360,
                colors: [
                  for (var h = 0; h <= 360; h += 60)
                    HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                ],
                onChanged: (v) => _apply(_hsv.withHue(v)),
              ),
              _HsvSlider(
                label: 'Saturation',
                valueText: '${(_hsv.saturation * 100).round()}%',
                value: _hsv.saturation,
                max: 1,
                colors: [
                  _hsv
                      .withSaturation(0)
                      .withValue(math.max(_hsv.value, 0.35))
                      .toColor(),
                  _hsv
                      .withSaturation(1)
                      .withValue(math.max(_hsv.value, 0.35))
                      .toColor(),
                ],
                onChanged: (v) => _apply(_hsv.withSaturation(v)),
              ),
              _HsvSlider(
                label: 'Brightness',
                valueText: '${(_hsv.value * 100).round()}%',
                value: _hsv.value,
                max: 1,
                colors: [Colors.black, _hsv.withValue(1).toColor()],
                onChanged: (v) => _apply(_hsv.withValue(v)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 156,
                    child: TextField(
                      controller: _hex,
                      focusNode: _hexFocus,
                      onChanged: _onHexChanged,
                      onSubmitted: (_) => _commitHex(),
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9a-fA-F#]'),
                        ),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      decoration: InputDecoration(
                        labelText: 'HEX',
                        prefixText: '#',
                        isDense: true,
                        errorText: _hexError,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                  _RgbReadout(rgb: _rgb),
                ],
              ),
              const SizedBox(height: 14),
              _ColorName(name: ColorTools.nameThatColor(color)),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wheel,
                const SizedBox(width: 24),
                Expanded(child: controls),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: wheel),
              const SizedBox(height: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

// ── sliders ────────────────────────────────────────────────

class _HsvSlider extends StatelessWidget {
  const _HsvSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.max,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double max;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              valueText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            trackShape: _GradientTrack(colors, scheme.outlineVariant),
            thumbShape: _RingThumb(scheme.onSurface),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            overlayColor: scheme.onSurface.withValues(alpha: 0.08),
          ),
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            onChanged: onChanged,
            semanticFormatterCallback: (_) => valueText,
          ),
        ),
      ],
    );
  }
}

class _GradientTrack extends SliderTrackShape with BaseSliderTrackShape {
  const _GradientTrack(this.colors, this.border);

  final List<Color> colors;
  final Color border;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    context.canvas
      ..drawRRect(
        rrect,
        Paint()..shader = LinearGradient(colors: colors).createShader(rect),
      )
      ..drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = border,
      );
  }
}

/// white dot with a dark ring, readable on any part of the gradient
class _RingThumb extends SliderComponentShape {
  const _RingThumb(this.ring);

  final Color ring;

  static const _radius = 10.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas
      ..drawCircle(center, _radius, Paint()..color = Colors.white)
      ..drawCircle(
        center,
        _radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring,
      );
  }
}

// ── readouts ───────────────────────────────────────────────

class _RgbReadout extends StatelessWidget {
  const _RgbReadout({required this.rgb});

  final int rgb;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        _Channel('R', (rgb >> 16) & 0xFF),
        _Channel('G', (rgb >> 8) & 0xFF),
        _Channel('B', rgb & 0xFF),
      ],
    );
  }
}

class _Channel extends StatelessWidget {
  const _Channel(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            TextSpan(
              text: '$value',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ColorName extends StatelessWidget {
  const _ColorName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.sell_outlined, size: 18, color: muted),
        const SizedBox(width: 8),
        Text(
          'Looks like ',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
