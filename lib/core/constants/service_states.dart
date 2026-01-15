/// Estados posibles de una solicitud de servicio
class ServiceStates {
  static const String pending = 'pending';
  static const String quotationSent = 'quotation_sent';
  static const String quotationAccepted = 'quotation_accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String rated = 'rated';
  static const String cancelled = 'cancelled';

  /// Obtener el nombre legible del estado
  static String getDisplayName(String state) {
    switch (state) {
      case pending:
        return 'Pendiente';
      case quotationSent:
        return 'Cotización Enviada';
      case quotationAccepted:
        return 'Cotización Aceptada';
      case inProgress:
        return 'En Progreso';
      case completed:
        return 'Completado';
      case rated:
        return 'Calificado';
      case cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtener el color asociado al estado
  static int getStateColor(String state) {
    switch (state) {
      case pending:
        return 0xFFFFA726; // Naranja
      case quotationSent:
        return 0xFF42A5F5; // Azul
      case quotationAccepted:
        return 0xFF66BB6A; // Verde claro
      case inProgress:
        return 0xFF29B6F6; // Azul claro
      case completed:
        return 0xFF4CAF50; // Verde
      case rated:
        return 0xFF9C27B0; // Púrpura
      case cancelled:
        return 0xFFEF5350; // Rojo
      default:
        return 0xFF757575; // Gris
    }
  }

  /// Verificar si un estado es válido
  static bool isValid(String state) {
    return [
      pending,
      quotationSent,
      quotationAccepted,
      inProgress,
      completed,
      rated,
      cancelled,
    ].contains(state);
  }
}

/// Estados de cotización
class QuotationStates {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';

  static String getDisplayName(String state) {
    switch (state) {
      case pending:
        return 'Pendiente';
      case accepted:
        return 'Aceptada';
      case rejected:
        return 'Rechazada';
      default:
        return 'Desconocido';
    }
  }
}