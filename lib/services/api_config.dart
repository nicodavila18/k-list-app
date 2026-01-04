class ApiConfig {
  // 👇 Tu URL de Render (Ya no necesitamos puertos ni IPs locales)
  static const String _baseUrl = 'https://k-list-backend.onrender.com';

  /// Obtiene la URL base del Backend.
  /// Ahora es simple: siempre devuelve la dirección de la nube.
  static Future<String> getBaseUrl() async {
    return _baseUrl;
  }
}