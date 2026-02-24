import 'package:flutter/material.dart';

import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/features/project_detail/widgets/video_player_widget.dart';

/// Tarjeta de video pitch mejorada con reproductor nativo
class VideoPitchCard extends StatelessWidget {
  const VideoPitchCard({
    super.key,
    required this.url,
  });

  final String url;

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
          // ── Reproductor de video nativo ─────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusMD),
            ),
            child: VideoPlayerWidget(
              videoUrl: url,
              autoPlay: false,
              showControls: true,
              aspectRatio: 16 / 9,
            ),
          ),
          // ── Pie de card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.sp14, AppTheme.sp12, AppTheme.sp14, AppTheme.sp14),
            child: Row(
              children: [
                const Icon(Icons.videocam_rounded,
                    size: 16, color: AppTheme.textDisabled),
                const SizedBox(width: AppTheme.sp8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video Pitch',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _displayUrl(url),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppTheme.textDisabled,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper para mostrar URL limpia
String _displayUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return rawUrl;
  final host = uri.host.replaceFirst('www.', '');
  return host.isNotEmpty ? host : rawUrl;
}
