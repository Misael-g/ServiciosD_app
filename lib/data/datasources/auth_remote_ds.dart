import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Fuente de datos remota para autenticación
class AuthRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Registrar nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone, 
    List<String>? specialties, // 🆕 AGREGAR
  }) async {
    try {
      print('🔵 [AUTH_DS] Iniciando registro...');
      print('   Email: $email');
      print('   Nombre: $fullName');
      print('   Rol: $role');
      print('   Teléfono: ${phone ?? "no proporcionado"}'); // ← AGREGADO
      if (specialties != null) {
        print('   Especialidades: $specialties');
      }

      // Validar que el rol no sea admin
      if (role == 'admin') {
        print('❌ [AUTH_DS] Intento de registro como admin');
        throw Exception('No puedes registrarte como administrador');
      }

      print('🔵 [AUTH_DS] Llamando a Supabase signUp...');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          if (phone != null && phone.isNotEmpty) 'phone': phone, // ← AGREGADO
          if (specialties != null && specialties.isNotEmpty) // 🆕 AGREGAR
            'specialties': specialties,
        },
      );

      print('🔵 [AUTH_DS] Respuesta de Supabase recibida');
      print('   User ID: ${response.user?.id}');
      print('   Email: ${response.user?.email}');
      print('   Session: ${response.session != null ? "Existe" : "null"}');

      if (response.user == null) {
        print('❌ [AUTH_DS] Usuario es null en la respuesta');
        throw Exception('Error al crear usuario - respuesta sin usuario');
      }

      print('✅ [AUTH_DS] Usuario creado exitosamente');
      print('   ID: ${response.user!.id}');
      
      return response;
      
    } on AuthException catch (e) {
      print('❌ [AUTH_DS] AuthException capturada:');
      print('   Mensaje: ${e.message}');
      print('   StatusCode: ${e.statusCode}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [AUTH_DS] Error general capturado:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Iniciar sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [AUTH_DS] Iniciando sesión...');
      print('   Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ [AUTH_DS] Sesión iniciada exitosamente');
      print('   User ID: ${response.user?.id}');

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      return response;
      
    } on AuthException catch (e) {
      print('❌ [AUTH_DS] Error al iniciar sesión:');
      print('   ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [AUTH_DS] Error general al iniciar sesión: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      print('🔵 [AUTH_DS] Cerrando sesión...');
      await _supabase.auth.signOut();
      print('✅ [AUTH_DS] Sesión cerrada');
    } catch (e) {
      print('❌ [AUTH_DS] Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtener usuario actual
  User? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    print('🔵 [AUTH_DS] Usuario actual: ${user?.id ?? "null"}');
    return user;
  }

  /// Verificar si hay un usuario autenticado
  bool isAuthenticated() {
    final isAuth = _supabase.auth.currentUser != null;
    print('🔵 [AUTH_DS] ¿Autenticado?: $isAuth');
    return isAuth;
  }

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      print('🔵 [AUTH_DS] Recuperando contraseña para: $email');
      await _supabase.auth.resetPasswordForEmail(email);
      print('✅ [AUTH_DS] Email de recuperación enviado');
    } on AuthException catch (e) {
      print('❌ [AUTH_DS] Error al recuperar contraseña: ${e.message}');
      rethrow;
    }
  }

  /// Actualizar contraseña
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      print('🔵 [AUTH_DS] Actualizando contraseña...');
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Error al actualizar contraseña');
      }

      print('✅ [AUTH_DS] Contraseña actualizada');
      return response;
    } on AuthException catch (e) {
      print('❌ [AUTH_DS] Error al actualizar contraseña: ${e.message}');
      rethrow;
    }
  }

  /// Actualizar email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      print('🔵 [AUTH_DS] Actualizando email a: $newEmail');
      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (response.user == null) {
        throw Exception('Error al actualizar email');
      }

      print('✅ [AUTH_DS] Email actualizado');
      return response;
    } on AuthException catch (e) {
      print('❌ [AUTH_DS] Error al actualizar email: ${e.message}');
      rethrow;
    }
  }
}