import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Background handler (top-level, fuera de clase) ─────────────────────────

/// Manejador de mensajes en background — debe ser función top-level.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM-BG] Mensaje recibido: ${message.messageId}');
  // Firebase ya inicializado en este punto por el plugin.
}

// ── Canal de notificaciones Android ──────────────────────────────────────────

const _androidChannel = AndroidNotificationChannel(
  'biofrost_high_importance',
  'Biofrost — Notificaciones',
  description: 'Notificaciones de evaluaciones y actualizaciones de proyectos.',
  importance: Importance.high,
  playSound: true,
);

// ── NotificationService ───────────────────────────────────────────────────────

/// Servicio centralizado de notificaciones push.
///
/// Responsabilidades:
/// - Solicitar permisos al usuario.
/// - Registrar el token FCM en el backend/Firestore.
/// - Mostrar notificaciones locales cuando la app está en foreground.
/// - Emitir eventos de navegación al hacer tap en una notificación.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream que emite el payload de tap para navegación reactiva.
  final _tapStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _tapStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  int _badgeCount = 0;
  int get badgeCount => _badgeCount;

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Registrar handler de fondo
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar canal Android
    await _setupAndroidChannel();

    // Inicializar flutter_local_notifications
    await _initLocalNotifications();

    // Solicitar permisos
    await _requestPermissions();

    // Obtener token FCM
    _fcmToken = await _messaging.getToken();
    debugPrint('[FCM] Token: $_fcmToken');

    // Escuchar renovación de token
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('[FCM] Token renovado: $token');
    });

    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Al abrir notificación desde background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app fue abierta por notificación (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      // Android 13+ requiere permiso explícito
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ── Canal Android ─────────────────────────────────────────────────────────

  Future<void> _setupAndroidChannel() async {
    if (!Platform.isAndroid) return;
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  // ── Inicialización local notifications ────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        _onLocalNotificationTap(details.payload);
      },
    );
  }

  // ── Foreground ───────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[FCM-FG] ${message.notification?.title}: ${message.notification?.body}');

    final notification = message.notification;
    if (notification == null) return;

    // Incrementar badge counter
    _badgeCount++;

    // Mostrar notificación local (FCM no la muestra automáticamente en FG en Android)
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: _badgeCount, // Badge counter en Android
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: _badgeCount, // Badge counter en iOS
        ),
      ),
      payload: message.data['route'], // e.g. "/project/abc123"
    );
  }

  // ── Tap handlers ─────────────────────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tap en notificación: ${message.data}');
    _badgeCount = 0; // Limpiar badge al abrir la app por notificación
    _tapStreamController.add(message.data);
  }

  /// Reinicia el badge counter manualmente (e.g., al navegar al perfil).
  void clearBadge() {
    _badgeCount = 0;
  }

  void _onLocalNotificationTap(String? payload) {
    if (payload == null) return;
    _tapStreamController.add({'route': payload});
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _tapStreamController.close();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Estado de las notificaciones push.
class NotificationState {
  const NotificationState({
    this.fcmToken,
    this.permissionGranted = false,
    this.pendingRoute,
  });

  final String? fcmToken;
  final bool permissionGranted;
  final String? pendingRoute; // ruta a navegar por tap en notificación

  NotificationState copyWith({
    String? fcmToken,
    bool? permissionGranted,
    String? pendingRoute,
  }) =>
      NotificationState(
        fcmToken: fcmToken ?? this.fcmToken,
        permissionGranted: permissionGranted ?? this.permissionGranted,
        pendingRoute: pendingRoute,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _autoSubscribe();
  }

  StreamSubscription<Map<String, dynamic>>? _tapSub;

  void _autoSubscribe() {
    // NotificationService ya fue inicializado en main.dart.
    // Sólo necesitamos sincronizar el token y suscribir al stream de taps.
    state = state.copyWith(
      fcmToken: NotificationService.instance.fcmToken,
      permissionGranted: NotificationService.instance.fcmToken != null,
    );

    _tapSub = NotificationService.instance.onNotificationTap.listen((data) {
      final route = data['route'] as String?;
      if (route != null) {
        state = state.copyWith(pendingRoute: route);
      }
    });
  }

  /// Marca la ruta pendiente como consumida.
  void consumeRoute() {
    state = state.copyWith(pendingRoute: null);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
