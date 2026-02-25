import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de diseño global de Biofrost.
///
/// Paleta: negro puro / blanco puro — sin neon.
/// Estética: Neumórfico + Liquid Glass adaptado a mobile.
/// Tipografía: Inter (Variable).
///
/// Uso:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.dark(),
///   ...
/// )
/// ```
abstract class AppTheme {
  AppTheme._();

  // ── Paleta ──────────────────────────────────────────────────────────

  /// Colores primitivos del sistema.
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Superficies
  static const surface0 = Color(0xFF000000); // fondo base
  static const surface1 = Color(0xFF0D0D0D); // tarjetas
  static const surface2 = Color(0xFF1A1A1A); // inputs / chips
  static const surface3 = Color(0xFF262626); // hover / focus

  // Bordes
  static const border = Color(0xFF2E2E2E);
  static const borderFocus = Color(0xFF545454);

  // Texto
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const textDisabled = Color(0xFF555555);
  static const textInverse = Color(0xFF000000);

  // Estados
  static const success = Color(0xFF34C759); // verde iOS
  static const error = Color(0xFFFF453A); // rojo iOS
  static const warning = Color(0xFFFF9F0A); // naranja iOS
  static const info = Color(0xFF0A84FF); // azul iOS

  // Badges de estado de proyecto
  static const badgeGreen = Color(0xFF1A3D2B);
  static const badgeGreenText = Color(0xFF34C759);
  static const badgeBlue = Color(0xFF0D2137);
  static const badgeBlueText = Color(0xFF0A84FF);
  static const badgeGray = Color(0xFF1F1F1F);
  static const badgeGrayText = Color(0xFF888888);

  // Podio
  static const podiumGold = Color(0xFFD4AF37);
  static const podiumSilver = Color(0xFF9E9E9E);
  static const podiumBronze = Color(0xFFCD7F32);

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

  // ── Sombras neumórficas ──────────────────────────────────────────────

  /// Sombra suave para tarjetas sobre surface0.
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: Colors.black.withAlpha(204),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withAlpha(5),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  /// Sombra elevada para modales o panel flotante.
  static List<BoxShadow> get shadowModal => [
        BoxShadow(
          color: Colors.black.withAlpha(230),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  /// Sombra fina de borde luminoso para enfatizar un widget activo.
  static List<BoxShadow> get shadowGlow => [
        BoxShadow(
          color: Colors.white.withAlpha(20),
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

  /// Gradiente de fondo principal (negro puro).
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface0, Color(0xFF080808)],
  );

  /// Gradiente de fade-out inferior (para listas que desaparecen).
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
      primary: white,
      onPrimary: black,
      primaryContainer: surface2,
      onPrimaryContainer: textPrimary,
      secondary: textSecondary,
      onSecondary: black,
      secondaryContainer: surface3,
      onSecondaryContainer: textPrimary,
      tertiary: textDisabled,
      onTertiary: black,
      surface: surface1,
      onSurface: textPrimary,
      error: error,
      onError: white,
      outline: border,
      outlineVariant: borderFocus,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: white,
      onInverseSurface: black,
      inversePrimary: black,
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
        selectedItemColor: white,
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
            color: selected ? white : textSecondary,
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
          borderSide: const BorderSide(color: white, width: 1.5),
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
          backgroundColor: white,
          foregroundColor: black,
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
          foregroundColor: white,
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
          foregroundColor: textSecondary,
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
      textTheme: _buildTextTheme(),
      // ── Slider ───────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: white,
        inactiveTrackColor: surface3,
        thumbColor: white,
        overlayColor: Color(0x22FFFFFF),
        trackHeight: 3,
      ),
      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? black : textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? white : surface3;
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
      primary: black,
      onPrimary: white,
      primaryContainer: Color(0xFFF2F2F2),
      onPrimaryContainer: black,
      secondary: textSecondary,
      onSecondary: white,
      secondaryContainer: Color(0xFFF6F6F6),
      onSecondaryContainer: black,
      tertiary: textDisabled,
      onTertiary: white,
      surface: Color(0xFFFFFFFF),
      onSurface: black,
      error: error,
      onError: white,
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFBDBDBD),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: black,
      onInverseSurface: white,
      inversePrimary: white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Color(0xFFF8F8F8),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F8F8),
        foregroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      textTheme: _buildTextTheme(),
    );
  }

  // ── TextTheme completo ───────────────────────────────────────────────

  static TextTheme _buildTextTheme() => const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        // Headline
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        // Title
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        // Body
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        // Label
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: textDisabled,
        ),
      );
}

// ── Constante extra que necesita InputDecorationTheme ──────────────────

const double sp14 = 14;

// ── Extensiones de conveniencia ──────────────────────────────────────────

extension ContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Muestra un SnackBar de error con el estilo del sistema.
  void showError(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error.withAlpha(230),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un SnackBar de éxito.
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success.withAlpha(230),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
