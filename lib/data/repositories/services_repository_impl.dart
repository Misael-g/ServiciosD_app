import '../../domain/entities/service_request.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/service_requests_remote_ds.dart';

/// Implementación del repositorio de servicios
class ServicesRepositoryImpl implements ServicesRepository {
  final ServiceRequestsRemoteDataSource _remoteDataSource;

  ServicesRepositoryImpl(this._remoteDataSource);

  @override
  Future<ServiceRequest> createServiceRequest({
    required String title,
    required String description,
    required String serviceType,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? images,
  }) async {
    try {
      final requestModel = await _remoteDataSource.createServiceRequest(
        title: title,
        description: description,
        serviceType: serviceType,
        latitude: latitude,
        longitude: longitude,
        address: address,
        images: images,
      );
      return requestModel.toEntity();
    } catch (e) {
      throw Exception('Error al crear solicitud: $e');
    }
  }

  @override
  Future<ServiceRequest> getServiceRequestById(String id) async {
    try {
      final requestModel = await _remoteDataSource.getServiceRequestById(id);
      return requestModel.toEntity();
    } catch (e) {
      throw Exception('Error al obtener solicitud: $e');
    }
  }

  @override
  Future<List<ServiceRequest>> getMyServiceRequests() async {
    try {
      final requestModels = await _remoteDataSource.getMyServiceRequests();
      return requestModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes: $e');
    }
  }

  @override
  Future<List<ServiceRequest>> getNearbyServiceRequests({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      final requestModels = await _remoteDataSource.getNearbyServiceRequests(
        latitude: latitude,
        longitude: longitude,
        serviceType: serviceType,
        radiusMeters: radiusMeters,
      );
      return requestModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes cercanas: $e');
    }
  }

  @override
  Future<ServiceRequest> updateServiceRequestStatus(
    String id,
    String newStatus,
  ) async {
    try {
      final requestModel =
          await _remoteDataSource.updateServiceRequestStatus(id, newStatus);
      return requestModel.toEntity();
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  @override
  Future<ServiceRequest> completeService(String requestId) async {
    try {
      final requestModel = await _remoteDataSource.completeService(requestId);
      return requestModel.toEntity();
    } catch (e) {
      throw Exception('Error al completar servicio: $e');
    }
  }

  @override
  Future<ServiceRequest> cancelService(String requestId) async {
    try {
      final requestModel = await _remoteDataSource.cancelService(requestId);
      return requestModel.toEntity();
    } catch (e) {
      throw Exception('Error al cancelar servicio: $e');
    }
  }
}