/// Fuente de datos remota para servicios
/// 
/// Este datasource está reservado para funcionalidades futuras
/// relacionadas con catálogo de servicios, tipos de servicios, etc.
class ServicesRemoteDataSource {

  // TODO: Implementar funcionalidades de catálogo de servicios
  
  /// Obtener tipos de servicios disponibles
  Future<List<String>> getServiceTypes() async {
    try {
      // Por ahora retornar lista hardcodeada
      // En el futuro se puede obtener de una tabla 'service_types'
      return [
        'Electricista',
        'Plomero',
        'Carpintero',
        'Pintor',
        'Mecánico',
        'Jardinero',
        'Limpieza',
        'Reparación de Electrodomésticos',
        'Instalación de TV/Internet',
        'Otros',
      ];
    } catch (e) {
      throw Exception('Error al obtener tipos de servicios: $e');
    }
  }

  /// Obtener descripción de un tipo de servicio
  Future<String?> getServiceTypeDescription(String serviceType) async {
    try {
      // TODO: Obtener de base de datos
      final descriptions = {
        'Electricista': 'Instalación y reparación de sistemas eléctricos',
        'Plomero': 'Instalación y reparación de tuberías y sanitarios',
        'Carpintero': 'Trabajos en madera y muebles',
        'Pintor': 'Pintura de interiores y exteriores',
        'Mecánico': 'Reparación de vehículos',
        'Jardinero': 'Mantenimiento de jardines y áreas verdes',
        'Limpieza': 'Servicios de limpieza profesional',
        'Reparación de Electrodomésticos': 'Reparación de lavadoras, refrigeradoras, etc.',
        'Instalación de TV/Internet': 'Instalación de equipos y redes',
      };
      
      return descriptions[serviceType];
    } catch (e) {
      return null;
    }
  }
}