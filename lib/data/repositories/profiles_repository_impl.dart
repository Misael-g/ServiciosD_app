import '../../domain/entities/profile.dart';
import '../../domain/repositories/profiles_repository.dart';
import '../datasources/profiles_remote_ds.dart';

/// Implementación del repositorio de perfiles
class ProfilesRepositoryImpl implements ProfilesRepository {
  final ProfilesRemoteDataSource _remoteDataSource;

  ProfilesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Profile> getProfileById(String userId) async {
    try {
      final profileModel = await _remoteDataSource.getProfileById(userId);
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  @override
  Future<Profile> getCurrentUserProfile() async {
    try {
      final profileModel = await _remoteDataSource.getCurrentUserProfile();
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al obtener perfil actual: $e');
    }
  }

  @override
  Future<Profile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
    List<String>? specialties,
    List<String>? coverageZones,
    double? baseRate,
  }) async {
    try {
      final profileModel = await _remoteDataSource.updateProfileFields(
        userId: userId,
        updates: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (specialties != null) 'specialties': specialties,
          if (coverageZones != null) 'coverage_zones': coverageZones,
          if (baseRate != null) 'base_rate': baseRate,
        },
      );
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  @override
  Future<Profile> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final profileModel = await _remoteDataSource.updateLocation(
        userId,
        latitude,
        longitude,
        address,
      );
      return profileModel.toEntity();
    } catch (e) {
      throw Exception('Error al actualizar ubicación: $e');
    }
  }

  @override
  Future<List<Profile>> getNearbyTechnicians({
    required double latitude,
    required double longitude,
    required String serviceType,
    int radiusMeters = 10000,
  }) async {
    try {
      final profileModels = await _remoteDataSource.getNearbyTechnicians(
        latitude: latitude,
        longitude: longitude,
        serviceType: serviceType,
        radiusMeters: radiusMeters,
      );
      return profileModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al obtener técnicos cercanos: $e');
    }
  }
}