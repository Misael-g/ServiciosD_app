import '../entities/service_request.dart';

/// Repositorio de servicios (interfaz)
abstract class ServicesRepository {
  /// Crear nueva solicitud de servicio
  Future<ServiceRequest> createServiceRequest({
    required String title,
    required String description,
    required String serviceType,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? images,
  });

  /// Obtener solicitud por ID
  Future<ServiceRequest> getServiceRequestById(String id);

  /// Obtener mis solicitudes
  Future<List<ServiceRequest>> getMyServiceRequests();

  /// Obtener solicitudes cercanas (para técnicos)
  Future<List<ServiceRequest>> getNearbyServiceRequests({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  });

  /// Actualizar estado de la solicitud
  Future<ServiceRequest> updateServiceRequestStatus(
    String id,
    String newStatus,
  );

  /// Completar servicio
  Future<ServiceRequest> completeService(String requestId);

  /// Cancelar servicio
  Future<ServiceRequest> cancelService(String requestId);
}