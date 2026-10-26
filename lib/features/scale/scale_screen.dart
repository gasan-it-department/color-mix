import 'package:flutter/material.dart';

import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';

class ScaleScreen extends StatelessWidget {
  const ScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Scale',
      body: EmptyState(
        icon: Icons.bluetooth_disabled,
        title: 'No scale connected',
        message:
            'Bluetooth scanning and the simulated practice scale '
            'aren\'t in this build yet.',
      ),
    );
  }
}
