import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/core/bluetooth/scale_device.dart';

/// the scale everything reads weight from. null until one is connected.
/// TODO: phase 4 swaps this for a notifier that owns the simulator and the
/// ble adapters
final activeScaleProvider = Provider<ScaleDevice?>((ref) => null);
