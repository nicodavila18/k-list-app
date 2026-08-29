import 'dart:convert';
import 'dart:async'; // Necesario para Timeout
import 'package:http/http.dart' as http;
import 'package:k_list/models/serie.dart';
import 'package:k_list/models/actor_favorito.dart';
import 'package:k_list/services/auth_service.dart';
import 'api_config.dart';

class ApiService {
  final _authService = AuthService();

  // 🛡️ HELPERS
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken(); 
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", 
    };
  }

  Future<String> _getUrl(String endpoint) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    return '$baseUrl/$endpoint';
  }

  // ==========================================
  // 🎬 GESTIÓN DE SERIES
  // ==========================================
  Future<List<Serie>> getSeries() async {
    final url = await _getUrl('series');
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 60)); // ⏳ 60s

      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => Serie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Serie?> addSerie(Serie serie) async {
    final url = await _getUrl('series');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(serie.toJson()),
      ).timeout(const Duration(seconds: 60)); // ⏳ 60s

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String body = utf8.decode(response.bodyBytes);
        return Serie.fromJson(jsonDecode(body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateSerie(Serie serie) async {
    if (serie.id == null) return false;
    final url = await _getUrl('series/${serie.id}');
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(serie.toJson()),
      ).timeout(const Duration(seconds: 60)); // ⏳ 60s
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSerie(int id) async {
    final url = await _getUrl('series/$id');
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 60)); // ⏳ 60s
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // ⭐ GESTIÓN DE ACTORES
  // ==========================================
  Future<List<ActorFavorito>> getActores() async {
    final url = await _getUrl('actores');
    final headers = await _getHeaders();
    
    try {
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 60)); // ⏳ 60s
      
      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => ActorFavorito.fromJson(json)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<ActorFavorito?> addActor(ActorFavorito actor) async {
    final url = await _getUrl('actores');
    final headers = await _getHeaders();
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(actor.toJson()),
      ).timeout(const Duration(seconds: 60)); // ⏳ 60s
      
      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        return ActorFavorito.fromJson(jsonDecode(body));
      }
      return null;
    } catch (e) { return null; }
  }

  Future<bool> deleteActorByTmdb(int tmdbId) async {
    final url = await _getUrl('actores/tmdb/$tmdbId');
    final headers = await _getHeaders(); 
    
    try {
      final response = await http.delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 60)); // ⏳ 60s
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🤖 RECOMENDACIONES DE INTELIGENCIA ARTIFICIAL
  // ==========================================
  Future<List<Map<String, dynamic>>> getRecomendacionesIA() async {
    final url = await _getUrl('recomendaciones');
    final headers = await _getHeaders();

    try {
      // Le damos un poco más de tiempo (90s) porque la IA puede tardar unos segundos en pensar
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 90)); 

      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(body);
        
        // Convertimos la respuesta en una lista que Flutter pueda usar fácilmente
        return data.map((item) => {
          "titulo": item["titulo"],
          "razon": item["razon"]
        }).toList();
      }
      return [];
    } catch (e) {
      return []; // Si falla, devolvemos una lista vacía
    }
  }
}