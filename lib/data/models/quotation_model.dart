import '../../domain/entities/quotation.dart';

/// Modelo de datos para Quotation
class QuotationModel extends Quotation {
  const QuotationModel({
    required super.id,
    required super.serviceRequestId,
    required super.technicianId,
    required super.estimatedPrice,
    required super.estimatedDuration,
    required super.description,
    required super.status,
    required super.createdAt,
  });

  /// Crear QuotationModel desde JSON (Supabase)
  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      technicianId: json['technician_id'] as String,
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
      estimatedDuration: json['estimated_duration'] as int,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir QuotationModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'technician_id': technicianId,
      'estimated_price': estimatedPrice,
      'estimated_duration': estimatedDuration,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convertir a entidad de dominio
  Quotation toEntity() {
    return Quotation(
      id: id,
      serviceRequestId: serviceRequestId,
      technicianId: technicianId,
      estimatedPrice: estimatedPrice,
      estimatedDuration: estimatedDuration,
      description: description,
      status: status,
      createdAt: createdAt,
    );
  }

  /// Crear QuotationModel desde Quotation
  factory QuotationModel.fromEntity(Quotation quotation) {
    return QuotationModel(
      id: quotation.id,
      serviceRequestId: quotation.serviceRequestId,
      technicianId: quotation.technicianId,
      estimatedPrice: quotation.estimatedPrice,
      estimatedDuration: quotation.estimatedDuration,
      description: quotation.description,
      status: quotation.status,
      createdAt: quotation.createdAt,
    );
  }
}