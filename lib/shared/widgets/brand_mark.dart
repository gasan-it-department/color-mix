import 'package:flutter/material.dart';

import 'package:colormix_studio/core/constants/app_info.dart';

/// three overlapping drops for colour a, b and c
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = size * 0.58;
    final colors = [scheme.secondary, const Color(0xFFC9A27E), scheme.primary];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: [0.0, size - dot, (size - dot) / 2][i],
              top: [size - dot, size - dot, 0.0][i],
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i].withValues(alpha: 0.9),
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            AppInfo.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1),
          ),
        ),
      ],
    );
  }
}
