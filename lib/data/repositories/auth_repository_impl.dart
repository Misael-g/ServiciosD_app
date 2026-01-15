import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';
import '../datasources/profiles_remote_ds.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final ProfilesRemoteDataSource _profilesDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required ProfilesRemoteDataSource profilesDataSource,
  })  : _authDataSource = authDataSource,
        _profilesDataSource = profilesDataSource;

  @override
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      // Registrar usuario en Supabase Auth
      // El trigger creará automáticamente el perfil
      await _authDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      // Esperar un momento para que se cree el perfil
      await Future.delayed(const Duration(seconds: 1));

      // Obtener el perfil creado
      final profileModel = await _profilesDataSource.getCurrentUserProfile();
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  @override
  Future<Profile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Iniciar sesión
      await _authDataSource.signIn(
        email: email,
        password: password,
      );

      // Obtener perfil del usuario
      final profileModel = await _profilesDataSource.getCurrentUserProfile();
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authDataSource.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<Profile?> getCurrentUserProfile() async {
    try {
      if (!_authDataSource.isAuthenticated()) {
        return null;
      }

      final profileModel = await _profilesDataSource.getCurrentUserProfile();
      return profileModel.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  bool isAuthenticated() {
    return _authDataSource.isAuthenticated();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _authDataSource.resetPassword(email);
    } catch (e) {
      throw Exception('Error al recuperar contraseña: $e');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authDataSource.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _authDataSource.updateEmail(newEmail);
    } catch (e) {
      throw Exception('Error al actualizar email: $e');
    }
  }
}