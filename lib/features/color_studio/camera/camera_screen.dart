import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/utils/color_utils.dart';
import 'package:colormix_studio/features/color_studio/camera/camera_reading.dart';
import 'package:colormix_studio/features/color_studio/camera/color_camera.dart';
import 'package:colormix_studio/features/color_studio/color_target.dart';
import 'package:colormix_studio/features/settings/settings_providers.dart';
import 'package:colormix_studio/shared/data/demo_catalog.dart';

/// hair on a card under the camera, one still, the card-corrected color.
/// "use this color" makes it the custom target and goes back
class CameraColorScreen extends ConsumerStatefulWidget {
  const CameraColorScreen({super.key});

  @override
  ConsumerState<CameraColorScreen> createState() => _CameraColorScreenState();
}

class _CameraColorScreenState extends ConsumerState<CameraColorScreen>
    with WidgetsBindingObserver {
  ColorCamera? _camera;
  String? _cameraError;
  bool _opening = false;
  bool _reading = false;
  ColorReading? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_camera?.close());
    super.dispose();
  }

  // the camera is let go while the app is in the background, other apps
  // may want it
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final c = _camera;
      if (c == null) return;
      setState(() => _camera = null);
      unawaited(c.close());
    } else if (state == AppLifecycleState.resumed &&
        _camera == null &&
        !_opening) {
      _open();
    }
  }

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _cameraError = null;
    });
    final camera = ref.read(colorCameraFactoryProvider)();
    try {
      await camera.open();
    } on CameraUnavailable catch (e) {
      if (mounted) {
        setState(() {
          _opening = false;
          _cameraError = e.message;
        });
      }
      return;
    }
    if (!mounted) {
      await camera.close();
      return;
    }
    setState(() {
      _opening = false;
      _camera = camera;
    });
  }

  Future<void> _read() async {
    final camera = _camera;
    if (camera == null || _reading) return;
    setState(() => _reading = true);
    ColorReading result;
    try {
      final photo = await camera.capture();
      result = readHairColor(photo, ref.read(settingsProvider).cameraCard);
    } on Object catch (e) {
      result = ColorReading(problem: 'The photo didn\'t come through: $e');
    }
    if (!mounted) return;
    setState(() {
      _reading = false;
      _result = result;
    });
  }

  void _use() {
    final result = _result!;
    ref.read(colorTargetProvider.notifier).pickCustom(result.rgb!);
    ref.read(lastCameraReadingProvider.notifier).set(result);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;

    final Widget view;
    if (camera != null) {
      view = camera.preview(overlay: const _Guide());
    } else if (_cameraError != null) {
      view = _CameraMessage(message: _cameraError!, onRetry: _open);
    } else {
      view = const CircularProgressIndicator(color: Colors.white);
    }

    final controls = _Controls(
      ready: camera != null,
      reading: _reading,
      result: _result,
      onRead: _read,
      onAgain: () => setState(() => _result = null),
      onUse: _use,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Read a color')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final previewArea = ColoredBox(
              color: Colors.black,
              child: Center(child: view),
            );
            if (c.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: previewArea),
                  SizedBox(
                    width: 360,
                    child: SingleChildScrollView(child: controls),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: previewArea),
                // the result can run long on a small phone, the preview
                // keeps at least half
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: c.maxHeight * 0.5),
                  child: SingleChildScrollView(child: controls),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── guide ──────────────────────────────────────────────────

/// the hair square and the four card squares, from [ReadingLayout]
class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _GuidePainter(), size: Size.infinite),
    );
  }
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final centre = size.center(Offset.zero);

    Rect square(Offset c, double fraction) => Rect.fromCenter(
      center: c,
      width: side * fraction,
      height: side * fraction,
    );

    final rects = [
      square(centre, ReadingLayout.hair),
      for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)])
        square(
          centre + Offset(dx * side, dy * side) * ReadingLayout.cardOffset,
          ReadingLayout.card,
        ),
    ];

    // dark under light so the lines show on white paper and dark hair
    final under = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.black.withValues(alpha: 0.45);
    final over = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    for (final r in rects) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas
        ..drawRRect(rr, under)
        ..drawRRect(rr, over);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) => false;
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ── controls ───────────────────────────────────────────────

class _Controls extends ConsumerWidget {
  const _Controls({
    required this.ready,
    required this.reading,
    required this.result,
    required this.onRead,
    required this.onAgain,
    required this.onUse,
  });

  final bool ready;
  final bool reading;
  final ColorReading? result;
  final VoidCallback onRead;
  final VoidCallback onAgain;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final r = result;

    if (r != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: r.ok
            ? _Result(reading: r, onAgain: onAgain, onUse: onUse)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Note(text: r.problem!, color: context.status.danger),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAgain,
                    child: const Text('Read again'),
                  ),
                ],
              ),
      );
    }

    final card = ref.watch(settingsProvider.select((s) => s.cameraCard));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hair in the middle square, card in the four small ones. Even '
            'light, no flash, 15 to 20 cm away.',
            style: muted,
          ),
          const SizedBox(height: 12),
          Text('The hair is on', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<ReferenceCard>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: [
              for (final c in ReferenceCard.values)
                ButtonSegment(value: c, label: Text(c.label)),
            ],
            selected: {card},
            onSelectionChanged: (s) => unawaited(
              ref.read(settingsProvider.notifier).setCameraCard(s.first),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: ready && !reading ? onRead : null,
            icon: reading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(reading ? 'Reading…' : 'Read color'),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.reading,
    required this.onAgain,
    required this.onUse,
  });

  final ColorReading reading;
  final VoidCallback onAgain;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final rgb = reading.rgb!;
    final nearest = nearestDemoShade(rgb);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorFromRgb(rgb),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hexFromRgb(rgb),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Closest demo shade: ${nearest.shade.name} · '
                    '${closenessLabel(nearest.deltaE)}',
                    style: muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (reading.cameraRgb != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colorFromRgb(reading.cameraRgb!),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Straight from the camera ${hexFromRgb(reading.cameraRgb!)}, '
                  'before the card\'s correction',
                  style: muted,
                ),
              ),
            ],
          ),
        ],
        for (final w in reading.warnings) ...[
          const SizedBox(height: 10),
          _Note(text: w, color: context.status.warning),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onAgain,
                child: const Text('Read again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onUse,
                child: const Text('Use this color'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
