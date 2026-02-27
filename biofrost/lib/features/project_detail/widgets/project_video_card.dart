import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/features/project_detail/widgets/video_player_widget.dart';
import 'package:biofrost/core/config/app_config.dart';
import 'package:flutter/services.dart';

String _resolveSupabaseUrl(String url) {
  if (url.trim().isEmpty) return url;
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  var path = u;
  if (path.startsWith('/')) path = path.substring(1);
  if (path.startsWith('${AppConfig.supabaseBucket}/')) {
    path = path.substring(AppConfig.supabaseBucket.length + 1);
  }
  return AppConfig.storageUrl(path);
}

void _pushFullScreen(BuildContext context, String url, String title) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, __, ___) => _FullScreenVideoPage(
      videoUrl: url,
      tag: url,
      title: title,
    ),
  ));
}

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
            // Video principal (tap para ver full-screen)
            Hero(
              tag: primaryVideoUrl ?? projectTitle,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusMD),
                ),
                child: VideoPlayerWidget(
                  videoUrl: _resolveSupabaseUrl(primaryVideoUrl!),
                  autoPlay: false,
                  showControls: true,
                  aspectRatio: 16 / 9,
                  // Delegate heavy loading to full-screen. Inline will show
                  // placeholder and call this onTap when tapped.
                  onTap: () => _pushFullScreen(context,
                      _resolveSupabaseUrl(primaryVideoUrl!), projectTitle),
                ),
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
                  const Icon(Icons.info_outline_rounded,
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
    final resolved = _resolveSupabaseUrl(url);
    final uri = Uri.tryParse(resolved);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  const _FullScreenVideoPage(
      {required this.videoUrl, required this.tag, required this.title});

  final String videoUrl;
  final String tag;
  final String title;

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  @override
  void initState() {
    super.initState();
    // Allow both orientations until the video tells us its real ratio.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Always restore all orientations when leaving full-screen.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Called by [VideoPlayerWidget] after the video is initialized.
  /// Locks the orientation to match the video's native format.
  void _onAspectRatioResolved(double ratio) {
    if (!mounted) return;
    if (ratio < 1.0) {
      // Portrait video (e.g. 9:16 selfie/pitch recorded vertically)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Landscape video (widescreen / 16:9)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Restore orientations when the user swipes back.
      onPopInvokedWithResult: (_, __) =>
          SystemChrome.setPreferredOrientations(DeviceOrientation.values),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              SystemChrome.setPreferredOrientations(DeviceOrientation.values);
              Navigator.of(context).pop();
            },
          ),
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        ),
        // Fill the screen and let Chewie respect the native aspect ratio.
        body: Center(
          child: Hero(
            tag: widget.tag,
            child: VideoPlayerWidget(
              videoUrl: widget.videoUrl,
              autoPlay: true,
              showControls: true,
              // No fixed aspectRatio — VideoPlayerWidget will use the
              // video's native ratio once initialized.
              onAspectRatioResolved: _onAspectRatioResolved,
            ),
          ),
        ),
      ),
    );
  }
}
