import '../../domain/entities/profile.dart';
import '../../core/utils/location_helper.dart';

/// Modelo de datos para Profile (capa de datos)
/// Extiende de la entidad de dominio y agrega métodos de serialización
class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    required super.role,
    super.profilePictureUrl,
    required super.createdAt,
    required super.updatedAt,
    super.specialties,
    super.coverageZones,
    super.baseRate,
    super.bio,
    super.verificationStatus,
    super.verificationNotes,
    super.verifiedAt,
    super.latitude,
    super.longitude,
    super.address,
    super.averageRating,
    super.totalReviews,
    super.completedServices,
  });

  /// Crear ProfileModel desde JSON (Supabase)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Parsear ubicación desde PostGIS si existe
    Map<String, double>? location;
    if (json['location'] != null) {
      location = LocationHelper.parsePostGISPoint(json['location']);
    }

    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      
      // Campos de técnico
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : null,
      coverageZones: json['coverage_zones'] != null
          ? List<String>.from(json['coverage_zones'] as List)
          : null,
      baseRate: json['base_rate'] != null
          ? (json['base_rate'] as num).toDouble()
          : null,
      bio: json['bio'] as String?,
      verificationStatus: json['verification_status'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,

      // Geolocalización
      latitude: location?['latitude'],
      longitude: location?['longitude'],
      address: json['address'] as String?,

      // Métricas
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      totalReviews: json['total_reviews'] as int?,
      completedServices: json['completed_services'] as int?,
    );
  }

  /// Convertir ProfileModel a JSON para Supabase
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Solo incluir campos de técnico si aplica
    if (isTechnician) {
      data['specialties'] = specialties;
      data['coverage_zones'] = coverageZones;
      data['base_rate'] = baseRate;
      data['bio'] = bio;
      data['verification_status'] = verificationStatus;
      data['verification_notes'] = verificationNotes;
      data['verified_at'] = verifiedAt?.toIso8601String();
    }

    // Geolocalización en formato PostGIS
    if (latitude != null && longitude != null) {
      data['location'] = LocationHelper.coordinatesToPostGIS(
        latitude!,
        longitude!,
      );
    }
    data['address'] = address;

    // Métricas
    data['average_rating'] = averageRating;
    data['total_reviews'] = totalReviews;
    data['completed_services'] = completedServices;

    return data;
  }

  /// Convertir a entidad de dominio
  Profile toEntity() {
    return Profile(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      profilePictureUrl: profilePictureUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      specialties: specialties,
      coverageZones: coverageZones,
      baseRate: baseRate,
      bio: bio,
      verificationStatus: verificationStatus,
      verificationNotes: verificationNotes,
      verifiedAt: verifiedAt,
      latitude: latitude,
      longitude: longitude,
      address: address,
      averageRating: averageRating,
      totalReviews: totalReviews,
      completedServices: completedServices,
    );
  }

  /// Crear ProfileModel desde Profile
  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      phone: profile.phone,
      role: profile.role,
      profilePictureUrl: profile.profilePictureUrl,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      specialties: profile.specialties,
      coverageZones: profile.coverageZones,
      baseRate: profile.baseRate,
      bio: profile.bio,
      verificationStatus: profile.verificationStatus,
      verificationNotes: profile.verificationNotes,
      verifiedAt: profile.verifiedAt,
      latitude: profile.latitude,
      longitude: profile.longitude,
      address: profile.address,
      averageRating: profile.averageRating,
      totalReviews: profile.totalReviews,
      completedServices: profile.completedServices,
    );
  }
}