/// Estados de verificación de técnicos
class VerificationStates {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  /// Obtener el nombre legible del estado
  static String getDisplayName(String state) {
    switch (state) {
      case pending:
        return 'Pendiente de Aprobación';
      case approved:
        return 'Verificado';
      case rejected:
        return 'Rechazado';
      default:
        return 'Sin Verificar';
    }
  }

  /// Obtener el color asociado al estado
  static int getStateColor(String state) {
    switch (state) {
      case pending:
        return 0xFFFFA726; // Naranja
      case approved:
        return 0xFF4CAF50; // Verde
      case rejected:
        return 0xFFEF5350; // Rojo
      default:
        return 0xFF757575; // Gris
    }
  }

  /// Verificar si un estado es válido
  static bool isValid(String state) {
    return [pending, approved, rejected].contains(state);
  }

  /// Verificar si el técnico puede enviar cotizaciones
  static bool canSendQuotations(String? state) {
    return state == approved;
  }
}

/// Tipos de documentos de verificación
class DocumentTypes {
  static const String idFront = 'id_front';
  static const String idBack = 'id_back';
  static const String certificate = 'certificate';

  static String getDisplayName(String type) {
    switch (type) {
      case idFront:
        return 'Cédula (Frontal)';
      case idBack:
        return 'Cédula (Posterior)';
      case certificate:
        return 'Certificado Profesional';
      default:
        return 'Documento';
    }
  }

  /// Lista de todos los tipos de documentos requeridos
  static List<String> get allTypes => [idFront, idBack, certificate];

  /// Verificar si todos los documentos fueron subidos
  static bool allDocumentsUploaded(List<String> uploadedTypes) {
    return allTypes.every((type) => uploadedTypes.contains(type));
  }
}

/// Roles de usuario
class UserRoles {
  static const String client = 'client';
  static const String technician = 'technician';
  static const String admin = 'admin';

  static String getDisplayName(String role) {
    switch (role) {
      case client:
        return 'Cliente';
      case technician:
        return 'Técnico';
      case admin:
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  static bool isValid(String role) {
    return [client, technician, admin].contains(role);
  }

  /// Solo estos roles pueden registrarse desde la app
  static List<String> get registerableRoles => [client, technician];
}