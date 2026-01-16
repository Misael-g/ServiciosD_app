import '../entities/profile.dart';

/// Repositorio de perfiles (interfaz)
abstract class ProfilesRepository {
  /// Obtener perfil por ID
  Future<Profile> getProfileById(String userId);

  /// Obtener perfil del usuario actual
  Future<Profile> getCurrentUserProfile();

  /// Actualizar perfil
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
    List<String>? specialties,
    List<String>? coverageZones,
    double? baseRate,
  });

  /// Actualizar ubicación
  Future<Profile> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String address,
  });

  /// Obtener técnicos cercanos
  Future<List<Profile>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  });
}