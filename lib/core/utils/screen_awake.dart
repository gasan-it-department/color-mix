import 'package:wakelock_plus/wakelock_plus.dart';

/// keeps the screen on while weighing. hands are busy, the phone mustn't
/// lock mid-pour. quietly does nothing where it isn't supported
Future<void> keepScreenOn(bool on) async {
  try {
    if (on) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  } catch (_) {
    // not available here, weighing still works
  }
}
