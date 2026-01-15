import '../../domain/entities/service_request.dart';
import '../../core/utils/location_helper.dart';

/// Modelo de datos para ServiceRequest
class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
    required super.clientId,
    required super.title,
    required super.description,
    required super.serviceType,
    required super.latitude,
    required super.longitude,
    required super.address,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.assignedTechnicianId,
    super.assignedAt,
    super.startedAt,
    super.completedAt,
    super.images,
  });

  /// Crear ServiceRequestModel desde JSON (Supabase)
  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    // Parsear ubicación desde PostGIS
    Map<String, double>? location;
    if (json['location'] != null) {
      location = LocationHelper.parsePostGISPoint(json['location']);
    }

    return ServiceRequestModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      serviceType: json['service_type'] as String,
      latitude: location?['latitude'] ?? 0.0,
      longitude: location?['longitude'] ?? 0.0,
      address: json['address'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedTechnicianId: json['assigned_technician_id'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
    );
  }

  /// Convertir ServiceRequestModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'description': description,
      'service_type': serviceType,
      'location': LocationHelper.coordinatesToPostGIS(latitude, longitude),
      'address': address,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_technician_id': assignedTechnicianId,
      'assigned_at': assignedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'images': images,
    };
  }

  /// Convertir a entidad de dominio
  ServiceRequest toEntity() {
    return ServiceRequest(
      id: id,
      clientId: clientId,
      title: title,
      description: description,
      serviceType: serviceType,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedTechnicianId: assignedTechnicianId,
      assignedAt: assignedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      images: images,
    );
  }

  /// Crear ServiceRequestModel desde ServiceRequest
  factory ServiceRequestModel.fromEntity(ServiceRequest request) {
    return ServiceRequestModel(
      id: request.id,
      clientId: request.clientId,
      title: request.title,
      description: request.description,
      serviceType: request.serviceType,
      latitude: request.latitude,
      longitude: request.longitude,
      address: request.address,
      status: request.status,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      assignedTechnicianId: request.assignedTechnicianId,
      assignedAt: request.assignedAt,
      startedAt: request.startedAt,
      completedAt: request.completedAt,
      images: request.images,
    );
  }
}