import 'package:flutter/material.dart';

import 'package:colormix_studio/app/theme.dart';
import 'package:colormix_studio/core/bluetooth/scale_device.dart';

String connectionLabel(ScaleConnectionState s) => switch (s) {
  ScaleConnectionState.disconnected => 'Not connected',
  ScaleConnectionState.connecting => 'Connecting…',
  ScaleConnectionState.connectedSupported => 'Connected',
  ScaleConnectionState.connectedUnsupported => 'Connected, can\'t read weight',
  ScaleConnectionState.failed => 'Couldn\'t connect',
};

/// dot + 'Simulated scale · Connected'
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.name, required this.state});

  final String name;
  final ScaleConnectionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final dot = switch (state) {
      ScaleConnectionState.connectedSupported => status.success,
      ScaleConnectionState.connecting => status.warning,
      ScaleConnectionState.disconnected => theme.colorScheme.outline,
      _ => status.danger,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$name · ${connectionLabel(state)}',
            maxLines: 1,
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
