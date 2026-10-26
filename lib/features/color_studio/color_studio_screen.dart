import 'package:flutter/material.dart';

import 'package:colormix_studio/core/widgets/app_page.dart';
import 'package:colormix_studio/core/widgets/empty_state.dart';

class ColorStudioScreen extends StatelessWidget {
  const ColorStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Color Studio',
      body: EmptyState(
        icon: Icons.palette_outlined,
        title: 'Choose a target color',
        message:
            'The color picker and the demo shade palette aren\'t in '
            'this build yet.',
      ),
    );
  }
}
