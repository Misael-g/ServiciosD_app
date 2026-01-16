import '../../domain/entities/review.dart';

/// Modelo de datos para Review
class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.serviceRequestId,
    required super.reviewerId,
    required super.reviewedId,
    required super.rating,
    super.punctualityRating,
    super.qualityRating,
    super.communicationRating,
    super.comment,
    required super.createdAt,
  });

  /// Crear ReviewModel desde JSON (Supabase)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      serviceRequestId: json['service_request_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewedId: json['reviewed_id'] as String,
      rating: json['rating'] as int,
      punctualityRating: json['punctuality_rating'] as int?,
      qualityRating: json['quality_rating'] as int?,
      communicationRating: json['communication_rating'] as int?,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir ReviewModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'reviewer_id': reviewerId,
      'reviewed_id': reviewedId,
      'rating': rating,
      'punctuality_rating': punctualityRating,
      'quality_rating': qualityRating,
      'communication_rating': communicationRating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convertir a entidad de dominio
  Review toEntity() {
    return Review(
      id: id,
      serviceRequestId: serviceRequestId,
      reviewerId: reviewerId,
      reviewedId: reviewedId,
      rating: rating,
      punctualityRating: punctualityRating,
      qualityRating: qualityRating,
      communicationRating: communicationRating,
      comment: comment,
      createdAt: createdAt,
    );
  }

  /// Crear ReviewModel desde Review
  factory ReviewModel.fromEntity(Review review) {
    return ReviewModel(
      id: review.id,
      serviceRequestId: review.serviceRequestId,
      reviewerId: review.reviewerId,
      reviewedId: review.reviewedId,
      rating: review.rating,
      punctualityRating: review.punctualityRating,
      qualityRating: review.qualityRating,
      communicationRating: review.communicationRating,
      comment: review.comment,
      createdAt: review.createdAt,
    );
  }
}