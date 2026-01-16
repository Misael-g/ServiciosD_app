import 'package:equatable/equatable.dart';

/// Entidad de dominio para Cotización
class Quotation extends Equatable {
  final String id;
  final String serviceRequestId;
  final String technicianId;
  final double estimatedPrice;
  final int estimatedDuration; // en minutos
  final String description;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  const Quotation({
    required this.id,
    required this.serviceRequestId,
    required this.technicianId,
    required this.estimatedPrice,
    required this.estimatedDuration,
    required this.description,
    required this.status,
    required this.createdAt,
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
        estimatedDuration,
        description,
        status,
        createdAt,
      ];

  Quotation copyWith({
    String? id,
    String? serviceRequestId,
    String? technicianId,
    double? estimatedPrice,
    int? estimatedDuration,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      technicianId: technicianId ?? this.technicianId,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}