import '../../../domain/entities/review.dart';

/// Model para reseñas desde Supabase
class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.clientId,
    required super.technicianId,
    required super.serviceRequestId,
    required super.rating,
    required super.comment,
    required super.createdAt,
  });

  /// Crear ReviewModel desde JSON (Supabase)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      technicianId: json['technician_id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir ReviewModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'technician_id': technicianId,
      'service_request_id': serviceRequestId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convertir a entidad de dominio
  Review toEntity() {
    return Review(
      id: id,
      clientId: clientId,
      technicianId: technicianId,
      serviceRequestId: serviceRequestId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}