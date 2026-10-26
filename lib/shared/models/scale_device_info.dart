enum ScaleConnectionType { bluetoothLe, simulated }

enum ScaleAdapterType {
  /// our esp32 + hx711 scale
  esp32Custom,

  /// bluetooth weight scale service 0x181D, experimental
  standardWeightScale,
  simulated,
  unknown,
}

class ScaleDeviceInfo {
  const ScaleDeviceInfo({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.adapterType,
    required this.isSupported,
  });

  final String id;
  final String name;
  final ScaleConnectionType connectionType;
  final ScaleAdapterType adapterType;
  final bool isSupported;
}
