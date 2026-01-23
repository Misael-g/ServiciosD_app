import 'package:geolocator/geolocator.dart';

/// Helper para manejo de geolocalización
class LocationHelper {
  /// Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verificar permisos de ubicación
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Solicitar permisos de ubicación
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Verificar y solicitar permisos si es necesario
  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtener la ubicación actual
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calcular distancia entre dos puntos (en metros)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Formatear distancia a texto legible
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  /// Convertir Position a formato para Supabase (PostGIS)
  /// Formato: POINT(longitude latitude)
  static String positionToPostGIS(Position position) {
    return 'POINT(${position.longitude} ${position.latitude})';
  }

  /// Convertir coordenadas a formato para Supabase (PostGIS)
  static String coordinatesToPostGIS(double latitude, double longitude) {
    return 'POINT($longitude $latitude)';
  }

  /// Parsear coordenadas desde PostGIS
  /// Formato recibido: POINT(longitude latitude)
  static Map<String, double>? parsePostGISPoint(String? point) {
    if (point == null || point.isEmpty) return null;

    try {
      // Remover "POINT(" y ")"
      final coords = point
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');

      if (coords.length != 2) return null;

      return {
        'latitude': double.parse(coords[1]),
        'longitude': double.parse(coords[0]),
      };
    } catch (e) {
      return null;
    }
  }

  /// Obtener ubicación en tiempo real (stream)
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    );
  }

  /// Abrir configuración de ubicación del dispositivo
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abrir configuración de la app
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}