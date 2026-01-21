import 'dart:math' as math;
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

  /// Obtener perfil por email
  Future<ProfileModel?> getProfileByEmail(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle(); // ← maybeSingle() permite que sea null si no existe

      if (response == null) {
        return null;
      }

      return ProfileModel.fromJson(response);
    } catch (e) {
      print('❌ [PROFILES_DS] Error al buscar email: $e');
      return null;
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
    print('   Address: ${address ?? "no proporcionada"}');
    
    final fields = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'location': 'POINT($longitude $latitude)',
    };

    if (address != null && address.isNotEmpty) {
      fields['address'] = address;
    }

    print('📝 [PROFILES_DS] Campos a actualizar: $fields');

    return updateProfileFields(userId, fields);
  }

  /// Obtener técnicos cercanos (con filtro de especialidad)
  Future<List<ProfileModel>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      print('🔵 [PROFILES_DS] Buscando técnicos cercanos por especialidad');
      print('   Tipo: $serviceType');
      print('   Ubicación: lat=$latitude, lon=$longitude');
      print('   Radio: ${radiusMeters}m');
      
      // Intentar usar función RPC
      try {
        final response = await _supabase.rpc(
          'get_nearby_technicians',
          params: {
            'client_location': 'POINT($longitude $latitude)',
            'service_type': serviceType,
            'radius_meters': radiusMeters,
          },
        );

        if (response != null) {
          print('✅ [PROFILES_DS] Técnicos obtenidos vía RPC');
          final technicians = (response as List)
              .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
              .toList();

          for (var tech in technicians) {
            print('👤 ${tech.fullName}: lat=${tech.latitude}, lng=${tech.longitude}');
          }

          print('✅ [PROFILES_DS] ${technicians.length} técnicos encontrados');
          return technicians;
        }
      } catch (rpcError) {
        print('⚠️ [PROFILES_DS] Función RPC no disponible: $rpcError');
        print('   Usando filtro básico...');
      }

      // FALLBACK: Si RPC falla, usar SELECT directo
      print('🔄 [PROFILES_DS] Usando query SELECT directo');
      
      final response = await _supabase
          .from('profiles')
          .select('*, latitude, longitude')
          .eq('role', 'technician')
          .eq('verification_status', 'approved')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .limit(50);

      print('✅ [PROFILES_DS] Query directo ejecutado');

      final allTechnicians = (response as List)
          .map((json) {
            print('🔍 JSON recibido: ${json.keys}');
            return ProfileModel.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      // Filtrar por especialidad y distancia
      final filteredTechnicians = allTechnicians.where((tech) {
        // Verificar coordenadas válidas
        if (tech.latitude == null || tech.longitude == null) {
          print('⚠️ Técnico ${tech.fullName} sin coordenadas válidas');
          return false;
        }

        if (tech.latitude == 0.0 || tech.longitude == 0.0) {
          print('⚠️ Técnico ${tech.fullName} con coordenadas 0.0');
          return false;
        }

        // Verificar especialidad
        final hasSpecialty = tech.specialties?.contains(serviceType) ?? false;
        if (!hasSpecialty) {
          return false;
        }

        // Calcular distancia
        final distance = _calculateDistance(
          latitude,
          longitude,
          tech.latitude!,
          tech.longitude!,
        );

        final withinRadius = distance <= radiusMeters;
        print('👤 ${tech.fullName}: ${withinRadius ? "✅" : "❌"} ${distance.toStringAsFixed(0)}m');

        return withinRadius;
      }).toList();

      // Ordenar por distancia
      filteredTechnicians.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude!, a.longitude!);
        final distB = _calculateDistance(latitude, longitude, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });

      print('✅ [PROFILES_DS] ${filteredTechnicians.length} técnicos dentro del radio');
      return filteredTechnicians;
      
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al obtener técnicos cercanos:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      return [];
    }
  }

  /// Obtener TODOS los técnicos cercanos (sin filtro de especialidad)
  Future<List<ProfileModel>> getAllNearbyTechnicians({
    required double latitude,
    required double longitude,
    int radiusMeters = 10000,
  }) async {
    try {
      print('📍 [PROFILES_DS] Buscando TODOS los técnicos cercanos');
      print('   Ubicación cliente: lat=$latitude, lon=$longitude');
      print('   Radio: ${radiusMeters}m');

      // Intentar usar función RPC si existe
      try {
        final response = await _supabase.rpc(
          'get_all_nearby_technicians',
          params: {
            'client_location': 'POINT($longitude $latitude)',
            'radius_meters': radiusMeters,
          },
        );

        if (response != null) {
          print('✅ [PROFILES_DS] Técnicos obtenidos vía RPC');
          
          // 🔍 DEBUG: Ver el JSON crudo
          for (var json in (response as List)) {
            print('📦 JSON crudo del técnico:');
            print('   latitude: ${json['latitude']} (tipo: ${json['latitude'].runtimeType})');
            print('   longitude: ${json['longitude']} (tipo: ${json['longitude'].runtimeType})');
            print('   location: ${json['location']}');
            print('   full_name: ${json['full_name']}');
          }
          
          final technicians = (response as List)
              .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Log de cada técnico
          for (var tech in technicians) {
            print('👤 Técnico ${tech.fullName}: lat=${tech.latitude}, lng=${tech.longitude}');
          }

          print('✅ [PROFILES_DS] ${technicians.length} técnicos encontrados vía RPC');
          return technicians;
        }
      } catch (rpcError) {
        print('⚠️ [PROFILES_DS] Función RPC no disponible: $rpcError');
        print('   Usando filtro básico...');
      }

      // FALLBACK: Si RPC falla, obtener directamente con SELECT
      print('🔄 [PROFILES_DS] Usando query SELECT directo');
      
      final response = await _supabase
          .from('profiles')
          .select('*, latitude, longitude') // ← CRÍTICO: Incluir latitude y longitude
          .eq('role', 'technician')
          .eq('verification_status', 'approved')
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .limit(50);

      print('✅ [PROFILES_DS] Query directo ejecutado');
      print('   Registros recibidos: ${(response as List).length}');
      
      final technicians = (response as List)
          .map((json) {
            print('🔍 JSON keys: ${json.keys}');
            print('   ID: ${json['id']}');
            print('   Nombre: ${json['full_name']}');
            print('   Latitude: ${json['latitude']}');
            print('   Longitude: ${json['longitude']}');
            return ProfileModel.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      print('✅ [PROFILES_DS] ${technicians.length} técnicos parseados');

      // Filtrar por distancia manualmente
      final filteredTechnicians = technicians.where((tech) {
        if (tech.latitude == null || tech.longitude == null) {
          print('⚠️ Técnico ${tech.fullName} sin coordenadas válidas (null)');
          return false;
        }

        if (tech.latitude == 0.0 || tech.longitude == 0.0) {
          print('⚠️ Técnico ${tech.fullName} con coordenadas 0.0');
          return false;
        }

        // Calcular distancia usando fórmula de Haversine
        final distance = _calculateDistance(
          latitude,
          longitude,
          tech.latitude!,
          tech.longitude!,
        );

        final withinRadius = distance <= radiusMeters;
        print('👤 Técnico ${tech.fullName}: ${withinRadius ? "✅" : "❌"} ${distance.toStringAsFixed(0)}m (${(distance/1000).toStringAsFixed(1)}km)');

        return withinRadius;
      }).toList();

      // Ordenar por distancia
      filteredTechnicians.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude!, a.longitude!);
        final distB = _calculateDistance(latitude, longitude, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });

      print('✅ [PROFILES_DS] ${filteredTechnicians.length} técnicos dentro del radio de ${radiusMeters}m');

      return filteredTechnicians;
    } catch (e, stackTrace) {
      print('❌ [PROFILES_DS] Error al obtener técnicos:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      return [];
    }
  }

  /// Calcular distancia entre dos puntos (Haversine)
  /// Retorna distancia en metros
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Radio de la Tierra en metros
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
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