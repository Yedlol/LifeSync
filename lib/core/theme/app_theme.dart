import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimary = Color(0xFF1E6FD9);

/// Corner radius used by cards, buttons, inputs and sheets.
const kRadius = 12.0;

/// Spacing scale: 4 / 8 / 12 / 16 / 24.
abstract final class Sp {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24;
}

/// Soft, low-contrast shadow for raised surfaces.
List<BoxShadow> softShadow(BuildContext context) => [
  BoxShadow(
    color: Colors.black.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
    ),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

const _colors = FlexSchemeColor(
  primary: kPrimary,
  primaryContainer: Color(0xFFD6E6FB),
  secondary: Color(0xFF4F83CC),
  secondaryContainer: Color(0xFFDCE8F8),
  tertiary: Color(0xFF3AA6C9),
  tertiaryContainer: Color(0xFFD3EEF7),
);

const _subThemes = FlexSubThemesData(
  defaultRadius: kRadius,
  blendOnLevel: 0,
  useMaterial3Typography: true,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorRadius: kRadius,
  filledButtonRadius: kRadius,
  outlinedButtonRadius: kRadius,
  textButtonRadius: kRadius,
  cardRadius: kRadius,
  cardElevation: 1,
  dialogRadius: 16,
  bottomSheetRadius: 20,
  chipRadius: 20,
  navigationBarIndicatorOpacity: 0.15,
  navigationRailIndicatorOpacity: 0.15,
  navigationBarHeight: 68,
  appBarScrolledUnderElevation: 1,
);

ThemeData _finish(ThemeData base) {
  final isDark = base.brightness == Brightness.dark;
  final textTheme = GoogleFonts.interTextTheme(base.textTheme);
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
    cardTheme: base.cardTheme.copyWith(
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
    ),
  );
}

/// Clean blue-and-white light theme.
ThemeData buildAppTheme() => _finish(
  FlexThemeData.light(
    colors: _colors,
    useMaterial3: true,
    surfaceMode: FlexSurfaceMode.level,
    blendLevel: 0,
    scaffoldBackground: Colors.white,
    subThemesData: _subThemes,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
  ),
);

/// Dark counterpart, same blue.
ThemeData buildDarkTheme() => _finish(
  FlexThemeData.dark(
    colors: _colors.toDark(20, false),
    useMaterial3: true,
    surfaceMode: FlexSurfaceMode.level,
    blendLevel: 0,
    subThemesData: _subThemes,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
  ),
);
