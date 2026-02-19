import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [Connectivity] and exposes an online-state stream and a one-shot check.
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Maps the list of [ConnectivityResult] to a single bool.
  /// Online if at least one non-none result is present.
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map((results) => _isOnline(results));

  Future<bool> checkIsOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
}

// ── Riverpod providers ────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
);

/// `true` when the device has at least one active network interface.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.read(connectivityServiceProvider).onlineStream;
});
