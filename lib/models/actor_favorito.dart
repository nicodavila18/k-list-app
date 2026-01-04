class ActorFavorito {
  int? id;
  int tmdbId;
  String nombre;
  String fotoUrl;

  ActorFavorito({
    this.id,
    required this.tmdbId,
    required this.nombre,
    required this.fotoUrl,
  });

  // Convertir de JSON (Backend) a Objeto Flutter
  factory ActorFavorito.fromJson(Map<String, dynamic> json) {
    return ActorFavorito(
      id: json['id'],
      tmdbId: json['tmdb_id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      // 👇 CORRECCIÓN: Asumimos 'foto_url' para consistencia con Python
      fotoUrl: json['foto_url'] ?? json['fotoUrl'] ?? '', 
    );
  }

  // Convertir de Objeto Flutter a JSON (Para enviar)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'nombre': nombre,
      'foto_url': fotoUrl, // snake_case
    };
  }
}