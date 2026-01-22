import '../../domain/entities/quotation.dart';

/// Modelo de datos para Quotation
class QuotationModel extends Quotation {
  const QuotationModel({
    required super.id,
    required super.serviceRequestId,
    required super.technicianId,
    required super.estimatedPrice,
    super.laborCost,           // ← NUEVO
    super.materialsCost,       // ← NUEVO
    required super.estimatedDuration,
    super.estimatedArrivalTime, // ← NUEVO
    required super.description,
    required super.status,
    required super.createdAt,
    super.acceptedAt,
  });

  /// Crear QuotationModel desde JSON (Supabase)
  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      technicianId: json['technician_id'] as String,
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
      laborCost: json['labor_cost'] != null           // ← NUEVO
          ? (json['labor_cost'] as num).toDouble()
          : null,
      materialsCost: json['materials_cost'] != null   // ← NUEVO
          ? (json['materials_cost'] as num).toDouble()
          : null,
      estimatedDuration: json['estimated_duration'] as int,
      estimatedArrivalTime: json['estimated_arrival_time'] as int?, // ← NUEVO
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }

  /// Convertir QuotationModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'technician_id': technicianId,
      'estimated_price': estimatedPrice,
      'labor_cost': laborCost,              // ← NUEVO
      'materials_cost': materialsCost,      // ← NUEVO
      'estimated_duration': estimatedDuration,
      'estimated_arrival_time': estimatedArrivalTime, // ← NUEVO
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
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
      laborCost: quotation.laborCost,        // ← NUEVO
      materialsCost: quotation.materialsCost, // ← NUEVO
      estimatedDuration: quotation.estimatedDuration,
      estimatedArrivalTime: quotation.estimatedArrivalTime, // ← NUEVO
      description: quotation.description,
      status: quotation.status,
      createdAt: quotation.createdAt,
      acceptedAt: quotation.acceptedAt,
    );
  }
}