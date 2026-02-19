import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../storage/data/models/commands/upload_file_command.dart';
import '../../../storage/data/repositories/storage_repository.dart';
import '../models/commands/update_profile_command.dart';

// Implementa RF-Profile-01: Lectura y edición del perfil de usuario.
// Implementa RF-Profile-02: Upload de avatar desde cámara/galería.

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class IProfileRepository {
  /// Retorna el [AppUser] actual desde la sesión persistida.
  Future<AppUser?> getProfile();

  /// Sube una nueva imagen de avatar al servidor.
  /// Retorna la URL pública del archivo subido.
  Future<String> uploadAvatar({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  });

  /// Actualiza nombre y apellidos en Firebase Auth + sesión local.
  /// Retorna el [AppUser] actualizado.
  Future<AppUser> updateProfile(
    UpdateProfileCommand command, {
    required AppUser current,
  });

  /// Persiste el [AppUser] actualizado en la sesión local.
  Future<AppUser> saveUserLocally(AppUser user);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ProfileRepository implements IProfileRepository {
  ProfileRepository({
    required SessionService session,
    required IStorageRepository storageRepo,
    fb.FirebaseAuth? firebaseAuth,
  }) : _session = session,
       _storage = storageRepo,
       _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final SessionService _session;
  final IStorageRepository _storage;
  final fb.FirebaseAuth _firebaseAuth;

  @override
  Future<AppUser?> getProfile() => _session.getUser();

  // RF-Profile-02: subir avatar —— carpeta fija "avatars"
  @override
  Future<String> uploadAvatar({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    // Leer bytes antes de delegar al repositorio de storage
    final bytes = await File(filePath).length(); // solo para tamaño correcto
    final cmd = UploadFileCommand(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes,
      folder: 'avatars',
    );
    final uploaded = await _storage.uploadSingle(cmd);
    // Actualizar también Firebase Auth photoURL
    await _firebaseAuth.currentUser?.updatePhotoURL(uploaded.url);
    return uploaded.url;
  }

  // RF-Profile-01: actualizar nombre en Firebase Auth + sesión local
  @override
  Future<AppUser> updateProfile(
    UpdateProfileCommand command, {
    required AppUser current,
  }) async {
    // Actualizar displayName en Firebase Auth
    await _firebaseAuth.currentUser?.updateDisplayName(command.displayName);

    final updated = current.copyWith(
      nombre: command.nombre.trim(),
      apellidoPaterno: command.apellidoPaterno.trim(),
      apellidoMaterno: command.apellidoMaterno.trim(),
    );
    await _session.saveUser(updated);
    return updated;
  }

  @override
  Future<AppUser> saveUserLocally(AppUser user) async {
    await _session.saveUser(user);
    return user;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository(
    session: ref.read(sessionServiceProvider),
    storageRepo: ref.read(storageRepositoryProvider),
  );
});
