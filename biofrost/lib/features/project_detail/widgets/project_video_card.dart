import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/features/project_detail/widgets/video_player_widget.dart';

/// Card dedicado exclusivamente para mostrar videos del proyecto
/// Siempre se muestra, incluso sin videos para mejor UX
class ProjectVideoCard extends StatelessWidget {
  const ProjectVideoCard({
    super.key,
    required this.videoUrl,
    required this.projectTitle,
    this.canvasVideoUrls = const [],
  });

  final String? videoUrl; // Video principal del proyecto
  final String projectTitle;
  final List<String> canvasVideoUrls; // Videos adicionales del canvas

  bool get hasVideo => videoUrl != null || canvasVideoUrls.isNotEmpty;

  String? get primaryVideoUrl => videoUrl ?? canvasVideoUrls.firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bLG,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header del card ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hasVideo ? AppTheme.borderFocus : AppTheme.surface3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smart_display_rounded,
                    size: 18,
                    color: hasVideo ? Colors.white : AppTheme.textDisabled,
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasVideo ? 'Video del Proyecto' : 'Sin Video',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        hasVideo
                            ? 'Pitch y demostración'
                            : 'Este proyecto no tiene video',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasVideo)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.borderFocus.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderFocus.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'DISPONIBLE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.borderFocus,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Contenido ──────────────────────────────────────────
          if (hasVideo) ...[
            // Video principal
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radiusMD),
              ),
              child: VideoPlayerWidget(
                videoUrl: primaryVideoUrl!,
                autoPlay: false,
                showControls: true,
                aspectRatio: 16 / 9,
              ),
            ),

            // Videos adicionales del canvas (si existen)
            if (canvasVideoUrls.length > 1) ...[
              const SizedBox(height: AppTheme.sp12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Videos Adicionales',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sp8),
                    ...canvasVideoUrls.skip(1).map(
                          (url) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.sp8),
                            child: _AdditionalVideoTile(url: url),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            // Información del video
            Padding(
              padding: const EdgeInsets.all(AppTheme.sp16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppTheme.textDisabled),
                  const SizedBox(width: AppTheme.sp6),
                  Expanded(
                    child: Text(
                      _getVideoInfo(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textDisabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Estado sin video
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.sp16, 0, AppTheme.sp16, AppTheme.sp16),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.5),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      size: 32,
                      color: AppTheme.textDisabled,
                    ),
                    SizedBox(height: AppTheme.sp8),
                    Text(
                      'Este proyecto no incluye\nvideo de demostración',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getVideoInfo() {
    if (primaryVideoUrl == null) return '';

    final url = primaryVideoUrl!.toLowerCase();
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'Video de YouTube • Toca para reproducir';
    } else if (url.contains('vimeo.com')) {
      return 'Video de Vimeo • Toca para reproducir';
    } else if (url.contains('storage.googleapis.com') ||
        url.contains('firebasestorage.googleapis.com')) {
      return 'Video almacenado • Controles nativos';
    } else {
      return 'Video externo • Toca para reproducir';
    }
  }
}

/// Tile para videos adicionales del canvas
class _AdditionalVideoTile extends StatelessWidget {
  const _AdditionalVideoTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideo(url),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.sp12),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.sp8),
            Expanded(
              child: Text(
                _getDisplayName(url),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 14, color: AppTheme.textDisabled),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Video adicional';

    final host = uri.host.replaceFirst('www.', '');
    return host.isNotEmpty ? 'Video • $host' : 'Video adicional';
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
