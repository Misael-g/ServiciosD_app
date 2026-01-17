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
      print('🟢 [AUTH_REPO] Iniciando proceso de registro');
      print('   Email: $email');
      print('   Nombre: $fullName');
      print('   Rol: $role');

      // PASO 1: Registrar usuario en Supabase Auth
      print('🟢 [AUTH_REPO] PASO 1: Registrando en Supabase Auth...');
      await _authDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      print('✅ [AUTH_REPO] Usuario registrado en Auth');

      // PASO 2: Esperar a que el trigger cree el perfil
      print('🟢 [AUTH_REPO] PASO 2: Esperando creación del perfil (trigger)...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('   Esperando 500ms más...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('   Esperando 500ms más...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('   Esperando 500ms más...');
      await Future.delayed(const Duration(milliseconds: 500));

      // PASO 3: Intentar obtener el perfil creado
      print('🟢 [AUTH_REPO] PASO 3: Intentando obtener perfil...');
      
      int attempts = 0;
      const maxAttempts = 5;
      
      while (attempts < maxAttempts) {
        attempts++;
        print('   Intento $attempts/$maxAttempts');
        
        try {
          final profileModel = await _profilesDataSource.getCurrentUserProfile();
          print('✅ [AUTH_REPO] ¡Perfil obtenido exitosamente!');
          print('   ID: ${profileModel.id}');
          print('   Email: ${profileModel.email}');
          print('   Rol: ${profileModel.role}');
          
          return profileModel.toEntity();
          
        } catch (e) {
          print('⚠️ [AUTH_REPO] Intento $attempts falló: $e');
          
          if (attempts < maxAttempts) {
            print('   Esperando 1 segundo antes del siguiente intento...');
            await Future.delayed(const Duration(seconds: 1));
          } else {
            print('❌ [AUTH_REPO] Todos los intentos fallaron');
            rethrow;
          }
        }
      }

      throw Exception('No se pudo obtener el perfil después de $maxAttempts intentos');
      
    } catch (e, stackTrace) {
      print('❌ [AUTH_REPO] Error en signUp:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al registrar usuario: $e');
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