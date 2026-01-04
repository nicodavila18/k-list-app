import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;

/// Configuración centralizada de la API.
/// Maneja la detección automática de IP para Desarrollo (Emulador vs Físico).
class ApiConfig {
  // 👇 CAMBIA ESTO cuando tu PC cambie de IP
  static const String _ipPC = "192.168.1.71"; 
  static const String _puerto = "8000";

  // Variable para guardar la URL y no calcularla cada vez (Singleton/Cache)
  static String? _urlGuardada;

  /// Obtiene la URL base del Backend.
  /// Detecta automáticamente si estamos en Web, Emulador o Dispositivo Físico.
  static Future<String> getBaseUrl() async {
    // ⚡ OPTIMIZACIÓN: Si ya calculamos la URL antes, la devolvemos directo.
    if (_urlGuardada != null) return _urlGuardada!;

    // 1. Entorno Web
    if (kIsWeb) {
      _urlGuardada = 'http://127.0.0.1:$_puerto';
      return _urlGuardada!;
    }

    // 2. Entorno Android (Detección Inteligente)
    if (Platform.isAndroid) {
      try {
        // Intentamos un "ping" ultrarrápido al emulador (200ms)
        final urlEmulador = Uri.parse('http://10.0.2.2:$_puerto/');
        await http.get(urlEmulador).timeout(const Duration(milliseconds: 200));
        
        // Si responde, es el emulador
        _urlGuardada = 'http://10.0.2.2:$_puerto';
      } catch (e) {
        // Si falla o tarda, asumimos que es un celular físico
        _urlGuardada = 'http://$_ipPC:$_puerto';
      }
    } else {
      // 3. iOS u otros
      _urlGuardada = 'http://$_ipPC:$_puerto';
    }

    return _urlGuardada!;
  }
}