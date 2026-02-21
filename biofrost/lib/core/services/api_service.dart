import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../errors/app_exceptions.dart';

/// Cliente HTTP centralizado basado en Dio.
///
/// Responsabilidades:
/// 1. Adjunta Bearer token de Firebase en cada request autenticado.
/// 2. Normaliza errores HTTP a [AppException] del dominio.
/// 3. Log estructurado de requests/responses para debugging.
///
/// Patrón: Singleton instanciado por el provider de Riverpod.
class ApiService {
  ApiService({
    required FirebaseAuth auth,
    Logger? logger,
  })  : _auth = auth,
        _logger = logger ?? Logger() {
    _init();
  }

  final FirebaseAuth _auth;
  final Logger _logger;
  late final Dio _dio;

  // ── Inicialización ─────────────────────────────────────────────────

  void _init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(auth: _auth, logger: _logger),
      _ErrorInterceptor(logger: _logger),
      if (_isDev) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  static const bool _isDev = true; // TODO: tie to BuildConfig / --dart-define

  // ── HTTP Methods ───────────────────────────────────────────────────

  /// GET — CQRS Query (lectura de datos).
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    bool authenticated = true,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParams,
      options: Options(extra: {'authenticated': authenticated}),
    );
  }

  /// POST — CQRS Command (escritura).
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(extra: {'authenticated': authenticated}),
    );
  }

  /// PATCH — CQRS Command (actualización parcial).
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      options: Options(extra: {'authenticated': authenticated}),
    );
  }

  /// PUT — CQRS Command (reemplazo completo).
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      options: Options(extra: {'authenticated': authenticated}),
    );
  }

  /// DELETE — CQRS Command (eliminación).
  Future<Response<T>> delete<T>(
    String path, {
    bool authenticated = true,
  }) async {
    return _dio.delete<T>(
      path,
      options: Options(extra: {'authenticated': authenticated}),
    );
  }
}

// ── Interceptor: Auth Bearer Token ────────────────────────────────────

/// Adjunta el Firebase ID Token (JWT) en cada request que requiera auth.
/// Si el token no está disponible (sesión cerrada), propaga [AuthException].
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.auth, required this.logger});

  final FirebaseAuth auth;
  final Logger logger;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthenticated = options.extra['authenticated'] as bool? ?? true;

    if (!isAuthenticated) {
      return handler.next(options);
    }

    try {
      final user = auth.currentUser;
      if (user == null) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: const AuthException(
              message: 'No hay sesión activa. Inicia sesión.',
            ),
            type: DioExceptionType.cancel,
          ),
        );
      }

      // Obtiene un token fresco (Firebase renueva automáticamente si expira).
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
      logger.d('[Auth] Token adjuntado para ${options.uri}');
      handler.next(options);
    } catch (e) {
      logger.e('[Auth] Error obteniendo token', error: e);
      handler.reject(
        DioException(
          requestOptions: options,
          error: const AuthException(),
          type: DioExceptionType.cancel,
        ),
      );
    }
  }
}

// ── Interceptor: Error → AppException ─────────────────────────────────

/// Traduce [DioException] a [AppException] del dominio.
/// Mapeo según código HTTP y tipo de error de Dio.
class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor({required this.logger});

  final Logger logger;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      '[API Error] ${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err.error,
    );

    // Si ya es una AppException (del AuthInterceptor), la propaga directamente.
    if (err.error is AppException) {
      return handler.next(err);
    }

    final appException = _mapToAppException(err);
    handler.reject(
      err.copyWith(error: appException),
    );
  }

  AppException _mapToAppException(DioException err) {
    switch (err.type) {
      // Errores de conectividad
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Tiempo de espera agotado. Verifica tu conexión.',
        );

      // Respuesta HTTP con código de error
      case DioExceptionType.badResponse:
        return _mapHttpError(err.response);

      // Cancelación (normalmente del AuthInterceptor)
      case DioExceptionType.cancel:
        if (err.error is AppException) return err.error as AppException;
        return const CancelledException();

      default:
        return const NetworkException();
    }
  }

  AppException _mapHttpError(Response? response) {
    if (response == null) return const ServerException();

    final code = response.statusCode?.toString();
    final message = _extractMessage(response.data);

    switch (response.statusCode) {
      case 400:
        return BusinessException(
          message ?? 'Solicitud inválida.',
          code: code,
        );
      case 401:
        return AuthException(
          message: message ?? 'Sesión expirada. Inicia sesión nuevamente.',
          code: code,
        );
      case 403:
        return ForbiddenException(
          message: message ?? 'Acceso no autorizado.',
          code: code,
        );
      case 404:
        return NotFoundException(
          message: message ?? 'El recurso no fue encontrado.',
          code: code,
        );
      case 409:
        return BusinessException(
          message ?? 'Conflicto: el recurso ya existe.',
          code: code,
        );
      default:
        return ServerException(
          message: message ?? 'Error del servidor.',
          code: code,
        );
    }
  }

  /// Extrae el mensaje legible del body de respuesta del backend .NET.
  /// El backend puede devolver { "message": "..." } o { "detail": "..." }.
  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['detail'] as String? ??
          data['title'] as String?;
    }
    return null;
  }
}
