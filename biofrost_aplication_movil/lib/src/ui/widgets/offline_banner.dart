import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/connectivity_service.dart';
import '../../core/offline/sync_queue_service.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_text_styles.dart';

/// Global offline indicator.
///
/// Wrap the root [MaterialApp]'s `builder` child with this widget so the banner
/// appears above every page when the device loses connectivity.
///
/// Usage in MaterialApp:
/// ```dart
/// builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
/// ```
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  /// Tracks whether we just came back online (to show the "Sincronizado" flash).
  bool _wasOffline = false;
  bool _showReconnected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleOnlineChange(bool isOnline) {
    if (!isOnline) {
      _wasOffline = true;
      _controller.forward();
    } else {
      _controller.reverse();
      if (_wasOffline) {
        _wasOffline = false;
        setState(() => _showReconnected = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showReconnected = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(syncQueueNotifierProvider);

    onlineAsync.whenData(_handleOnlineChange);

    final pendingCount = pendingCountAsync.valueOrNull ?? 0;

    return Stack(
      children: [
        widget.child,
        // ── Offline banner ─────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: AppColors.warningBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pendingCount > 0
                              ? 'Sin conexión · $pendingCount cambio(s) pendiente(s)'
                              : 'Sin conexión · Modo offline',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Reconnected flash ──────────────────────────────────────────────
        if (_showReconnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: AppColors.successBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Conexión restaurada',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
