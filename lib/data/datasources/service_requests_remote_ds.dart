import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/service_request_model.dart';

/// Fuente de datos remota para solicitudes de servicio
class ServiceRequestsRemoteDataSource {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Crear nueva solicitud de servicio
  Future<ServiceRequestModel> createServiceRequest({
    required String title,
    required String description,
    required String serviceType,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? images,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      print('📍 [SERVICE_REQUESTS_DS] Creando solicitud con ubicación:');
      print('   Lat: $latitude, Lon: $longitude');
      print('   Address: $address');

      final response = await _supabase
          .from('service_requests')
          .insert({
            'client_id': userId,
            'title': title,
            'description': description,
            'service_type': serviceType, 
            'latitude': latitude,       
            'longitude': longitude,      
            'location': 'POINT($longitude $latitude)',
            'address': address,
            'status': 'pending',
            'images': images,        
          })
          .select()
          .single();

      print('✅ [SERVICE_REQUESTS_DS] Solicitud creada con ubicación guardada');

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      print('❌ [SERVICE_REQUESTS_DS] Error al crear solicitud: $e');
      throw Exception('Error al crear solicitud: $e');
    }
  }

  /// Obtener solicitud por ID
  Future<ServiceRequestModel> getServiceRequestById(String id) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('id', id)
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener solicitud: $e');
    }
  }

  /// Obtener solicitudes del cliente actual
  Future<List<ServiceRequestModel>> getMyServiceRequests() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('client_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ServiceRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes: $e');
    }
  }

  /// Obtener solicitudes por estado
  Future<List<ServiceRequestModel>> getServiceRequestsByStatus(
    String status,
  ) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('client_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ServiceRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes: $e');
    }
  }

  /// Obtener solicitudes cercanas (para técnicos)
  /// CORREGIDO: Usar 'requested_service_type' en lugar de 'service_type'
  Future<List<ServiceRequestModel>> getNearbyServiceRequests({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_nearby_service_requests',
        params: {
          'tech_location': 'POINT($longitude $latitude)',
          'requested_service_type': serviceType, // ← CAMBIO IMPORTANTE
          'radius_meters': radiusMeters,
        },
      );

      if (response == null) return [];

      return (response as List)
          .map((json) => ServiceRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Si la función RPC no existe o falla, usar filtrado básico
      try {
        final response = await _supabase
            .from('service_requests')
            .select()
            .eq('service_type', serviceType)
            .filter('status', 'in', '(pending,quotation_sent)') // ← CORRECCIÓN: usar filter con 'in'
            .order('created_at', ascending: false)
            .limit(20);

        return (response as List)
            .map((json) => ServiceRequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e2) {
        throw Exception('Error al obtener solicitudes cercanas: $e2');
      }
    }
  }

  /// Obtener TODAS las solicitudes cercanas (sin filtro de tipo)
  Future<List<ServiceRequestModel>> getAllNearbyRequests({
    required double latitude,
    required double longitude,
    int radiusMeters = 10000,
  }) async {
    try {
      print('📍 [SERVICE_REQUESTS_DS] Buscando solicitudes cercanas');
      print('   Ubicación técnico: lat=$latitude, lon=$longitude');
      print('   Radio: ${radiusMeters}m');

      // Intentar usar función RPC
      try {
        final response = await _supabase.rpc(
          'get_all_nearby_requests',
          params: {
            'tech_location': 'POINT($longitude $latitude)',
            'radius_meters': radiusMeters,
          },
        );

        if (response != null) {
          print('✅ [SERVICE_REQUESTS_DS] Solicitudes obtenidas vía RPC');
          final requests = (response as List)
              .map((json) => ServiceRequestModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Log de cada solicitud
          for (var request in requests) {
            print('📍 Request ${request.id}: lat=${request.latitude}, lng=${request.longitude}');
          }

          return requests;
        }
      } catch (rpcError) {
        print('⚠️ [SERVICE_REQUESTS_DS] Función RPC no disponible: $rpcError');
        print('   Usando filtro básico...');
      }

      // FALLBACK: Si RPC falla, obtener directamente con SELECT
      print('🔄 [SERVICE_REQUESTS_DS] Usando query SELECT directo');
      
      final response = await _supabase
          .from('service_requests')
          .select('*, latitude, longitude') // ← IMPORTANTE: Incluir latitude y longitude
          .inFilter('status', ['pending', 'quotation_sent'])
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false)
          .limit(50);

      print('✅ [SERVICE_REQUESTS_DS] Query directo ejecutado');
      
      final requests = (response as List)
          .map((json) {
            print('🔍 JSON recibido: ${json.keys}');
            return ServiceRequestModel.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      // Filtrar por distancia manualmente
      final filteredRequests = requests.where((request) {
        if (request.latitude == 0.0 || request.longitude == 0.0) {
          print('⚠️ Request ${request.id} sin coordenadas válidas');
          return false;
        }

        // Calcular distancia usando fórmula de Haversine
        final distance = _calculateDistance(
          latitude,
          longitude,
          request.latitude,
          request.longitude,
        );

        final withinRadius = distance <= radiusMeters;
        print('📍 Request ${request.id}: ${withinRadius ? "✅" : "❌"} ${distance.toStringAsFixed(0)}m');

        return withinRadius;
      }).toList();

      // Ordenar por distancia
      filteredRequests.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      print('✅ [SERVICE_REQUESTS_DS] ${filteredRequests.length} solicitudes dentro del radio');

      return filteredRequests;
    } catch (e) {
      print('❌ [SERVICE_REQUESTS_DS] Error: $e');
      throw Exception('Error al obtener solicitudes cercanas: $e');
    }
  }

  /// Actualizar estado de la solicitud
  Future<ServiceRequestModel> updateServiceRequestStatus(
    String id,
    String newStatus,
  ) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .update({'status': newStatus})
          .eq('id', id)
          .select()
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Asignar técnico a solicitud
  Future<ServiceRequestModel> assignTechnician(
    String requestId,
    String technicianId,
  ) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .update({
            'assigned_technician_id': technicianId,
            'assigned_at': DateTime.now().toIso8601String(),
            'status': 'quotation_accepted',
          })
          .eq('id', requestId)
          .select()
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al asignar técnico: $e');
    }
  }

  /// Iniciar servicio
  Future<ServiceRequestModel> startService(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .update({
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al iniciar servicio: $e');
    }
  }

  /// Completar servicio
  Future<ServiceRequestModel> completeService(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al completar servicio: $e');
    }
  }

  /// Cancelar servicio
  Future<ServiceRequestModel> cancelService(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId)
          .select()
          .single();

      return ServiceRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cancelar servicio: $e');
    }
  }

  /// Eliminar solicitud
  Future<void> deleteServiceRequest(String id) async {
    try {
      await _supabase.from('service_requests').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar solicitud: $e');
    }
  }

  /// Verificar si un técnico puede enviar cotización
  Future<bool> canTechnicianQuote(String requestId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return false;

      final response = await _supabase.rpc(
        'can_technician_quote',
        params: {
          'tech_id': userId,
          'request_id': requestId,
        },
      );

      return response == true;
    } catch (e) {
      return false;
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
}