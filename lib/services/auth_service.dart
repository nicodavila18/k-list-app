import 'dart:convert';
import 'dart:async'; // Necesario para el Timeout
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage(); 
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ==========================================
  // 🌐 LOGIN CON GOOGLE
  // ==========================================
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        String? tokenParaEnviar = googleAuth.accessToken;
        if (tokenParaEnviar == null) {
            tokenParaEnviar = await user.getIdToken();
        }
        if (tokenParaEnviar != null) {
            await _canjearTokenConPython(tokenParaEnviar);
        }
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _canjearTokenConPython(String googleToken) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/login/google');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": googleToken}),
      ).timeout(const Duration(seconds: 60)); // ⏳ PACIENCIA: 60 seg

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _guardarSesion(
            data['usuario_id'], 
            data['usuario_nombre'], 
            data['access_token']
        );
      }
    } catch (e) {
      // Si falla por timeout, se manejará en la UI
    }
  }

  // ==========================================
  // 📧 LOGIN TRADICIONAL
  // ==========================================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 60)); // ⏳ PACIENCIA: 60 seg (Antes 5)

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _guardarSesion(data['usuario_id'], data['usuario_nombre'], data['access_token']);
        return data;
      } else {
        return null; 
      }
    } catch (e) { 
      return null; 
    }
  }

  // ==========================================
  // 📝 REGISTRO
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
      ).timeout(const Duration(seconds: 60)); // ⏳ PACIENCIA: 60 seg (Antes 5)

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🔐 GESTIÓN DE SESIÓN
  // ==========================================
  Future<void> _guardarSesion(int id, String nombre, String token) async {
    await _storage.write(key: 'userId', value: id.toString());
    await _storage.write(key: 'userName', value: nombre);
    await _storage.write(key: 'authToken', value: token);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'authToken');
  }

  Future<void> logout() async {
    try {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
    } catch (_) {}
    
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }
}