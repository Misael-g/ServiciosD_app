import 'package:equatable/equatable.dart';

/// Entidad de dominio para Solicitud de Servicio
class ServiceRequest extends Equatable {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String serviceType;
  final double latitude;
  final double longitude;
  final String address;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Referencias al técnico asignado
  final String? assignedTechnicianId;
  final DateTime? assignedAt;

  // Fechas de seguimiento
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Imágenes del problema
  final List<String>? images;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTechnicianId,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.images,
  });

  /// Verificar si está pendiente
  bool get isPending => status == 'pending';

  /// Verificar si tiene cotizaciones
  bool get hasQuotations => status == 'quotation_sent';

  /// Verificar si está aceptada
  bool get isAccepted => status == 'quotation_accepted';

  /// Verificar si está en progreso
  bool get isInProgress => status == 'in_progress';

  /// Verificar si está completada
  bool get isCompleted => status == 'completed';

  /// Verificar si está calificada
  bool get isRated => status == 'rated';

  /// Verificar si está cancelada
  bool get isCancelled => status == 'cancelled';

  /// Verificar si tiene técnico asignado
  bool get hasTechnician => assignedTechnicianId != null;

  /// Verificar si tiene imágenes
  bool get hasImages => images != null && images!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        clientId,
        title,
        description,
        serviceType,
        latitude,
        longitude,
        address,
        status,
        createdAt,
        updatedAt,
        assignedTechnicianId,
        assignedAt,
        startedAt,
        completedAt,
        images,
      ];

  ServiceRequest copyWith({
    String? id,
    String? clientId,
    String? title,
    String? description,
    String? serviceType,
    double? latitude,
    double? longitude,
    String? address,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTechnicianId,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? images,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      serviceType: serviceType ?? this.serviceType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      images: images ?? this.images,
    );
  }
}