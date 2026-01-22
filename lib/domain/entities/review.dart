/// Entidad de dominio para reseñas
/// Compatible con schema existente (reviewer_id, reviewed_id)
class Review {
  final String id;
  final String serviceRequestId;
  final String reviewerId;    // Cliente que deja la reseña
  final String reviewedId;    // Técnico que recibe la reseña
  final double rating;
  final int? punctualityRating;
  final int? qualityRating;
  final int? communicationRating;
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
}