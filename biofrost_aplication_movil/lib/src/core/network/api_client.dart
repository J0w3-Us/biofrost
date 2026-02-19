import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../session/session_service.dart';

/// Cliente HTTP centralizado para todas las peticiones al backend .NET.
///
/// Responsabilidades:
/// - Inyectar `Authorization: Bearer <token>` en cada petición.
/// - Traducir status codes HTTP a [AppException]s tipadas.
/// - Log de peticiones y errores (solo en debug).
/// - Timeout configurable via [AppConfig.httpTimeoutSeconds].
class ApiClient {
  ApiClient({required SessionService sessionService, String? baseUrl})
    : _session = sessionService,
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final SessionService _session;
  final String _baseUrl;
  final _log = Logger();
  final _inner = http.Client();

  // -------------------------------------------------------------------------
  // Métodos públicos
  // -------------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    final headers = await _headers();
    _log.d('[GET] $uri');
    final res = await _inner
        .get(uri, headers: headers)
        .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
    return _handle(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = _uri(path, null);
    final headers = await _headers();
    _log.d('[POST] $uri');
    final res = await _inner
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
    return _handle(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = _uri(path, null);
    final headers = await _headers();
    _log.d('[PUT] $uri');
    final res = await _inner
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
    return _handle(res);
  }

  Future<void> delete(String path) async {
    final uri = _uri(path, null);
    final headers = await _headers();
    _log.d('[DELETE] $uri');
    final res = await _inner
        .delete(uri, headers: headers)
        .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
    _handle(res);
  }

  /// Multipart upload — usado por Storage module.
  Future<dynamic> uploadFile(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    String? folder,
  }) async {
    final uri = _uri(path, folder != null ? {'folder': folder} : null);
    final token = await _session.getToken();
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${token ?? ""}'
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: filename),
      );
    if (folder != null) req.fields['folder'] = folder;
    _log.d('[UPLOAD] $uri — $filename');
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  void dispose() => _inner.close();

  // -------------------------------------------------------------------------
  // Helpers privados
  // -------------------------------------------------------------------------

  Uri _uri(String path, Map<String, String>? query) {
    final base = Uri.parse(_baseUrl);
    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _session.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Parsea la respuesta y lanza [AppException] según el status code.
  dynamic _handle(http.Response res) {
    _log.d('[${res.statusCode}] ${res.request?.url}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body; // respuesta no-JSON (e.g. plain text)
      }
    }

    final body = res.body.isNotEmpty ? res.body : '(empty)';
    _log.w('HTTP ${res.statusCode} — ${res.request?.url}\n$body');

    switch (res.statusCode) {
      case 400:
        throw ValidationException(
          detail: _extractMessage(res.body, fallback: 'Datos inválidos.'),
          debugInfo: body,
        );
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw NotFoundException(
          resource: res.request?.url.path ?? 'recurso',
          debugInfo: body,
        );
      case >= 500:
        throw ServerException(debugInfo: body);
      default:
        throw UnknownException(debugInfo: 'HTTP ${res.statusCode}: $body');
    }
  }

  String _extractMessage(String body, {required String fallback}) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        return (json['message'] ?? json['Message'] ?? json['title'] ?? fallback)
            .toString();
      }
    } catch (_) {}
    return fallback;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.read(sessionServiceProvider);
  final client = ApiClient(sessionService: session);
  ref.onDispose(client.dispose);
  return client;
});
