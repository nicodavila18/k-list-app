class Serie {
  int? id;
  int tmdbId;
  String titulo;
  String imagenUrl;
  String estado;       // 'Por ver', 'Viendo', 'Terminada', 'Abandonada'
  double calificacion; // 1.0 a 5.0
  String comentario;
  String plataforma;   // 'Netflix', 'Viki', etc.
  int anioLanzamiento;
  String tipo;         // 'tv' o 'movie'
  
  // Nuevos campos de progreso
  int episodiosVistos;
  int totalEpisodios;

  Serie({
    this.id,
    required this.tmdbId,
    required this.titulo,
    required this.imagenUrl,
    required this.estado,
    required this.calificacion,
    required this.comentario,
    required this.plataforma,
    required this.anioLanzamiento,
    required this.tipo,
    this.episodiosVistos = 0,
    this.totalEpisodios = 0,
  });

  // De JSON (Backend) a Objeto Flutter
  factory Serie.fromJson(Map<String, dynamic> json) {
    return Serie(
      id: json['id'],
      tmdbId: json['tmdb_id'] ?? 0,
      titulo: json['titulo'] ?? 'Sin título',
      // 👇 CORRECCIÓN: Usamos snake_case para coincidir con Python
      imagenUrl: json['imagen_url'] ?? json['imagenUrl'] ?? '',
      estado: json['estado'] ?? 'Por ver',
      calificacion: (json['calificacion'] ?? 0).toDouble(),
      comentario: json['comentario'] ?? '',
      plataforma: json['plataforma'] ?? 'Desconocido',
      anioLanzamiento: json['anio_lanzamiento'] ?? json['anioLanzamiento'] ?? 0,
      tipo: json['tipo'] ?? 'tv',
      episodiosVistos: json['episodios_vistos'] ?? 0,
      totalEpisodios: json['total_episodios'] ?? 0,
    );
  }

  // De Objeto Flutter a JSON (Para enviar a Backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'titulo': titulo,
      'imagen_url': imagenUrl, // snake_case
      'estado': estado,
      'calificacion': calificacion,
      'comentario': comentario,
      'plataforma': plataforma,
      'anio_lanzamiento': anioLanzamiento, // snake_case
      'tipo': tipo,
      'episodios_vistos': episodiosVistos,
      'total_episodios': totalEpisodios,
    };
  }
}