import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'painpal_app_colors.dart';

ThemeData buildPainpalTheme({
  required Brightness brightness,
  required PainpalAppColors c,
}) {
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.accentPrimary,
    onPrimary: c.textOnAccent,
    primaryContainer: c.accentPrimaryLight,
    onPrimaryContainer: c.textPrimary,
    secondary: c.accentSecondary,
    onSecondary: isDark ? c.textOnAccent : Colors.white,
    secondaryContainer: c.accentSecondaryLight,
    onSecondaryContainer: c.accentSecondary,
    tertiary: c.accentSuccess,
    onTertiary: c.textOnAccent,
    tertiaryContainer: c.accentSuccessLight,
    onTertiaryContainer: c.textPrimary,
    error: c.accentDanger,
    onError: Colors.white,
    surface: c.bgCard,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerHighest: c.bgCardElevated,
    outline: c.borderDefault,
    outlineVariant: c.borderDefault.withValues(alpha: 0.6),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: c.textPrimary,
    displayColor: c.textPrimary,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bgTertiary,
    canvasColor: c.bgTertiary,
    dividerColor: c.borderDefault,
    extensions: <ThemeExtension<dynamic>>[c],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgCard,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.bgCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PainpalRadii.cardBubble),
        side: BorderSide(color: c.borderDefault),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PainpalRadii.lg),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PainpalRadii.xl)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor:
            isDark ? c.accentPrimary : const Color(0xFF1C1B2E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PainpalRadii.pill),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accentPrimary,
        side: BorderSide(color: c.accentPrimary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PainpalRadii.pill),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PainpalRadii.lg),
        borderSide: BorderSide(color: c.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PainpalRadii.lg),
        borderSide: BorderSide(color: c.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PainpalRadii.lg),
        borderSide: BorderSide(color: c.borderFocus, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.accentPrimary,
      textColor: c.textPrimary,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.bgCard,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accentSecondary,
      foregroundColor: c.textOnAccent,
    ),
  );
}
