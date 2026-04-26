import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF6360FF);
  static const Color secondaryColor = Color(0xFFF1F1FA);
  static const Color tertiaryColor = Color(0xFFFF8181);

  // Light-mode muted text tones — the values that already shipped, kept
  // exactly as-is so light mode is byte-for-byte unchanged.
  static const Color lightMutedText = Color(0xFF757575); // Colors.grey[600]
  static const Color lightFaintText = Color(0xFF9E9E9E); // Colors.grey[500]

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          );
        }
        return GoogleFonts.poppins(fontSize: 12);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // Dark-mode surface tokens — used directly by widgets that need to
  // pick a colour without going through Theme.of(context).
  static const Color darkScaffoldBg = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1C1C24);
  static const Color darkSurfaceElevated = Color(0xFF24242E);
  static const Color darkBorder = Color(0xFF2E2E3A);
  static const Color darkOnSurface = Color(0xFFE6E6EE);
  static const Color darkOnSurfaceMuted = Color(0xFFB0B0C0);
  static const Color darkOnSurfaceFaint = Color(0xFF7A7A8A);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkScaffoldBg,
    canvasColor: darkScaffoldBg,
    cardColor: darkSurface,
    dividerColor: darkBorder,
    hintColor: darkOnSurfaceFaint,
    iconTheme: const IconThemeData(color: darkOnSurface),
    primaryIconTheme: const IconThemeData(color: darkOnSurface),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: darkSurface,
      onSurface: darkOnSurface,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: darkOnSurface, displayColor: darkOnSurface),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: primaryColor.withValues(alpha: 0.20),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 12,
          color: darkOnSurfaceMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor);
        }
        return const IconThemeData(color: darkOnSurfaceMuted);
      }),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: darkSurfaceElevated,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurfaceElevated,
      contentTextStyle: TextStyle(color: darkOnSurface),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceElevated,
      hintStyle: const TextStyle(color: darkOnSurfaceFaint),
      labelStyle: const TextStyle(color: darkOnSurfaceMuted),
      iconColor: darkOnSurfaceMuted,
      prefixIconColor: darkOnSurfaceMuted,
      suffixIconColor: darkOnSurfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

/// Theme-aware text colour helpers.
///
/// Subtitle / secondary text in this app historically used hardcoded
/// `Colors.grey[600]` (#757575) and `Colors.grey[500]` (#9E9E9E). Those
/// look right on a white card but lose contrast on a dark card. These
/// getters return the *same* light-mode greys verbatim, but swap to
/// brighter dark-mode greys (`darkOnSurfaceMuted` / `darkOnSurfaceFaint`)
/// when the active theme is dark — so light mode stays byte-for-byte
/// identical and only dark mode improves.
extension AppColors on BuildContext {
  /// Primary muted text (titles' subtitles, metadata strings, etc.).
  /// Was: `Colors.grey[600]`.
  Color get mutedText {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightMutedText;
  }

  /// Secondary, fainter text (timestamps, captions, "Sem 2"-style chips).
  /// Was: `Colors.grey[500]`.
  Color get faintText {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppTheme.darkOnSurfaceFaint : AppTheme.lightFaintText;
  }
}
