import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

import 'package:biofrost/features/project_detail/domain/models/project_detail_read_model.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/features/sharing/sharing_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// QR Modal — 5.2
// ══════════════════════════════════════════════════════════════════════════════

/// Muestra un bottom sheet con el QR del proyecto y opciones de guardado/share.
///
/// Uso:
/// ```dart
/// QrModal.show(context, project: project);
/// ```
class QrModal extends ConsumerStatefulWidget {
  const QrModal({super.key, required this.project});

  final ProjectDetailReadModel project;

  static Future<void> show(
    BuildContext context, {
    required ProjectDetailReadModel project,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrModal(project: project),
    );
  }

  @override
  ConsumerState<QrModal> createState() => _QrModalState();
}

class _QrModalState extends ConsumerState<QrModal> {
  final _screenshotCtrl = ScreenshotController();
  bool _saving = false;
  bool _saved = false;

  String get _deepLink => 'biofrost://project/${widget.project.id}';

  // ── Guardar QR en galería ──────────────────────────────────────────────────

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);

    final bytes = await _screenshotCtrl.capture(pixelRatio: 3.0);
    if (bytes == null) {
      setState(() => _saving = false);
      return;
    }

    final ok = await SharingService.saveImageToGallery(
      bytes,
      name: 'biofrost_qr_${widget.project.id}',
    );

    if (mounted) {
      setState(() {
        _saving = false;
        _saved = ok;
      });
      if (ok) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _saved = false);
      }
    }
  }

  // ── Compartir QR ───────────────────────────────────────────────────────────

  Future<void> _shareQr() async {
    final bytes = await _screenshotCtrl.capture(pixelRatio: 3.0);
    if (bytes == null) return;

    await SharingService.shareImage(
      bytes,
      fileName: 'biofrost_qr_${widget.project.id}.png',
      text: '📲 Escanea para ver "${widget.project.titulo}" en Biofrost',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          const Text(
            'Código QR del Proyecto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            project.titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // ── QR Card (capturada por Screenshot) ────────────────────────────
          Screenshot(
            controller: _screenshotCtrl,
            child: _QrCard(project: project, deepLink: _deepLink),
          ),

          const SizedBox(height: 28),

          // ── Botones de acción ─────────────────────────────────────────────
          Row(
            children: [
              // Guardar en galería
              Expanded(
                child: _ActionButton(
                  icon: _saved ? Icons.check_rounded : Icons.download_rounded,
                  label: _saved ? '¡Guardado!' : 'Guardar',
                  loading: _saving,
                  filled: false,
                  onTap: _saving ? null : _saveToGallery,
                ),
              ),
              const SizedBox(width: 12),
              // Compartir
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Compartir',
                  filled: true,
                  onTap: _shareQr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── QR Card widget (el que se captura) ────────────────────────────────────────

class _QrCard extends StatelessWidget {
  const _QrCard({required this.project, required this.deepLink});

  final ProjectDetailReadModel project;
  final String deepLink;

  @override
  Widget build(BuildContext context) {
    final stackPreview = project.stackTecnologico.take(3).join('  ·  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo + brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'BIOFROST',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR code
          QrImageView(
            data: deepLink,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            embeddedImage: const AssetImage('assets/images/qr_logo.png'),
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(36, 36),
            ),
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          const SizedBox(height: 20),

          // Nombre del proyecto
          Text(
            project.titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (stackPreview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              stackPreview,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 12),
          // URL legible
          Text(
            'biofrost.utm.mx/project/${project.id.length > 8 ? project.id.substring(0, 8) : project.id}...',
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

// ── Botón de acción ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: filled ? Colors.black : AppTheme.textPrimary,
                  ),
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
