// ignore: file_names
class ValidatorForm {
  // --- VALIDADOR PARA CORREO ELECTRÓNICO ---
  static String? validatorEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Es necesario ingresar un correo';
    }

    // Expresión regular para verificar formato estándar de email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
      r"'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r'{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]'
      r'{0,253}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo válido (ej. usuario@udla.edu.co)';
    }

    return null; // Retorna null si la validación es correcta
  }

  // --- VALIDADOR PARA CONTRASEÑA ---
  static String? validatorPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su contraseña';
    }

    if (value.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null; // Retorna null si la validación es correcta
  }
}