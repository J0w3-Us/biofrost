import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/core.dart';
import '../models/commands/login_command.dart';
import '../models/commands/register_command.dart';
import '../models/read/auth_user_read_model.dart';
import '../models/read/register_response.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class IAuthRepository {
  /// [Command] Intercambia credenciales Firebase por perfil del backend.
  Future<AuthUserReadModel> login(LoginCommand cmd);

  /// [Command] Registra un usuario nuevo con datos extendidos.
  Future<RegisterResponse> register(RegisterCommand cmd);
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
    print('[INFO] AuthRepository.login: STARTING login request');
    print(
      '[DEBUG] AuthRepository.login: Command data - FirebaseUid: ${cmd.firebaseUid}, Email: ${cmd.email}',
    );
    print('[DEBUG] AuthRepository.login: URL: $_baseUrl/api/auth/login');

    try {
      print('[DEBUG] AuthRepository.login: Sending HTTP POST request...');
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cmd.toJson()),
          )
          .timeout(_timeout);

      print(
        '[INFO] AuthRepository.login: HTTP response received - Status: ${response.statusCode}',
      );
      print(
        '[DEBUG] AuthRepository.login: Response body length: ${response.body.length}',
      );

      final result = _handleResponse(response);
      print(
        '[SUCCESS] AuthRepository.login: Login successful - UserId: ${result.uid}, Role: ${result.rol}',
      );
      return result;
    } on AppException catch (e) {
      print(
        '[WARN] AuthRepository.login: AppException caught - ${e.toString()}',
      );
      rethrow;
    } catch (e) {
      print('[ERROR] AuthRepository.login: Unexpected error - ${e.toString()}');
      throw NetworkException(debugInfo: 'auth/login: ${e.toString()}');
    }
  }

  @override
  Future<RegisterResponse> register(RegisterCommand cmd) async {
    print('[INFO] AuthRepository.register: STARTING register request');
    print(
      '[DEBUG] AuthRepository.register: Command data - FirebaseUid: ${cmd.firebaseUid}, Email: ${cmd.email}, Role: ${cmd.rol}',
    );
    print(
      '[DEBUG] AuthRepository.register: Personal info - Nombre: ${cmd.nombre}, ApellidoPaterno: ${cmd.apellidoPaterno}, ApellidoMaterno: ${cmd.apellidoMaterno}',
    );
    print('[DEBUG] AuthRepository.register: URL: $_baseUrl/api/auth/register');

    try {
      print('[DEBUG] AuthRepository.register: Sending HTTP POST request...');
      print(
        '[DEBUG] AuthRepository.register: Request payload: ${jsonEncode(cmd.toJson())}',
      );

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cmd.toJson()),
          )
          .timeout(_timeout);

      print(
        '[INFO] AuthRepository.register: HTTP response received - Status: ${response.statusCode}',
      );
      print('[DEBUG] AuthRepository.register: Response body: ${response.body}');

      final result = _handleRegisterResponse(response);
      print(
        '[SUCCESS] AuthRepository.register: Registration successful - Success: ${result.success}, UserId: ${result.userId}',
      );
      return result;
    } on AppException catch (e) {
      print(
        '[WARN] AuthRepository.register: AppException caught - ${e.toString()}',
      );
      rethrow;
    } catch (e) {
      print(
        '[ERROR] AuthRepository.register: Unexpected error - ${e.toString()}',
      );
      throw NetworkException(debugInfo: 'auth/register: ${e.toString()}');
    }
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  AuthUserReadModel _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    print(
      '[DEBUG] AuthRepository._handleResponse: Processing response - Status: ${response.statusCode}',
    );
    print(
      '[DEBUG] AuthRepository._handleResponse: Body preview: ${body.length > 200 ? body.substring(0, 200) + '...' : body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(
        '[DEBUG] AuthRepository._handleResponse: Success response, parsing JSON...',
      );
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = AuthUserReadModel.fromJson(json);
      print(
        '[DEBUG] AuthRepository._handleResponse: Parsed AuthUserReadModel - UID: ${result.uid}, Role: ${result.rol}',
      );
      return result;
    }
    if (response.statusCode == 400) {
      print('[WARN] AuthRepository._handleResponse: Bad request (400)');
      throw ValidationException(
        detail: _extractMessage(body) ?? 'Datos inválidos. Revisa los campos.',
        debugInfo: body,
      );
    }
    if (response.statusCode == 401) {
      print('[WARN] AuthRepository._handleResponse: Unauthorized (401)');
      throw const UnauthorizedException();
    }
    if (response.statusCode == 409) {
      print(
        '[WARN] AuthRepository._handleResponse: Conflict (409) - Email already registered',
      );
      throw const ValidationException(
        detail: 'Este correo ya está registrado.',
        debugInfo: 'HTTP 409 Conflict',
      );
    }
    print(
      '[ERROR] AuthRepository._handleResponse: Unexpected status code: ${response.statusCode}',
    );
    throw ServerException(debugInfo: 'HTTP ${response.statusCode}: $body');
  }

  RegisterResponse _handleRegisterResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    print(
      '[DEBUG] AuthRepository._handleRegisterResponse: Processing register response - Status: ${response.statusCode}',
    );
    print('[DEBUG] AuthRepository._handleRegisterResponse: Body: $body');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(
        '[DEBUG] AuthRepository._handleRegisterResponse: Success response, parsing JSON...',
      );
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = RegisterResponse.fromJson(json);
      print(
        '[DEBUG] AuthRepository._handleRegisterResponse: Parsed RegisterResponse - Success: ${result.success}, UserId: ${result.userId}',
      );
      return result;
    }
    if (response.statusCode == 400) {
      print('[WARN] AuthRepository._handleRegisterResponse: Bad request (400)');
      throw ValidationException(
        detail: _extractMessage(body) ?? 'Datos inválidos. Revisa los campos.',
        debugInfo: body,
      );
    }
    if (response.statusCode == 401) {
      print(
        '[WARN] AuthRepository._handleRegisterResponse: Unauthorized (401)',
      );
      throw const UnauthorizedException();
    }
    if (response.statusCode == 409) {
      print(
        '[WARN] AuthRepository._handleRegisterResponse: Conflict (409) - Email already registered',
      );
      throw const ValidationException(
        detail: 'Este correo ya está registrado.',
        debugInfo: 'HTTP 409 Conflict',
      );
    }
    print(
      '[ERROR] AuthRepository._handleRegisterResponse: Unexpected status code: ${response.statusCode}',
    );
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
