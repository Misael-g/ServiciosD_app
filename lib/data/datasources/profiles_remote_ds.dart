import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/profile_model.dart';

/// Fuente de datos remota para perfiles de usuarios
class ProfilesRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Obtener perfil por ID
  Future<ProfileModel> getProfileById(String userId) async {
    try {
      print('🔵 [PROFILES_DS] Obteniendo perfil por ID: $userId');
      
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      print('✅ [PROFILES_DS] Perfil obtenido exitosamente');
      print('   ID: ${response['id']}');
      print('   Email: ${response['email']}');
      print('   Rol: ${response['role']}');

      return ProfileModel.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al obtener perfil:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Obtener perfil del usuario actual
  Future<ProfileModel> getCurrentUserProfile() async {
    final userId = SupabaseConfig.currentUserId;
    
    print('🔵 [PROFILES_DS] Obteniendo perfil del usuario actual');
    print('   User ID: ${userId ?? "null"}');
    
    if (userId == null) {
      print('❌ [PROFILES_DS] No hay usuario autenticado');
      throw Exception('No hay usuario autenticado');
    }

    return getProfileById(userId);
  }

  /// Actualizar perfil
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      print('🔵 [PROFILES_DS] Actualizando perfil: ${profile.id}');
      
      final data = profile.toJson();
      // Remover campos que no deben actualizarse
      data.remove('id');
      data.remove('email');
      data.remove('created_at');
      data.remove('role');

      print('   Datos a actualizar: ${data.keys.join(", ")}');

      final response = await _supabase
          .from('profiles')
          .update(data)
          .eq('id', profile.id)
          .select()
          .single();

      print('✅ [PROFILES_DS] Perfil actualizado');
      return ProfileModel.fromJson(response);
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al actualizar perfil:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Actualizar solo campos específicos del perfil
  Future<ProfileModel> updateProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('🔵 [PROFILES_DS] Actualizando campos del perfil: $userId');
      print('   Campos: ${fields.keys.join(", ")}');
      
      // Asegurar que no se actualice el rol
      fields.remove('role');
      fields.remove('id');
      fields.remove('email');

      final response = await _supabase
          .from('profiles')
          .update(fields)
          .eq('id', userId)
          .select()
          .single();

      print('✅ [PROFILES_DS] Campos actualizados');
      return ProfileModel.fromJson(response);
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al actualizar campos:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al actualizar campos del perfil: $e');
    }
  }

  /// Actualizar foto de perfil
  Future<ProfileModel> updateProfilePicture(
    String userId,
    String imageUrl,
  ) async {
    print('🔵 [PROFILES_DS] Actualizando foto de perfil: $userId');
    return updateProfileFields(userId, {'profile_picture_url': imageUrl});
  }

  /// Actualizar ubicación del perfil
  Future<ProfileModel> updateLocation(
    String userId, {
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    print('🔵 [PROFILES_DS] Actualizando ubicación: $userId');
    print('   Lat: $latitude, Lon: $longitude');
    
    final fields = <String, dynamic>{
      'location': 'POINT($longitude $latitude)',
    };

    if (address != null) {
      fields['address'] = address;
    }

    return updateProfileFields(userId, fields);
  }

  /// Obtener técnicos cercanos
  Future<List<ProfileModel>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      print('🔵 [PROFILES_DS] Buscando técnicos cercanos');
      print('   Tipo: $serviceType');
      print('   Radio: $radiusMeters m');
      
      final response = await _supabase.rpc(
        'get_nearby_technicians',
        params: {
          'client_location': 'POINT($longitude $latitude)',
          'service_type': serviceType,
          'radius_meters': radiusMeters,
        },
      );

      if (response == null) {
        print('⚠️ [PROFILES_DS] Respuesta null de RPC');
        return [];
      }

      final technicians = (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [PROFILES_DS] ${technicians.length} técnicos encontrados');
      return technicians;
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al obtener técnicos cercanos:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al obtener técnicos cercanos: $e');
    }
  }

  /// Obtener técnicos pendientes de verificación (Solo admin)
  Future<List<ProfileModel>> getPendingVerifications() async {
    try {
      print('🔵 [PROFILES_DS] Obteniendo verificaciones pendientes');
      
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'technician')
          .eq('verification_status', 'pending')
          .order('created_at', ascending: true);

      final technicians = (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [PROFILES_DS] ${technicians.length} verificaciones pendientes');
      return technicians;
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al obtener verificaciones:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al obtener verificaciones pendientes: $e');
    }
  }

  /// Actualizar estado de verificación (Solo admin)
  Future<ProfileModel> updateVerificationStatus(
    String technicianId, {
    required String status,
    String? notes,
  }) async {
    try {
      print('🔵 [PROFILES_DS] Actualizando estado de verificación');
      print('   Técnico: $technicianId');
      print('   Estado: $status');
      
      final fields = <String, dynamic>{
        'verification_status': status,
        'verification_notes': notes,
      };

      if (status == 'approved') {
        fields['verified_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('profiles')
          .update(fields)
          .eq('id', technicianId)
          .select()
          .single();

      print('✅ [PROFILES_DS] Verificación actualizada');
      return ProfileModel.fromJson(response);
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al actualizar verificación:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      throw Exception('Error al actualizar verificación: $e');
    }
  }
}