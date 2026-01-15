/// Validadores para formularios
class Validators {
  /// Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  /// Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  /// Validar confirmación de contraseña
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Validar nombre completo
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre completo es requerido';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  /// Validar teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    // Acepta números con o sin espacios/guiones
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{8,}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Teléfono inválido';
    }

    return null;
  }

  /// Validar campo requerido genérico
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Validar precio
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es requerido';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Ingresa un precio válido';
    }

    return null;
  }

  /// Validar duración (minutos)
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'La duración es requerida';
    }

    final duration = int.tryParse(value);
    if (duration == null || duration <= 0) {
      return 'Ingresa una duración válida (en minutos)';
    }

    return null;
  }

  /// Validar rating (1-5)
  static String? validateRating(int? value) {
    if (value == null || value < 1 || value > 5) {
      return 'Selecciona una calificación (1-5)';
    }
    return null;
  }

  /// Validar descripción
  static String? validateDescription(String? value, {int minLength = 10}) {
    if (value == null || value.isEmpty) {
      return 'La descripción es requerida';
    }

    if (value.length < minLength) {
      return 'La descripción debe tener al menos $minLength caracteres';
    }

    return null;
  }
}