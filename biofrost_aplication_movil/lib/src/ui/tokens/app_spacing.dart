/// Tokens de espaciado y radio de bordes para Bifrost.
///
/// Usa múltiplos de 4 para consistencia en diseño táctil.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  /// Padding horizontal de página.
  static const double pagePadding = 20;

  /// Padding vertical de página.
  static const double pageVertical = 24;
}

/// Tokens de radio de bordes.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double base = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}
