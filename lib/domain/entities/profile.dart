import 'package:equatable/equatable.dart';

/// Entidad de dominio para Perfil de Usuario
class Profile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos específicos de técnicos
  final List<String>? specialties;
  final List<String>? coverageZones;
  final double? baseRate;
  final String? bio;
  final String? verificationStatus;
  final String? verificationNotes;
  final DateTime? verifiedAt;

  // Geolocalización
  final double? latitude;
  final double? longitude;
  final String? address;

  // Métricas
  final double? averageRating;
  final int? totalReviews;
  final int? completedServices;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
    this.specialties,
    this.coverageZones,
    this.baseRate,
    this.bio,
    this.verificationStatus,
    this.verificationNotes,
    this.verifiedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.averageRating,
    this.totalReviews,
    this.completedServices,
  });

  /// Verificar si es cliente
  bool get isClient => role == 'client';

  /// Verificar si es técnico
  bool get isTechnician => role == 'technician';

  /// Verificar si es admin
  bool get isAdmin => role == 'admin';

  /// Verificar si el técnico está verificado
  bool get isVerified => verificationStatus == 'approved';

  /// Verificar si tiene ubicación
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        role,
        profilePictureUrl,
        createdAt,
        updatedAt,
        specialties,
        coverageZones,
        baseRate,
        bio,
        verificationStatus,
        verificationNotes,
        verifiedAt,
        latitude,
        longitude,
        address,
        averageRating,
        totalReviews,
        completedServices,
      ];

  Profile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? specialties,
    List<String>? coverageZones,
    double? baseRate,
    String? bio,
    String? verificationStatus,
    String? verificationNotes,
    DateTime? verifiedAt,
    double? latitude,
    double? longitude,
    String? address,
    double? averageRating,
    int? totalReviews,
    int? completedServices,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specialties: specialties ?? this.specialties,
      coverageZones: coverageZones ?? this.coverageZones,
      baseRate: baseRate ?? this.baseRate,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedServices: completedServices ?? this.completedServices,
    );
  }
}