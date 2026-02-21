import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'package:biofrost/core/models/project_read_model.dart';

/// Servicio central del Módulo 5 — Sharing, QR & Export.
///
/// Todos los métodos son estáticos: no requiere instanciación.
abstract class SharingService {
  // ── 5.1 Compartir link ─────────────────────────────────────────────────────

  /// Comparte un link y descripción breve del proyecto con cualquier app del
  /// sistema (WhatsApp, LinkedIn, correo, etc.).
  static Future<void> shareProjectLink(
    ProjectDetailReadModel project, {
    String? subject,
    Rect? sharePositionOrigin, // para iPad
  }) async {
    final deepLink = 'biofrost://project/${project.id}';
    final webLink = 'https://biofrost.utm.mx/project/${project.id}';

    final stack = project.stackTecnologico.take(3).join(' · ');
    final text = '''
🚀 *${project.titulo}*
${project.materia} · ${project.ciclo ?? 'DSM'}

Stack: $stack

Ver proyecto → $webLink
O abre en Biofrost → $deepLink
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text.trim(),
        subject: subject ?? project.titulo,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  // ── 5.2 Guardar imagen en galería ──────────────────────────────────────────

  /// Guarda [imageBytes] (PNG) en la galería del dispositivo.
  /// Retorna `true` si se guardó correctamente.
  static Future<bool> saveImageToGallery(
    Uint8List imageBytes, {
    String name = 'biofrost_project',
  }) async {
    try {
      // Verificar y solicitar permiso (gal lo hace internamente en Android 13+)
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImageBytes(imageBytes, name: name);
      return true;
    } catch (e) {
      debugPrint('[SharingService] Error guardando imagen: $e');
      return false;
    }
  }

  // ── 5.3 Compartir imagen ───────────────────────────────────────────────────

  /// Comparte [imageBytes] directamente sin guardar en galería.
  static Future<void> shareImage(
    Uint8List imageBytes, {
    String fileName = 'biofrost_project.png',
    String text = '',
    Rect? sharePositionOrigin,
  }) async {
    final xFile = XFile.fromData(
      imageBytes,
      name: fileName,
      mimeType: 'image/png',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
