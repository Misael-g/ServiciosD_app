import '../entities/profile.dart';

/// Repositorio de autenticación (interfaz)
/// Define el contrato que debe cumplir la implementación
abstract class AuthRepository {
  /// Registrar nuevo usuario
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    List<String>? specialties, // 🆕 AGREGAR
  });

  /// Iniciar sesión
  Future<Profile> signIn({
    required String email,
    required String password,
  });

  /// Cerrar sesión
  Future<void> signOut();

  /// Obtener perfil del usuario actual
  Future<Profile?> getCurrentUserProfile();

  /// Verificar si hay un usuario autenticado
  bool isAuthenticated();

  /// Recuperar contraseña
  Future<void> resetPassword(String email);

  /// Actualizar contraseña
  Future<void> updatePassword(String newPassword);

  /// Actualizar email
  Future<void> updateEmail(String newEmail);
}