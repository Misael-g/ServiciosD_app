import 'package:equatable/equatable.dart';

/// Entidad de dominio para Reseña/Calificación
class Review extends Equatable {
  final String id;
  final String serviceRequestId;
  final String reviewerId; // Quien califica
  final String reviewedId; // Quien recibe la calificación
  final int rating; // 1-5
  final int? punctualityRating; // 1-5
  final int? qualityRating; // 1-5
  final int? communicationRating; // 1-5
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.serviceRequestId,
    required this.reviewerId,
    required this.reviewedId,
    required this.rating,
    this.punctualityRating,
    this.qualityRating,
    this.communicationRating,
    this.comment,
    required this.createdAt,
  });

  /// Calcular promedio de ratings detallados
  double get averageDetailedRating {
    final ratings = [
      if (punctualityRating != null) punctualityRating!,
      if (qualityRating != null) qualityRating!,
      if (communicationRating != null) communicationRating!,
    ];

    if (ratings.isEmpty) return rating.toDouble();

    final sum = ratings.reduce((a, b) => a + b);
    return sum / ratings.length;
  }

  /// Verificar si tiene comentario
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Verificar si tiene ratings detallados
  bool get hasDetailedRatings =>
      punctualityRating != null ||
      qualityRating != null ||
      communicationRating != null;

  @override
  List<Object?> get props => [
        id,
        serviceRequestId,
        reviewerId,
        reviewedId,
        rating,
        punctualityRating,
        qualityRating,
        communicationRating,
        comment,
        createdAt,
      ];

  Review copyWith({
    String? id,
    String? serviceRequestId,
    String? reviewerId,
    String? reviewedId,
    int? rating,
    int? punctualityRating,
    int? qualityRating,
    int? communicationRating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewedId: reviewedId ?? this.reviewedId,
      rating: rating ?? this.rating,
      punctualityRating: punctualityRating ?? this.punctualityRating,
      qualityRating: qualityRating ?? this.qualityRating,
      communicationRating: communicationRating ?? this.communicationRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}