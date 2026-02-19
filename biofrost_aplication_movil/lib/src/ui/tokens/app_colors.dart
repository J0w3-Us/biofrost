import 'package:flutter/material.dart';

/// Paleta de colores centralizada de Bifrost.
///
/// Todos los widgets del UI Kit y pantallas de la app deben
/// referenciar estas constantes en lugar de valores `Color` literales.
abstract final class AppColors {
  // ── Fondos ────────────────────────────────────────────────────────────────
  /// Fondo base de toda la app (dark-navy).
  static const Color background = Color(0xFF0F0F1A);

  /// Fondo de superficies elevadas: cards, inputs, sheets.
  static const Color surface = Color(0xFF1A1A2E);

  /// Fondo de superficies de segundo nivel (hover states, chips).
  static const Color surfaceVariant = Color(0xFF252540);

  // ── Bordes ────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF374151);
  static const Color borderFocus = Color(0xFF7C3AED);

  // ── Primario (purple) ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryVariant = Color(0xFF5B21B6);
  static const Color primaryMuted = Color(0xFF4C1D95);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4B5563);

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFF78350F);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFF1E3A5F);

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const Color roleAlumno = Color(0xFF3B82F6);
  static const Color roleDocente = Color(0xFF10B981);
  static const Color roleAdmin = Color(0xFFEF4444);
  static const Color roleInvitado = Color(0xFFF59E0B);

  /// Devuelve el color asociado al rol del usuario.
  static Color forRol(String rol) => switch (rol) {
    'Alumno' => roleAlumno,
    'Docente' => roleDocente,
    'Admin' => roleAdmin,
    _ => roleInvitado,
  };

  // ── Overlay / Scrim ───────────────────────────────────────────────────────
  static const Color scrim = Color(0xB3000000); // 70 % opaco
}
