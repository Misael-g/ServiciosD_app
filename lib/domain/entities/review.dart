import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String serviceRequestId;
  final String reviewerId; // Quien califica
  final String reviewedId; // Quien recibe la calificación
  final int rating; // 1-5
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
}