import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:k_list/models/serie.dart';
import 'package:k_list/models/actor_favorito.dart';
import 'package:k_list/services/auth_service.dart';
import 'api_config.dart';

/// Servicio encargado de todas las peticiones HTTP al Backend (Python).
/// Maneja la inyección del Token de seguridad automáticamente.
class ApiService {
  final _authService = AuthService();

  // ==========================================
  // 🛡️ HELPERS PRIVADOS (Seguridad y Config)
  // ==========================================

  /// Genera las cabeceras HTTP necesarias, incluyendo el Token JWT.
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken(); 
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // 🔑 Llave de acceso
    };
  }

  /// Construye la URL completa basada en la configuración dinámica.
  Future<String> _getUrl(String endpoint) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    return '$baseUrl/$endpoint';
  }

  // ==========================================
  // 🎬 GESTIÓN DE SERIES
  // ==========================================

  /// Obtiene la lista de series y películas del usuario.
  Future<List<Serie>> getSeries() async {
    final url = await _getUrl('series');
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        // Usamos bodyBytes y utf8.decode para soportar tildes y caracteres coreanos
        final String body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => Serie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Guarda una nueva serie o película.
  Future<Serie?> addSerie(Serie serie) async {
    final url = await _getUrl('series');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(serie.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String body = utf8.decode(response.bodyBytes);
        return Serie.fromJson(jsonDecode(body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el estado, calificación o datos de una serie.
  Future<bool> updateSerie(Serie serie) async {
    if (serie.id == null) return false;
    final url = await _getUrl('series/${serie.id}');
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(serie.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Elimina una serie de la base de datos.
  Future<bool> deleteSerie(int id) async {
    final url = await _getUrl('series/$id');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // ⭐ GESTIÓN DE ACTORES (IDOLS)
  // ==========================================

  /// Obtiene la lista de actores favoritos.
  Future<List<ActorFavorito>> getActores() async {
    final url = await _getUrl('actores');
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => ActorFavorito.fromJson(json)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  /// Agrega un nuevo actor a favoritos.
  Future<ActorFavorito?> addActor(ActorFavorito actor) async {
    final url = await _getUrl('actores');
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(actor.toJson()),
      );
      
      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        return ActorFavorito.fromJson(jsonDecode(body));
      }
      return null;
    } catch (e) { return null; }
  }

  /// Elimina un actor usando su ID de TMDB (ruta especial).
  Future<bool> deleteActorByTmdb(int tmdbId) async {
    final url = await _getUrl('actores/tmdb/$tmdbId');
    final headers = await _getHeaders(); 
    
    try {
      final response = await http.delete(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}