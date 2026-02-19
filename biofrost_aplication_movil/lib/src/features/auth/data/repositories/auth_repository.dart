import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/core.dart';
import '../models/commands/login_command.dart';
import '../models/commands/register_command.dart';
import '../models/read/auth_user_read_model.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class IAuthRepository {
  /// [Command] Intercambia credenciales Firebase por perfil del backend.
  Future<AuthUserReadModel> login(LoginCommand cmd);

  /// [Command] Registra un usuario nuevo con datos extendidos.
  Future<AuthUserReadModel> register(RegisterCommand cmd);
}

// ---------------------------------------------------------------------------
// Implementation — endpoints públicos, no requieren JWT
// ---------------------------------------------------------------------------

class AuthRepository implements IAuthRepository {
  AuthRepository({String? baseUrl})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String _baseUrl;
  static const _timeout = Duration(seconds: AppConfig.httpTimeoutSeconds);

  @override
  Future<AuthUserReadModel> login(LoginCommand cmd) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cmd.toJson()),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(debugInfo: 'auth/login: ${e.toString()}');
    }
  }

  @override
  Future<AuthUserReadModel> register(RegisterCommand cmd) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cmd.toJson()),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(debugInfo: 'auth/register: ${e.toString()}');
    }
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  AuthUserReadModel _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return AuthUserReadModel.fromJson(json);
    }
    if (response.statusCode == 400) {
      throw ValidationException(
        detail: _extractMessage(body) ?? 'Datos inválidos. Revisa los campos.',
        debugInfo: body,
      );
    }
    if (response.statusCode == 401) throw const UnauthorizedException();
    if (response.statusCode == 409) {
      throw const ValidationException(
        detail: 'Este correo ya está registrado.',
        debugInfo: 'HTTP 409 Conflict',
      );
    }
    throw ServerException(debugInfo: 'HTTP ${response.statusCode}: $body');
  }

  static String? _extractMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (json['message'] ??
              json['Message'] ??
              json['error'] ??
              json['Error'])
          as String?;
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<IAuthRepository>(
  (_) => AuthRepository(),
);
