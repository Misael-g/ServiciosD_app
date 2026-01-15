import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Fuente de datos remota para autenticación
class AuthRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Registrar nuevo usuario
  /// 
  /// [email] - Email del usuario
  /// [password] - Contraseña
  /// [fullName] - Nombre completo
  /// [role] - Rol del usuario ('client' o 'technician')
  /// 
  /// El rol se pasa en los metadatos y el trigger en Supabase
  /// crea automáticamente el perfil con validación
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role, // El trigger validará que no sea 'admin'
        },
      );

      if (response.user == null) {
        throw Exception('Error al crear usuario');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Iniciar sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtener usuario actual
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Verificar si hay un usuario autenticado
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Error al recuperar contraseña: ${e.message}');
    } catch (e) {
      throw Exception('Error al recuperar contraseña: $e');
    }
  }

  /// Actualizar contraseña
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Error al actualizar contraseña');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Error al actualizar contraseña: ${e.message}');
    } catch (e) {
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  /// Actualizar email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (response.user == null) {
        throw Exception('Error al actualizar email');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Error al actualizar email: ${e.message}');
    } catch (e) {
      throw Exception('Error al actualizar email: $e');
    }
  }
}