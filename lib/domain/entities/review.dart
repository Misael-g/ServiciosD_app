/// Entidad de dominio para reseñas
class Review {
  final String id;
  final String clientId;
  final String technicianId;
  final String serviceRequestId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.clientId,
    required this.technicianId,
    required this.serviceRequestId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}