import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:biofrost/core/theme/app_theme.dart';

/// Widget reproductor de video nativo para proyectos.
///
/// Soporta:
/// - Videos directos (.mp4, .webm, .mov)
/// - YouTube URLs (usando webview/externa)
/// - Controles de reproducción completos
/// - Pantalla completa
/// - Estados de carga y error
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.placeholder,
  });

  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final double aspectRatio;
  final Widget? placeholder;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Detectar si es video directo o enlace externo
      if (_isDirectVideoUrl(widget.videoUrl)) {
        await _initializeDirectVideo();
      } else {
        // Para YouTube/Vimeo, mostrar botón para abrir externamente
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el video: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDirectVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: widget.autoPlay,
      looping: false,
      showControls: widget.showControls,
      aspectRatio: widget.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControlsOnInitialize: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppTheme.borderFocus,
        handleColor: AppTheme.borderFocus,
        backgroundColor: AppTheme.surface3,
        bufferedColor: AppTheme.surface3,
      ),
      placeholder: widget.placeholder ?? _buildPlaceholder(),
      errorBuilder: (context, errorMessage) => _buildError(errorMessage),
    );

    setState(() {
      _isLoading = false;
    });
  }

  bool _isDirectVideoUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final path = uri.path.toLowerCase();
    final directVideoExtensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv'];

    return directVideoExtensions.any((ext) => path.endsWith(ext)) ||
        uri.host.contains('storage.googleapis.com') ||
        uri.host.contains('firebasestorage.googleapis.com');
  }

  bool _isYouTubeUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('youtube.com') || u.contains('youtu.be');
  }

  bool _isVimeoUrl(String url) {
    return url.toLowerCase().contains('vimeo.com');
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface2, Color(0xFF1A1A1A)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.textDisabled,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Error al cargar video',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeVideo,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalVideoCard() {
    IconData icon = Icons.play_circle_outline_rounded;
    String platform = 'Video';

    if (_isYouTubeUrl(widget.videoUrl)) {
      icon = Icons.smart_display_outlined;
      platform = 'YouTube';
    } else if (_isVimeoUrl(widget.videoUrl)) {
      icon = Icons.videocam_rounded;
      platform = 'Vimeo';
    }

    return GestureDetector(
      onTap: () => _openExternalVideo(),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: AppTheme.bMD,
          border: Border.all(color: AppTheme.border),
        ),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.surface2, Color(0xFF1A1A1A)],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ver en $platform',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Externo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExternalVideo() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null) {
      // Usar URL launcher para abrir en navegador/app externa
      try {
        final url = Uri.parse(widget.videoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // Fallback silencioso
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            borderRadius: AppTheme.bMD,
            border: Border.all(color: AppTheme.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: _buildError(_error!),
      );
    }

    // Si es video directo y está inicializado
    if (_chewieController != null) {
      return ClipRRect(
        borderRadius: AppTheme.bMD,
        child: Chewie(controller: _chewieController!),
      );
    }

    // Para videos externos (YouTube/Vimeo)
    return _buildExternalVideoCard();
  }
}
