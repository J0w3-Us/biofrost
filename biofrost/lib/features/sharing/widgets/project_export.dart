import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/features/sharing/sharing_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 5.3 — Captura de tarjeta como imagen
// ══════════════════════════════════════════════════════════════════════════════

/// Captura el ProjectCard como PNG y permite guardar/compartir.
class ProjectCardCapture extends StatefulWidget {
  const ProjectCardCapture({super.key, required this.project});
  final ProjectDetailReadModel project;

  static Future<void> show(
    BuildContext context, {
    required ProjectDetailReadModel project,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectCardCapture(project: project),
    );
  }

  @override
  State<ProjectCardCapture> createState() => _ProjectCardCaptureState();
}

class _ProjectCardCaptureState extends State<ProjectCardCapture> {
  final _ctrl = ScreenshotController();
  bool _capturing = false;
  String? _feedback;

  Future<void> _capture(bool saveToGallery) async {
    setState(() {
      _capturing = true;
      _feedback = null;
    });

    final bytes = await _ctrl.capture(pixelRatio: 3.0);
    if (bytes == null) {
      setState(() => _capturing = false);
      return;
    }

    if (saveToGallery) {
      final ok = await SharingService.saveImageToGallery(
        bytes,
        name: 'biofrost_card_${widget.project.id}',
      );
      setState(() {
        _capturing = false;
        _feedback = ok ? '✅ Guardada en galería' : '❌ Error al guardar';
      });
    } else {
      await SharingService.shareImage(
        bytes,
        fileName: 'biofrost_${widget.project.id}.png',
        text: '🚀 ${widget.project.titulo} — Proyecto IntegradorHub',
      );
      setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Compartir Tarjeta',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Card capturada ────────────────────────────────────────────────
          Screenshot(
            controller: _ctrl,
            child: _ShareableCard(project: widget.project),
          ),

          const SizedBox(height: 24),

          if (_feedback != null) ...[
            Text(
              _feedback!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: _Btn(
                  icon: Icons.save_alt_rounded,
                  label: 'Guardar',
                  loading: _capturing,
                  onTap: _capturing ? null : () => _capture(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Btn(
                  icon: Icons.ios_share_rounded,
                  label: 'Compartir',
                  filled: true,
                  loading: _capturing,
                  onTap: _capturing ? null : () => _capture(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta compartible ───────────────────────────────────────────────────────

class _ShareableCard extends StatelessWidget {
  const _ShareableCard({required this.project});
  final ProjectDetailReadModel project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'BIOFROST',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface3,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  project.estado,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            project.titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${project.materia}  ·  ${project.ciclo ?? 'DSM'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Stack chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.stackTecnologico
                .take(5)
                .map(
                  (tech) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface3,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Equipo
          if (project.members.isNotEmpty)
            Row(
              children: [
                ...project.members.take(4).map(
                      (m) => Container(
                        width: 28, height: 28,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface3,
                          border: Border.all(color: AppTheme.border, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            m.nombre.isNotEmpty ? m.nombre[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(width: 8),
                Text(
                  '${project.memberCount} integrante${project.memberCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),
          Divider(color: AppTheme.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),

          // Footer con URL
          Text(
            'biofrost.utm.mx/project/${project.id}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppTheme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón reusable ────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppTheme.white : AppTheme.surface2,
          borderRadius: AppTheme.bSM,
          border: filled ? null : Border.all(color: AppTheme.border),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16,
                      color: filled ? Colors.black : AppTheme.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: filled ? Colors.black : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 5.4 — One-Pager PDF
// ══════════════════════════════════════════════════════════════════════════════

/// Genera y lanza el diálogo de impresión/compartir del One-Pager PDF.
class ProjectPdfExporter {
  const ProjectPdfExporter._();

  /// Genera el PDF y abre el diálogo del sistema (imprimir / guardar / Share).
  static Future<void> exportAndShare(
    BuildContext context,
    ProjectDetailReadModel project,
  ) async {
    await Printing.layoutPdf(
      name: '${project.titulo} — Biofrost',
      onLayout: (format) => _buildPdf(project, format),
    );
  }

  // ── Builder del documento PDF ─────────────────────────────────────────────

  static Future<Uint8List> _buildPdf(
    ProjectDetailReadModel project,
    PdfPageFormat format,
  ) async {
    final doc = pw.Document(
      title: project.titulo,
      author: project.liderNombre ?? 'Biofrost',
      subject: 'One-Pager del Proyecto Integrador',
    );

    // Fuentes
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontExtraBold = await PdfGoogleFonts.interExtraBold();

    // Colores
    const bgDark = PdfColor.fromInt(0xFF0A0A0A);
    const surface = PdfColor.fromInt(0xFF141414);
    const borderColor = PdfColor.fromInt(0xFF2A2A2A);
    const primary = PdfColor.fromInt(0xFFE8E8E8);
    const secondary = PdfColor.fromInt(0xFF8A8A8A);
    const accent = PdfColor.fromInt(0xFFFFFFFF);

    // QR en bytes
    final qrBytes = await _generateQrBytes(
      'biofrost://project/${project.id}',
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: surface,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Info principal
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Brand
                        pw.Text(
                          'BIOFROST  ·  IntegradorHub',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: secondary,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        // Título
                        pw.Text(
                          project.titulo,
                          style: pw.TextStyle(
                            font: fontExtraBold,
                            fontSize: 22,
                            color: accent,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '${project.materia}  ·  ${project.ciclo ?? 'DSM'}',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 11,
                            color: secondary,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        // Estado badge
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: bgDark,
                            borderRadius: pw.BorderRadius.circular(20),
                            border: pw.Border.all(color: borderColor),
                          ),
                          child: pw.Text(
                            project.estado.toUpperCase(),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9,
                              color: primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // QR
                  pw.Column(
                    children: [
                      if (qrBytes != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Image(
                            pw.MemoryImage(qrBytes),
                            width: 90,
                            height: 90,
                          ),
                        ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Escanear',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Stack Tecnológico ────────────────────────────────────────────
            _pdfSection(
              title: 'Stack Tecnológico',
              fontBold: fontBold,
              fontRegular: fontRegular,
              surface: surface,
              borderColor: borderColor,
              accent: accent,
              secondary: secondary,
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.stackTecnologico
                    .map(
                      (tech) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: bgDark,
                          borderRadius: pw.BorderRadius.circular(16),
                          border: pw.Border.all(color: borderColor),
                        ),
                        child: pw.Text(
                          tech,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Equipo ───────────────────────────────────────────────────────
            if (project.members.isNotEmpty)
              _pdfSection(
                title: 'Equipo (${project.memberCount} integrantes)',
                fontBold: fontBold,
                fontRegular: fontRegular,
                surface: surface,
                borderColor: borderColor,
                accent: accent,
                secondary: secondary,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: project.members
                      .map(
                        (m) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 24,
                                height: 24,
                                decoration: pw.BoxDecoration(
                                  color: bgDark,
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(color: borderColor),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    m.nombre.isNotEmpty
                                        ? m.nombre[0].toUpperCase()
                                        : '?',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 10,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Text(
                                m.nombre,
                                style: pw.TextStyle(
                                  font: m.esLider ? fontBold : fontRegular,
                                  fontSize: 11,
                                  color: m.esLider ? accent : primary,
                                ),
                              ),
                              if (m.esLider) ...[
                                pw.SizedBox(width: 6),
                                pw.Text(
                                  'Líder',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 9,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            pw.SizedBox(height: 12),

            // ── Docente ───────────────────────────────────────────────────────
            if (project.docenteNombre != null)
              _pdfSection(
                title: 'Evaluador',
                fontBold: fontBold,
                fontRegular: fontRegular,
                surface: surface,
                borderColor: borderColor,
                accent: accent,
                secondary: secondary,
                child: pw.Row(
                  children: [
                    pw.Icon(
                      const pw.IconData(0xe7fd), // person icon
                      color: secondary,
                      size: 16,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      project.docenteNombre!,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 12,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Footer ────────────────────────────────────────────────────────
            pw.Spacer(),
            pw.Divider(color: borderColor, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'biofrost.utm.mx/project/${project.id}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9,
                    color: secondary,
                  ),
                ),
                pw.Text(
                  'Generado por Biofrost — IntegradorHub DSM',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── Genera los bytes PNG del QR (para embebido en PDF) ──────────────────

  static Future<Uint8List?> _generateQrBytes(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );
      final image = await painter.toImageData(300);
      return image?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[PDF] Error generando QR bytes: $e');
      return null;
    }
  }

  // ── Helper para secciones del PDF ─────────────────────────────────────────

  static pw.Widget _pdfSection({
    required String title,
    required pw.Widget child,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required PdfColor surface,
    required PdfColor borderColor,
    required PdfColor accent,
    required PdfColor secondary,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: secondary,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
