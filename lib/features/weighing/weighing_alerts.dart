import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colormix_studio/features/settings/settings_providers.dart';

/// sound and buzz for the moments that matter while pouring. tests swap in
/// a recorder
abstract interface class WeighingAlerts {
  void approaching();
  void reached();
  void over();
  void disconnected();
}

final weighingAlertsProvider = Provider<WeighingAlerts>(
  (ref) => SystemAlerts(
    soundsOn: ref.watch(settingsProvider.select((s) => s.soundsOn)),
  ),
);

class SystemAlerts implements WeighingAlerts {
  const SystemAlerts({required this.soundsOn});

  final bool soundsOn;

  @override
  void approaching() => _buzz(HapticFeedback.selectionClick);

  @override
  void reached() {
    _buzz(HapticFeedback.mediumImpact);
    _sound(SystemSoundType.click);
  }

  @override
  void over() {
    _buzz(HapticFeedback.heavyImpact);
    _sound(SystemSoundType.alert);
  }

  @override
  void disconnected() {
    _buzz(HapticFeedback.heavyImpact);
    _sound(SystemSoundType.alert);
  }

  void _sound(SystemSoundType type) {
    if (!soundsOn) return;
    // not every platform has system sounds, the colours still say it
    unawaited(SystemSound.play(type).catchError((Object _) {}));
  }

  void _buzz(Future<void> Function() haptic) {
    unawaited(haptic().catchError((Object _) {}));
  }
}
