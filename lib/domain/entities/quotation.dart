import 'package:equatable/equatable.dart';

/// Entidad de dominio para Cotización
class Quotation extends Equatable {
  final String id;
  final String serviceRequestId;
  final String technicianId;
  final double estimatedPrice;
  final double? laborCost;           // ← NUEVO
  final double? materialsCost;       // ← NUEVO
  final int estimatedDuration; // en minutos
  final int? estimatedArrivalTime;   // ← NUEVO
  final String description;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? acceptedAt;        // ← NUEVO

  const Quotation({
    required this.id,
    required this.serviceRequestId,
    required this.technicianId,
    required this.estimatedPrice,
    this.laborCost,                  // ← NUEVO
    this.materialsCost,              // ← NUEVO
    required this.estimatedDuration,
    this.estimatedArrivalTime,       // ← NUEVO
    required this.description,
    required this.status,
    required this.createdAt,
    this.acceptedAt,                 // ← NUEVO
  });

  /// Verificar si está pendiente
  bool get isPending => status == 'pending';

  /// Verificar si está aceptada
  bool get isAccepted => status == 'accepted';

  /// Verificar si está rechazada
  bool get isRejected => status == 'rejected';

  /// Formatear precio
  String get formattedPrice => '\$${estimatedPrice.toStringAsFixed(2)}';

  /// Formatear duración
  String get formattedDuration {
    if (estimatedDuration < 60) {
      return '$estimatedDuration min';
    }
    final hours = estimatedDuration ~/ 60;
    final minutes = estimatedDuration % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h ${minutes}m';
  }

  @override
  List<Object?> get props => [
        id,
        serviceRequestId,
        technicianId,
        estimatedPrice,
        laborCost,
        materialsCost,
        estimatedDuration,
        estimatedArrivalTime,
        description,
        status,
        createdAt,
        acceptedAt,
      ];

  Quotation copyWith({
    String? id,
    String? serviceRequestId,
    String? technicianId,
    double? estimatedPrice,
    double? laborCost,
    double? materialsCost,
    int? estimatedDuration,
    int? estimatedArrivalTime,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      technicianId: technicianId ?? this.technicianId,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      laborCost: laborCost ?? this.laborCost,
      materialsCost: materialsCost ?? this.materialsCost,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}