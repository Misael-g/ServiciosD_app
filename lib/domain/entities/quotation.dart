import 'package:equatable/equatable.dart';

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

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

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
}