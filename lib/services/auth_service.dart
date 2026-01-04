import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';

class AuthService {
  // Instancias de servicios externos
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage(); // Almacenamiento seguro (Keystore/Keychain)
  
  // Configuración de Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  // Stream para escuchar cambios de estado en tiempo real (Login/Logout)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ==========================================
  // 🌐 LOGIN CON GOOGLE
  // Maneja el flujo completo: Google -> Firebase -> Backend Python
  // ==========================================
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Iniciar flujo visual de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      // 2. Obtener credenciales (Tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Autenticar en Firebase con esas credenciales
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      // 4. Sincronizar con Backend Python (Intercambio de Token)
      if (user != null) {
        // Priorizamos el accessToken, pero tenemos un fallback al ID Token si falla
        String? tokenParaEnviar = googleAuth.accessToken;
        
        if (tokenParaEnviar == null) {
            // Intento de recuperación de seguridad
            tokenParaEnviar = await user.getIdToken();
        }
        
        if (tokenParaEnviar != null) {
            await _canjearTokenConPython(tokenParaEnviar);
        }
      }
      
      return user;
    } catch (e) {
      // Aquí podrías enviar el error a un servicio de logs como Sentry o Crashlytics
      return null;
    }
  }

  // Enviar el token de Google a Python para recibir nuestro propio JWT
  Future<void> _canjearTokenConPython(String googleToken) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/login/google');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": googleToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Éxito: Guardamos la sesión de forma segura
        await _guardarSesion(
            data['usuario_id'], 
            data['usuario_nombre'], 
            data['access_token']
        );
      }
    } catch (e) {
      // Manejo silencioso de error de conexión (el usuario verá el error en la UI si no avanza)
    }
  }

  // ==========================================
  // 📧 LOGIN TRADICIONAL (EMAIL/PASS)
  // ==========================================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ Éxito: Guardamos sesión
        await _guardarSesion(data['usuario_id'], data['usuario_nombre'], data['access_token']);
        return data;
      } else {
        return null; // Credenciales inválidas
      }
    } catch (e) { 
      return null; // Error de conexión o timeout
    }
  }

  // ==========================================
  // 📝 REGISTRO DE USUARIO
  // ==========================================
  Future<bool> registrar(String nombre, String email, String password) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/registro');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre,
          "email": email,
          "password": password
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🔐 GESTIÓN DE SESIÓN (SECURE STORAGE)
  // ==========================================

  // Guardar datos sensibles encriptados
  Future<void> _guardarSesion(int id, String nombre, String token) async {
    await _storage.write(key: 'userId', value: id.toString());
    await _storage.write(key: 'userName', value: nombre);
    await _storage.write(key: 'authToken', value: token);
    
    // Flag simple para comprobaciones rápidas de UI (no sensible)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  // Recuperar Token para peticiones a la API
  Future<String?> getToken() async {
    return await _storage.read(key: 'authToken');
  }

  // Cerrar Sesión (Limpieza total)
  Future<void> logout() async {
    // 1. Cerrar servicios externos
    try {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
    } catch (_) {}
    
    // 2. Eliminar datos sensibles de la caja fuerte
    await _storage.deleteAll();

    // 3. Eliminar flag de sesión, PERO mantenemos la foto local (SharedPrefs)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }
}