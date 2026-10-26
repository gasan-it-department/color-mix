import 'package:flutter/material.dart';

// interface colours only, never dye colours.
// no shadows or elevation anywhere: hierarchy comes from 1px borders and
// background tone steps.

abstract final class _Light {
  static const canvas = Color(0xFFFAF8F5); // warm off-white
  static const card = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFF3EEE8); // warm beige step
  static const beige = Color(0xFFEDE4D9);
  static const line = Color(0xFFE6DFD7);
  static const lineStrong = Color(0xFFCFC6BC);
  static const ink = Color(0xFF2B2A29); // deep charcoal
  static const ink2 = Color(0xFF6B6560);
  static const rose = Color(0xFF9A5560); // muted rose, dark enough for text
  static const roseWash = Color(0xFFF5E6E8);
  static const onRoseWash = Color(0xFF6E3540);
  static const green = Color(0xFF2F7350);
  static const greenWash = Color(0xFFE2F0E7);
  static const amber = Color(0xFF8F5409);
  static const amberWash = Color(0xFFFBEED8);
  static const red = Color(0xFFB0302A);
  static const redWash = Color(0xFFF9E1DF);
}

abstract final class _Dark {
  static const canvas = Color(0xFF1C1B1A);
  static const card = Color(0xFF242220);
  static const sunken = Color(0xFF2C2927);
  static const beige = Color(0xFF3A3430);
  static const line = Color(0xFF37332F);
  static const lineStrong = Color(0xFF4D4742);
  static const ink = Color(0xFFEDE8E3);
  static const ink2 = Color(0xFFA9A19A);
  static const rose = Color(0xFFE2A6AF);
  static const roseWash = Color(0xFF3B2A2E);
  static const onRoseWash = Color(0xFFF3D3D8);
  static const green = Color(0xFF86C9A2);
  static const greenWash = Color(0xFF1F3329);
  static const amber = Color(0xFFE5B567);
  static const amberWash = Color(0xFF3A2E1A);
  static const red = Color(0xFFF0928B);
  static const redWash = Color(0xFF3F2220);
}

/// weighing states: neutral while pouring, amber close, green on target,
/// red over
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successWash,
    required this.warning,
    required this.warningWash,
    required this.danger,
    required this.dangerWash,
  });

  final Color success;
  final Color successWash;
  final Color warning;
  final Color warningWash;
  final Color danger;
  final Color dangerWash;

  static const light = StatusColors(
    success: _Light.green,
    successWash: _Light.greenWash,
    warning: _Light.amber,
    warningWash: _Light.amberWash,
    danger: _Light.red,
    dangerWash: _Light.redWash,
  );

  static const dark = StatusColors(
    success: _Dark.green,
    successWash: _Dark.greenWash,
    warning: _Dark.amber,
    warningWash: _Dark.amberWash,
    danger: _Dark.red,
    dangerWash: _Dark.redWash,
  );

  @override
  StatusColors copyWith({
    Color? success,
    Color? successWash,
    Color? warning,
    Color? warningWash,
    Color? danger,
    Color? dangerWash,
  }) {
    return StatusColors(
      success: success ?? this.success,
      successWash: successWash ?? this.successWash,
      warning: warning ?? this.warning,
      warningWash: warningWash ?? this.warningWash,
      danger: danger ?? this.danger,
      dangerWash: dangerWash ?? this.dangerWash,
    );
  }

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      successWash: Color.lerp(successWash, other.successWash, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningWash: Color.lerp(warningWash, other.warningWash, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerWash: Color.lerp(dangerWash, other.dangerWash, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: _Light.rose,
      onPrimary: Colors.white,
      primaryContainer: _Light.roseWash,
      onPrimaryContainer: _Light.onRoseWash,
      secondary: _Light.ink,
      onSecondary: Colors.white,
      secondaryContainer: _Light.beige,
      onSecondaryContainer: _Light.ink,
      tertiary: _Light.green,
      onTertiary: Colors.white,
      error: _Light.red,
      onError: Colors.white,
      errorContainer: _Light.redWash,
      onErrorContainer: _Light.red,
      surface: _Light.canvas,
      onSurface: _Light.ink,
      onSurfaceVariant: _Light.ink2,
      surfaceContainerLowest: _Light.card,
      surfaceContainerLow: _Light.card,
      surfaceContainer: _Light.sunken,
      surfaceContainerHigh: _Light.sunken,
      surfaceContainerHighest: _Light.beige,
      outline: _Light.lineStrong,
      outlineVariant: _Light.line,
      inverseSurface: _Light.ink,
      onInverseSurface: _Light.canvas,
      inversePrimary: _Dark.rose,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Color(0x66000000),
    ),
    StatusColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: _Dark.rose,
      onPrimary: Color(0xFF3A1E23),
      primaryContainer: _Dark.roseWash,
      onPrimaryContainer: _Dark.onRoseWash,
      secondary: _Dark.ink,
      onSecondary: _Dark.canvas,
      secondaryContainer: _Dark.beige,
      onSecondaryContainer: _Dark.ink,
      tertiary: _Dark.green,
      onTertiary: _Dark.canvas,
      error: _Dark.red,
      onError: Color(0xFF3F1310),
      errorContainer: _Dark.redWash,
      onErrorContainer: _Dark.red,
      surface: _Dark.canvas,
      onSurface: _Dark.ink,
      onSurfaceVariant: _Dark.ink2,
      surfaceContainerLowest: _Dark.card,
      surfaceContainerLow: _Dark.card,
      surfaceContainer: _Dark.sunken,
      surfaceContainerHigh: _Dark.sunken,
      surfaceContainerHighest: _Dark.beige,
      outline: _Dark.lineStrong,
      outlineVariant: _Dark.line,
      inverseSurface: _Dark.ink,
      onInverseSurface: _Dark.canvas,
      inversePrimary: _Light.rose,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Color(0x99000000),
    ),
    StatusColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final base = ThemeData(colorScheme: scheme, brightness: scheme.brightness);
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = text.copyWith(
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: scheme.outlineVariant),
    );
    const pill = StadiumBorder();
    const flat = WidgetStatePropertyAll<double>(0);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      extensions: [status],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: flat,
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          elevation: flat,
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: flat,
          shape: const WidgetStatePropertyAll(pill),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showCheckmark: false,
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.bodyMedium,
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape.copyWith(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        modalBackgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        modalElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape.copyWith(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }
}
