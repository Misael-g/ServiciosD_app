import 'package:supabase_flutter/supabase_flutter.dart';
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
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      print('🟢 [AUTH_REPO] Iniciando proceso de registro');
      print('   Email: $email');
      print('   Nombre: $fullName');
      print('   Rol: $role');
      print('   Teléfono: ${phone ?? "no proporcionado"}');
      
      // NUEVO: Verificar si el email ya existe
      try {
        final existingUsers = await _profilesDataSource.getProfileByEmail(email);
        if (existingUsers != null) {
          print('❌ [AUTH_REPO] Email ya registrado');
          throw Exception('Este email ya está registrado');
        }
      } catch (e) {
        // Si es error de "no encontrado", está bien (el email no existe)
        if (!e.toString().contains('no encontrado') && 
            !e.toString().contains('not found')) {
          // Si es el error de "ya registrado", relanzar
          if (e.toString().contains('ya está registrado')) {
            rethrow;
          }
        }
      }
      
      print('🔵 [AUTH_REPO] Email disponible, procediendo con registro...');
      
      // Crear usuario en Supabase Auth
      final response = await _authDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone, // ← Asegurarse de pasar phone
      );

      print('✅ [AUTH_REPO] Usuario registrado exitosamente');
      print('   ID: ${response.user?.id}');

    } on AuthException catch (e) {
      print('❌ [AUTH_REPO] AuthException: ${e.message}');
      
      // Mejorar mensajes de error de Supabase
      if (e.message.contains('already registered') || 
          e.message.contains('already been registered')) {
        throw Exception('Este email ya está registrado');
      } else if (e.message.contains('Invalid email')) {
        throw Exception('Email inválido');
      } else if (e.message.contains('password')) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      print('❌ [AUTH_REPO] Error: $e');
      rethrow;
    }
  }

  @override
  Future<Profile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🟢 [AUTH_REPO] Iniciando sesión');
      print('   Email: $email');
      
      // Iniciar sesión
      await _authDataSource.signIn(
        email: email,
        password: password,
      );
      print('✅ [AUTH_REPO] Sesión iniciada en Auth');

      // Obtener perfil del usuario
      print('🟢 [AUTH_REPO] Obteniendo perfil...');
      final profileModel = await _profilesDataSource.getCurrentUserProfile();
      
      print('✅ [AUTH_REPO] Inicio de sesión completo');
      print('   Rol: ${profileModel.role}');
      
      return profileModel.toEntity();
      
    } catch (e, stackTrace) {
      print('❌ [AUTH_REPO] Error al iniciar sesión:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      print('🟢 [AUTH_REPO] Cerrando sesión...');
      await _authDataSource.signOut();
      print('✅ [AUTH_REPO] Sesión cerrada');
    } catch (e) {
      print('❌ [AUTH_REPO] Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<Profile?> getCurrentUserProfile() async {
    try {
      print('🟢 [AUTH_REPO] Obteniendo perfil del usuario actual...');
      
      if (!_authDataSource.isAuthenticated()) {
        print('⚠️ [AUTH_REPO] No hay usuario autenticado');
        return null;
      }

      final profileModel = await _profilesDataSource.getCurrentUserProfile();
      print('✅ [AUTH_REPO] Perfil obtenido');
      
      return profileModel.toEntity();
      
    } catch (e) {
      print('❌ [AUTH_REPO] Error al obtener perfil actual: $e');
      return null;
    }
  }

  @override
  bool isAuthenticated() {
    final isAuth = _authDataSource.isAuthenticated();
    print('🟢 [AUTH_REPO] ¿Autenticado?: $isAuth');
    return isAuth;
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      print('🟢 [AUTH_REPO] Recuperando contraseña: $email');
      await _authDataSource.resetPassword(email);
      print('✅ [AUTH_REPO] Email de recuperación enviado');
    } catch (e) {
      print('❌ [AUTH_REPO] Error al recuperar contraseña: $e');
      throw Exception('Error al recuperar contraseña: $e');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      print('🟢 [AUTH_REPO] Actualizando contraseña...');
      await _authDataSource.updatePassword(newPassword);
      print('✅ [AUTH_REPO] Contraseña actualizada');
    } catch (e) {
      print('❌ [AUTH_REPO] Error al actualizar contraseña: $e');
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      print('🟢 [AUTH_REPO] Actualizando email...');
      await _authDataSource.updateEmail(newEmail);
      print('✅ [AUTH_REPO] Email actualizado');
    } catch (e) {
      print('❌ [AUTH_REPO] Error al actualizar email: $e');
      throw Exception('Error al actualizar email: $e');
    }
  }
}