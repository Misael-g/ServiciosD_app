import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/profile_model.dart';

/// Fuente de datos remota para perfiles de usuarios
class ProfilesRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Obtener perfil por ID
  Future<ProfileModel> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Obtener perfil del usuario actual
  Future<ProfileModel> getCurrentUserProfile() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) {
      throw Exception('No hay usuario autenticado');
    }

    return getProfileById(userId);
  }

  /// Actualizar perfil
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final data = profile.toJson();
      // Remover campos que no deben actualizarse
      data.remove('id');
      data.remove('email');
      data.remove('created_at');
      data.remove('role'); // El rol NO puede cambiarse desde la app

      final response = await _supabase
          .from('profiles')
          .update(data)
          .eq('id', profile.id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Actualizar solo campos específicos del perfil
  Future<ProfileModel> updateProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
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

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar campos del perfil: $e');
    }
  }

  /// Actualizar foto de perfil
  Future<ProfileModel> updateProfilePicture(
    String userId,
    String imageUrl,
  ) async {
    return updateProfileFields(userId, {'profile_picture_url': imageUrl});
  }

  /// Actualizar ubicación del perfil
  Future<ProfileModel> updateLocation(
    String userId, {
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final fields = <String, dynamic>{
      'location': 'POINT($longitude $latitude)',
    };

    if (address != null) {
      fields['address'] = address;
    }

    return updateProfileFields(userId, fields);
  }

  /// Obtener técnicos cercanos
  /// Usa la función de PostgreSQL get_nearby_technicians
  Future<List<ProfileModel>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_nearby_technicians',
        params: {
          'client_location': 'POINT($longitude $latitude)',
          'service_type': serviceType,
          'radius_meters': radiusMeters,
        },
      );

      if (response == null) return [];

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener técnicos cercanos: $e');
    }
  }

  /// Obtener técnicos por especialidad
  Future<List<ProfileModel>> getTechniciansBySpecialty(
    String specialty,
  ) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'technician')
          .eq('verification_status', 'approved')
          .contains('specialties', [specialty]);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener técnicos por especialidad: $e');
    }
  }

  /// Actualizar estado de verificación (Solo admin)
  Future<ProfileModel> updateVerificationStatus(
    String technicianId, {
    required String status,
    String? notes,
  }) async {
    try {
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

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar verificación: $e');
    }
  }

  /// Obtener técnicos pendientes de verificación (Solo admin)
  Future<List<ProfileModel>> getPendingVerifications() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'technician')
          .eq('verification_status', 'pending')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener verificaciones pendientes: $e');
    }
  }

  /// Buscar perfiles por nombre o email
  Future<List<ProfileModel>> searchProfiles(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar perfiles: $e');
    }
  }
}