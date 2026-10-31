import 'package:flutter/material.dart';

// Interface colours only, never dye colours. Warm paper, olive ink and
// restrained surface steps keep the actual pigment swatches prominent.

abstract final class _Light {
  static const canvas = Color(0xFFF5F4EE);
  static const card = Color(0xFFFFFEFA);
  static const sunken = Color(0xFFEEEDE5);
  static const beige = Color(0xFFE4E5DA);
  static const line = Color(0xFFDDDFD3);
  // field and control outlines: 3:1 against the card, the least a field's
  // edge needs to be seen
  static const lineStrong = Color(0xFF8E9383);
  static const ink = Color(0xFF252D26);
  static const ink2 = Color(0xFF646B60);
  static const accent = Color(0xFF435B46);
  static const accentWash = Color(0xFFE3EADB);
  static const onAccentWash = Color(0xFF304133);
  static const green = Color(0xFF2F7350);
  static const greenWash = Color(0xFFE2F0E7);
  static const amber = Color(0xFF8F5409);
  static const amberWash = Color(0xFFFBEED8);
  static const red = Color(0xFFB0302A);
  static const redWash = Color(0xFFF9E1DF);
}

abstract final class _Dark {
  static const canvas = Color(0xFF191E1A);
  static const card = Color(0xFF222923);
  static const sunken = Color(0xFF2B332C);
  static const beige = Color(0xFF364037);
  static const line = Color(0xFF39433A);
  static const lineStrong = Color(0xFF74816F);
  static const ink = Color(0xFFF0F1E8);
  static const ink2 = Color(0xFFB5BDB0);
  static const accent = Color(0xFFB8CDA5);
  static const accentWash = Color(0xFF344631);
  static const onAccentWash = Color(0xFFD9E8CC);
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

/// the styles screens kept rebuilding by hand: the small spaced label over a
/// title, a page's serif heading, and the big numbers read off the scale
@immutable
class StudioType extends ThemeExtension<StudioType> {
  const StudioType({
    required this.eyebrow,
    required this.pageTitle,
    required this.figure,
    required this.figureSmall,
  });

  /// 'YOUR COLOR TARGET'. 12 px, never smaller
  final TextStyle eyebrow;

  /// 'Your studio archive.' on phones, see [pageTitleFor]
  final TextStyle pageTitle;

  /// the live weight, sans with even-width digits
  final TextStyle figure;

  /// a total or a reading inside a card
  final TextStyle figureSmall;

  TextStyle pageTitleFor({required bool narrow}) =>
      narrow ? pageTitle : pageTitle.copyWith(fontSize: 38);

  static StudioType of(TextTheme t, ColorScheme scheme) {
    const digits = [FontFeature.tabularFigures()];
    return StudioType(
      eyebrow: t.labelSmall!.copyWith(
        fontSize: 12,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      pageTitle: t.headlineMedium!.copyWith(
        fontSize: 28,
        height: 1.15,
        letterSpacing: -0.8,
      ),
      figure: t.displayLarge!.copyWith(
        fontFamily: 'StudioSans',
        fontSize: 64,
        fontWeight: FontWeight.w500,
        letterSpacing: -2.5,
        height: 1.05,
        fontFeatures: digits,
      ),
      figureSmall: t.displaySmall!.copyWith(
        fontFamily: 'StudioSans',
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        fontFeatures: digits,
      ),
    );
  }

  @override
  StudioType copyWith({
    TextStyle? eyebrow,
    TextStyle? pageTitle,
    TextStyle? figure,
    TextStyle? figureSmall,
  }) {
    return StudioType(
      eyebrow: eyebrow ?? this.eyebrow,
      pageTitle: pageTitle ?? this.pageTitle,
      figure: figure ?? this.figure,
      figureSmall: figureSmall ?? this.figureSmall,
    );
  }

  @override
  StudioType lerp(StudioType? other, double t) {
    if (other == null) return this;
    return StudioType(
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      pageTitle: TextStyle.lerp(pageTitle, other.pageTitle, t)!,
      figure: TextStyle.lerp(figure, other.figure, t)!,
      figureSmall: TextStyle.lerp(figureSmall, other.figureSmall, t)!,
    );
  }
}

extension StudioTypeX on BuildContext {
  StudioType get type => Theme.of(this).extension<StudioType>()!;
}

/// corner sizes. a hairline bar, a tag or small swatch, a control (button,
/// field, menu), a tile in a list, a card or sheet
abstract final class Radii {
  static const double bar = 2;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: _Light.accent,
      onPrimary: Colors.white,
      primaryContainer: _Light.accentWash,
      onPrimaryContainer: _Light.onAccentWash,
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
      inversePrimary: _Dark.accent,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Color(0x66000000),
    ),
    StatusColors.light,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: _Dark.accent,
      onPrimary: Color(0xFF20301F),
      primaryContainer: _Dark.accentWash,
      onPrimaryContainer: _Dark.onAccentWash,
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
      inversePrimary: _Light.accent,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
      scrim: Color(0x99000000),
    ),
    StatusColors.dark,
  );

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final base = ThemeData(
      colorScheme: scheme,
      brightness: scheme.brightness,
      fontFamily: 'StudioSans',
      useMaterial3: true,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -2,
        height: 1.08,
      ),
      displayMedium: text.displayMedium?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displaySmall: text.displaySmall?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -1,
        height: 1.12,
      ),
      headlineLarge: text.headlineLarge?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -0.6,
        height: 1.18,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: 'StudioSerif',
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.5, letterSpacing: 0),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45, letterSpacing: 0),
      bodySmall: text.bodySmall?.copyWith(height: 1.4, letterSpacing: 0),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      // material's 11 px is too small to read at the bench
      labelSmall: text.labelSmall?.copyWith(fontSize: 12),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.xl),
      side: BorderSide(color: scheme.outlineVariant),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );
    const flat = WidgetStatePropertyAll<double>(0);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      extensions: [status, StudioType.of(textTheme, scheme)],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
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
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            size: 23,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
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
          shape: WidgetStatePropertyAll(controlShape),
          minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          elevation: flat,
          shape: WidgetStatePropertyAll(controlShape),
          minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: flat,
          shape: WidgetStatePropertyAll(controlShape),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
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
          shape: WidgetStatePropertyAll(controlShape),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape.copyWith(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Radii.xl),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape.copyWith(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }
}
