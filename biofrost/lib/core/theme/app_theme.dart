import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de diseño global de Biofrost.
///
/// Paleta: basada en el sistema de colores del frontend (OKLCH → sRGB).
/// Estética: Purple-slate, soporte completo light / dark.
/// Tipografía: Inter (Variable).
///
/// Uso:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(),
///   ...
/// )
/// ```
abstract class AppTheme {
  AppTheme._();

  // ── Paleta dark (defaults estáticos — usados por widgets) ────────────

  /// Fondo base oscuro — oklch(0.2166 0.0215 292.85)
  static const surface0 = Color(0xFF1A1823);

  /// Tarjetas oscuras — oklch(0.2544 0.0301 292.73)
  static const surface1 = Color(0xFF232030);

  /// Inputs oscuros — oklch(0.2847 0.0346 291.27)
  static const surface2 = Color(0xFF28233C);

  /// Hover / accent dark — oklch(0.3181 0.0321 308.61)
  static const surface3 = Color(0xFF372E3F);

  /// Borde oscuro — oklch(0.3063 0.0359 293.34)
  static const border = Color(0xFF2E2848);

  /// Borde con foco / ring — mismo que primary dark
  static const borderFocus = Color(0xFFA995C9);

  // ── Texto dark ───────────────────────────────────────────────────────

  /// Texto principal — oklch(0.9053 0.0245 293.56)
  static const textPrimary = Color(0xFFE0DDEF);

  /// Texto secundario / muted-foreground — oklch(0.6974 0.0282 300.06)
  static const textSecondary = Color(0xFFA09AAD);

  /// Texto deshabilitado — oklch(0.4604 0.0472 295.56)
  static const textDisabled = Color(0xFF5A5370);

  /// Texto sobre colores de marca (inverse)
  static const textInverse = Color(0xFF1A1823);

  // ── Colores de marca ──────────────────────────────────────────────────

  /// Primary dark — oklch(0.7058 0.0777 302.05)
  static const primary = Color(0xFFA995C9);

  /// Accent-foreground dark (pink) — oklch(0.8391 0.0692 2.67)
  static const accent = Color(0xFFF2B8C6);

  // ── Primitivos ─────────────────────────────────────────────────────────
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // ── Estados (conservan iOS palette para reconocimiento universal) ─────

  static const success = Color(0xFF34C759);
  static const error =
      Color(0xFFE57373); // destructive dark — oklch(0.6875 0.142 21.46)
  static const warning = Color(0xFFFF9F0A);
  static const info = Color(0xFF0A84FF);

  // ── Badges de estado de proyecto ─────────────────────────────────────
  static const badgeGreen = Color(0xFF1A3D2B);
  static const badgeGreenText = Color(0xFF34C759);
  static const badgeBlue = Color(0xFF0D2137);
  static const badgeBlueText = Color(0xFF0A84FF);
  static const badgeGray = Color(0xFF2E2848);
  static const badgeGrayText = Color(0xFFA09AAD);

  // ── Podio ──────────────────────────────────────────────────────────────
  static const podiumGold = Color(0xFFD4AF37);
  static const podiumSilver = Color(0xFF9E9E9E);
  static const podiumBronze = Color(0xFFCD7F32);

  // ── Paleta light (privada — usada solo en light() ThemeData) ─────────

  /// oklch(0.9777 0.0041 301.43)
  static const _lBackground = Color(0xFFF8F7FA);

  /// oklch(0.3651 0.0325 287.08)
  static const _lForeground = Color(0xFF3C3B4F);

  static const _lCard = Color(0xFFFFFFFF);

  /// oklch(0.6104 0.0767 299.73)
  static const _lPrimary = Color(0xFF8A79AB);

  /// oklch(0.8957 0.0265 300.24)
  static const _lSecondary = Color(0xFFDFD9EC);

  /// oklch(0.8906 0.0139 299.78)
  static const _lMuted = Color(0xFFE1DCE8);

  /// oklch(0.5288 0.0375 290.79)
  static const _lMutedFg = Color(0xFF6B6880);

  /// oklch(0.7889 0.0802 359.94) — pink accent
  static const _lAccent = Color(0xFFE6A5B8);

  /// oklch(0.3394 0.0441 1.76) — dark rose
  static const _lAccentFg = Color(0xFF4B2E36);

  /// oklch(0.6332 0.1578 22.67)
  static const _lDestructive = Color(0xFFD95C5C);

  /// oklch(0.8447 0.0226 300.14)
  static const _lBorder = Color(0xFFCDC9E2);

  /// oklch(0.9329 0.0124 301.28)
  static const _lInput = Color(0xFFEEEAF5);

  /// oklch(0.9554 0.0082 301.35) — sidebar light
  static const _lSidebar = Color(0xFFF2EFF9);

  // ── Radios ──────────────────────────────────────────────────────────

  static const double radiusXS = 6;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusFull = 999;

  static BorderRadius get bXS => BorderRadius.circular(radiusXS);
  static BorderRadius get bSM => BorderRadius.circular(radiusSM);
  static BorderRadius get bMD => BorderRadius.circular(radiusMD);
  static BorderRadius get bLG => BorderRadius.circular(radiusLG);
  static BorderRadius get bXL => BorderRadius.circular(radiusXL);
  static BorderRadius get bFull => BorderRadius.circular(radiusFull);

  // ── Espaciado ────────────────────────────────────────────────────────

  static const double sp2 = 2;
  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp40 = 40;
  static const double sp48 = 48;

  // ── Sombras ──────────────────────────────────────────────────────────

  /// Sombra suave para tarjetas — shadow-sm del sistema CSS.
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: Colors.black.withAlpha(46), // ~0.18 opacity
          blurRadius: 5,
          spreadRadius: 1,
          offset: const Offset(1, 2),
        ),
        BoxShadow(
          color: Colors.black.withAlpha(15),
          blurRadius: 2,
          offset: const Offset(1, 1),
        ),
      ];

  /// Sombra elevada para modales — shadow-lg.
  static List<BoxShadow> get shadowModal => [
        BoxShadow(
          color: Colors.black.withAlpha(60),
          blurRadius: 6,
          spreadRadius: 1,
          offset: const Offset(1, 4),
        ),
      ];

  /// Sombra ring / glow para widget activo.
  static List<BoxShadow> get shadowGlow => [
        BoxShadow(
          color: primary.withAlpha(51), // ~0.20
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // ── Decoraciones reutilizables ───────────────────────────────────────

  /// Contenedor tarjeta estándar.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface1,
        borderRadius: bMD,
        border: Border.all(color: border, width: 1),
        boxShadow: shadowCard,
      );

  /// Fondo de input / chip.
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: surface2,
        borderRadius: bSM,
        border: Border.all(color: border),
      );

  /// Input con enfoque activo.
  static BoxDecoration get inputFocusDecoration => BoxDecoration(
        color: surface2,
        borderRadius: bSM,
        border: Border.all(color: borderFocus, width: 1.5),
      );

  // ── Gradientes ───────────────────────────────────────────────────────

  /// Gradiente de fondo principal (dark).
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface0, Color(0xFF141220)],
  );

  /// Gradiente de fade-out inferior.
  static const fadeBottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, surface0],
  );

  // ── Durations de animación ───────────────────────────────────────────

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveSpring = Curves.easeOutCubic;

  // ── ThemeData ────────────────────────────────────────────────────────

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: surface0,
      primaryContainer: surface3,
      onPrimaryContainer: textPrimary,
      secondary: textSecondary,
      onSecondary: surface0,
      secondaryContainer: surface2,
      onSecondaryContainer: textPrimary,
      tertiary: accent,
      onTertiary: surface0,
      surface: surface1,
      onSurface: textPrimary,
      error: error,
      onError: surface0,
      outline: border,
      outlineVariant: borderFocus,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: _lBackground,
      onInverseSurface: _lForeground,
      inversePrimary: _lPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface0,
      fontFamily: 'Inter',
      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: surface0,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      // ── Bottom Navigation ────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface0,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface1,
        indicatorColor: surface3,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : textSecondary,
            size: 22,
          );
        }),
      ),
      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: bMD,
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      // ── Inputs ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        hintStyle: const TextStyle(
          color: textDisabled,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp16,
          vertical: sp14,
        ),
      ),
      // ── Botones ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface0,
          disabledBackgroundColor: surface3,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: bFull),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: bFull),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: surface3,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: bFull),
        padding: const EdgeInsets.symmetric(
          horizontal: sp12,
          vertical: sp4,
        ),
      ),
      // ── Divider ──────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      // ── SnackBar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: bMD),
        behavior: SnackBarBehavior.floating,
      ),
      // ── TextTheme ────────────────────────────────────────────────────
      textTheme: _buildTextTheme(textPrimary, textSecondary, textDisabled),
      // ── Slider ───────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surface3,
        thumbColor: primary,
        overlayColor: Color(0x22A995C9),
        trackHeight: 3,
      ),
      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? surface0
              : textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : surface3;
        }),
      ),
      // ── ListTile ─────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _lPrimary,
      onPrimary: _lBackground,
      primaryContainer: _lSecondary,
      onPrimaryContainer: _lForeground,
      secondary: _lMutedFg,
      onSecondary: _lBackground,
      secondaryContainer: _lMuted,
      onSecondaryContainer: _lForeground,
      tertiary: _lAccent,
      onTertiary: _lAccentFg,
      surface: _lCard,
      onSurface: _lForeground,
      error: _lDestructive,
      onError: _lBackground,
      outline: _lBorder,
      outlineVariant: _lPrimary,
      shadow: Colors.black,
      scrim: Colors.black38,
      inverseSurface: surface1,
      onInverseSurface: textPrimary,
      inversePrimary: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lBackground,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: _lBackground,
        foregroundColor: _lForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _lForeground,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _lForeground, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lBackground,
        selectedItemColor: _lPrimary,
        unselectedItemColor: _lMutedFg,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lSidebar,
        indicatorColor: _lSecondary,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _lForeground,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _lPrimary : _lMutedFg,
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: _lCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: bMD,
          side: const BorderSide(color: _lBorder, width: 1),
        ),
        shadowColor: Colors.black.withAlpha(20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lInput,
        hintStyle: const TextStyle(
          color: _lMutedFg,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: _lMutedFg,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: _lBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: _lBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: _lPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: _lDestructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: bSM,
          borderSide: const BorderSide(color: _lDestructive, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp16,
          vertical: sp14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lPrimary,
          foregroundColor: _lBackground,
          disabledBackgroundColor: _lMuted,
          disabledForegroundColor: _lMutedFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: bFull),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lPrimary,
          side: const BorderSide(color: _lBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: bFull),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lMuted,
        selectedColor: _lSecondary,
        side: const BorderSide(color: _lBorder),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lMutedFg,
        ),
        shape: RoundedRectangleBorder(borderRadius: bFull),
        padding: const EdgeInsets.symmetric(
          horizontal: sp12,
          vertical: sp4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _lBorder,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lCard,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: _lForeground,
        ),
        shape: RoundedRectangleBorder(borderRadius: bMD),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: _buildTextTheme(_lForeground, _lMutedFg, _lMuted),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _lPrimary,
        inactiveTrackColor: _lMuted,
        thumbColor: _lPrimary,
        overlayColor: Color(0x228A79AB),
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? _lBackground
              : _lMutedFg;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? _lPrimary : _lMuted;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _lMutedFg,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _lForeground,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _lMutedFg,
        ),
      ),
    );
  }

  // ── TextTheme completo ───────────────────────────────────────────────

  static TextTheme _buildTextTheme(
    Color fg,
    Color fgSec,
    Color fgDis,
  ) =>
      TextTheme(
        // Display
        displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: fg),
        displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: fg),
        displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: fg),
        // Headline
        headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: fg),
        headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: fg),
        headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: fg),
        // Title
        titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: fg),
        titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: fg),
        titleSmall:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
        // Body
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: fg, height: 1.5),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: fg, height: 1.5),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: fgSec,
            height: 1.4),
        // Label
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: fg),
        labelMedium:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fgSec),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: fgDis),
      );
}

// ── Constante extra que necesita InputDecorationTheme ──────────────────

const double sp14 = 14;

// ── Extensiones de conveniencia ──────────────────────────────────────────

extension ContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  // ── Toast / SnackBar system ─────────────────────────────────────────────
  // RF-TOAST: 4 tipos diferenciados (spec §4.4 Toast / Snackbar System)
  // Éxito (4 s) · Error de red con Reintentar · Advertencia (5 s) · Info (3 s)

  /// Toast de éxito — auto-dismiss 4 s (spec §4.4).
  void showSuccess(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bioSnackBar(
          message: message,
          borderColor: AppTheme.success,
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Toast de error de red — con botón "Reintentar" (spec §4.4).
  void showError(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bioSnackBar(
          message: message,
          borderColor: AppTheme.error,
          icon: Icons.error_outline_rounded,
          iconColor: AppTheme.error,
          duration: const Duration(seconds: 6),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Reintentar',
                  textColor: AppTheme.error,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
  }

  /// Toast de advertencia — auto-dismiss 5 s (spec §4.4).
  void showWarning(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bioSnackBar(
          message: message,
          borderColor: AppTheme.warning,
          icon: Icons.warning_amber_rounded,
          iconColor: AppTheme.warning,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  /// Toast informativo — auto-dismiss 3 s (spec §4.4).
  void showInfo(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        _bioSnackBar(
          message: message,
          borderColor: AppTheme.info,
          icon: Icons.info_outline_rounded,
          iconColor: AppTheme.info,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Constructor interno de SnackBar con borde de color diferenciador.
  SnackBar _bioSnackBar({
    required String message,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    return SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.surface2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp16,
        vertical: AppTheme.sp12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.bMD,
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      content: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppTheme.sp10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      action: action,
    );
  }
}
