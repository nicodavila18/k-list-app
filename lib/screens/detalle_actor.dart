import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Servicios y Modelos
import 'package:k_list/services/api_service.dart';
import '../models/serie.dart';
import '../models/actor_favorito.dart';
import 'detalle_serie.dart';

class PantallaDetalleActor extends StatefulWidget {
  final int actorId;
  final String nombre;
  final String fotoUrl;
  
  // Datos opcionales para mantener sincronizada la lista de series
  final List<Serie> seriesGuardadas; 
  final Function(Serie)? onSerieAgregada;

  const PantallaDetalleActor({
    super.key, 
    required this.actorId, 
    required this.nombre, 
    required this.fotoUrl,
    this.seriesGuardadas = const [],
    this.onSerieAgregada,
  });

  @override
  State<PantallaDetalleActor> createState() => _PantallaDetalleActorState();
}

class _PantallaDetalleActorState extends State<PantallaDetalleActor> {
  final _apiService = ApiService();
  
  // Estado de UI
  bool _cargando = true;
  bool _bioExpandida = false;
  bool _esFavorito = false; 
  
  // Datos del Actor
  String _biografia = "Buscando biografía...";
  String _fechaNacimiento = "";
  String _lugarNacimiento = "";
  String _nombrePrincipal = "";
  String _nombreSecundario = ""; // Para nombres en Hangul u originales
  List<dynamic> _filmografia = [];
  
  // Caché local de series para saber cuáles ya tienes
  List<Serie> _misSeriesEnLaNube = [];

  @override
  void initState() {
    super.initState();
    _nombrePrincipal = widget.nombre;
    _inicializarDatos();
  }

  void _inicializarDatos() {
    _verificarFavorito(); 
    _cargarInfoActor();
    _cargarSeriesDelUsuario();
  }

  // ==========================================
  // ❤️ LÓGICA DE FAVORITOS (IDOLS)
  // ==========================================
  
  Future<void> _verificarFavorito() async {
    // Consultamos la API para saber si ya lo seguimos
    final actores = await _apiService.getActores();
    final encontrado = actores.any((a) => a.tmdbId == widget.actorId);
    if (mounted) setState(() => _esFavorito = encontrado);
  }

  Future<void> _toggleFavorito() async {
    // Cambio visual optimista (Feedback inmediato)
    setState(() => _esFavorito = !_esFavorito); 

    if (_esFavorito) {
      // GUARDAR
      final nuevoActor = ActorFavorito(
        tmdbId: widget.actorId, 
        nombre: _nombrePrincipal.isNotEmpty ? _nombrePrincipal : widget.nombre,
        fotoUrl: widget.fotoUrl,
      );
      
      final resultado = await _apiService.addActor(nuevoActor);
      
      if (resultado != null && mounted) {
        _mostrarMensaje("¡Idol guardado! ⭐");
      } else {
        setState(() => _esFavorito = false); // Revertir si falló
      }
    } else {
      // ELIMINAR
      final exito = await _apiService.deleteActorByTmdb(widget.actorId);
      
      if (exito && mounted) {
         _mostrarMensaje("Idol eliminado de tu colección 💔");
      } else {
        setState(() => _esFavorito = true); // Revertir si falló
      }
    }
  }

  // ==========================================
  // 📥 CARGA DE INFORMACIÓN (TMDB)
  // ==========================================

  bool _esCoreano(String texto) {
    return RegExp(r'[\uAC00-\uD7AF]').hasMatch(texto);
  }

  Future<void> _cargarInfoActor() async {
    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    // Intentamos cargar biografía en Español primero
    final urlBioEs = Uri.parse('https://api.themoviedb.org/3/person/${widget.actorId}?api_key=$apiKey&language=es-ES');
    final urlCredits = Uri.parse('https://api.themoviedb.org/3/person/${widget.actorId}/combined_credits?api_key=$apiKey&language=es-ES');

    try {
      var resBio = await http.get(urlBioEs);
      final resCredits = await http.get(urlCredits);

      if (resBio.statusCode == 200 && resCredits.statusCode == 200) {
        var dataBio = json.decode(resBio.body);
        final dataCredits = json.decode(resCredits.body);

        // 1. Biografía (Fallback a Inglés si no hay español)
        String bioTexto = dataBio['biography'] ?? "";
        if (bioTexto.isEmpty) {
           final urlBioEn = Uri.parse('https://api.themoviedb.org/3/person/${widget.actorId}?api_key=$apiKey&language=en-US');
           final resBioEn = await http.get(urlBioEn);
           if (resBioEn.statusCode == 200) {
             final dataBioEn = json.decode(resBioEn.body);
             bioTexto = dataBioEn['biography'] ?? "Biografía no disponible.";
           }
        }

        // 2. Manejo de Nombres (Coreano vs Latino)
        List<dynamic> alias = dataBio['also_known_as'] ?? [];
        String nombreActual = widget.nombre;
        
        if (_esCoreano(nombreActual)) {
           // Si el nombre viene en Coreano, buscamos el alias latino
           var aliasLatino = alias.firstWhere((a) => !_esCoreano(a), orElse: () => "");
           if (aliasLatino.isNotEmpty) {
             _nombrePrincipal = aliasLatino;
             _nombreSecundario = nombreActual;
           } else {
             _nombrePrincipal = nombreActual;
           }
        } else {
          // Si el nombre viene en Latino, buscamos el alias coreano
          var aliasCoreano = alias.firstWhere((a) => _esCoreano(a), orElse: () => "");
          _nombrePrincipal = nombreActual;
          _nombreSecundario = aliasCoreano;
        }

        // 3. Filmografía (Ordenada por popularidad)
        List<dynamic> trabajos = dataCredits['cast'];
        trabajos.sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));

        if (mounted) {
          setState(() {
            _biografia = bioTexto;
            _fechaNacimiento = dataBio['birthday'] ?? "";
            _lugarNacimiento = dataBio['place_of_birth'] ?? "";
            _filmografia = trabajos;
            _cargando = false;
          });
        }
      }
    } catch (_) { 
      // Error silencioso
    }
  }

  // ==========================================
  // 🎬 LÓGICA PARA AGREGAR SERIES DESDE EL PERFIL
  // ==========================================
  
  Future<void> _cargarSeriesDelUsuario() async {
    // 1. Carga rápida desde props
    if (widget.seriesGuardadas.isNotEmpty) {
      setState(() => _misSeriesEnLaNube = widget.seriesGuardadas);
    }
    
    // 2. Sincronización real con API
    final seriesActualizadas = await _apiService.getSeries();
    if (mounted) {
      setState(() => _misSeriesEnLaNube = seriesActualizadas);
    }
  }

  Future<void> _agregarSerieDesdeActor(dynamic serieData, {VoidCallback? onTerminado}) async {
    final posterPath = serieData['poster_path'];
    final titulo = serieData['name'] ?? serieData['title'] ?? 'Sin título';
    final fechaStr = serieData['first_air_date'] ?? serieData['release_date'];
    final anio = int.tryParse((fechaStr as String?)?.split('-').first ?? '0') ?? 0;
    final tipo = serieData['media_type'] == 'movie' ? 'movie' : 'tv';

    final nuevaSerie = Serie(
      tmdbId: serieData['id'],
      titulo: titulo,
      imagenUrl: posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '',
      estado: 'Por ver', calificacion: 0, comentario: '', plataforma: 'Desconocido', anioLanzamiento: anio, tipo: tipo, 
    );

    // OPCIÓN A: Usar callback del padre (si venimos de una pantalla que lo soporta)
    if (widget.onSerieAgregada != null) {
      await widget.onSerieAgregada!(nuevaSerie);
      if (mounted) {
        setState(() => _misSeriesEnLaNube.add(nuevaSerie));
        _mostrarMensaje("¡$titulo agregada! 🎬");
        if (onTerminado != null) onTerminado();
      }
    }
    // OPCIÓN B: Guardar directo usando el servicio (Stand-alone)
    else {
      final guardada = await _apiService.addSerie(nuevaSerie);
      if (mounted) {
         if (guardada != null) {
            _mostrarMensaje("¡$titulo agregada! ✅");
            setState(() => _misSeriesEnLaNube.add(guardada));
            if (onTerminado != null) onTerminado();
         } else {
            _mostrarMensaje("Error al guardar", esError: true);
         }
      }
    }
  }

  // ==========================================
  // 🎨 INTERFAZ GRÁFICA (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_esFavorito ? Icons.favorite : Icons.favorite_border, color: _esFavorito ? Colors.red : Colors.black, size: 30),
            onPressed: _toggleFavorito,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _cargando 
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FOTO Y DATOS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(widget.fotoUrl, width: 120, height: 180, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 120, height: 180, color: Colors.grey)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nombrePrincipal, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            if (_nombreSecundario.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 5), child: Text(_nombreSecundario, style: TextStyle(fontSize: 18, color: Colors.deepPurple[700]))),
                            const SizedBox(height: 20),
                            if (_fechaNacimiento.isNotEmpty) Text("🎂 $_fechaNacimiento", style: TextStyle(color: Colors.grey[800], fontSize: 15)),
                            const SizedBox(height: 8),
                            if (_lugarNacimiento.isNotEmpty) Text("📍 $_lugarNacimiento", style: TextStyle(color: Colors.grey[800], fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // 2. BIOGRAFÍA
                  const Text("Biografía", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _bioExpandida = !_bioExpandida),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_biografia, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87), maxLines: _bioExpandida ? null : 6, overflow: _bioExpandida ? TextOverflow.visible : TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Text(_bioExpandida ? "Leer menos" : "Leer más...", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // 3. FILMOGRAFÍA (CARRUSEL)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Conocido por", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: _mostrarFilmografiaCompleta, child: const Text("Ver todo →")),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filmografia.length > 10 ? 10 : _filmografia.length,
                      itemBuilder: (context, index) {
                         return Container(width: 105, margin: const EdgeInsets.only(right: 12), child: _itemFilmografia(_filmografia[index]));
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  // --- MODAL DE FILMOGRAFÍA COMPLETA ---
  void _mostrarFilmografiaCompleta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 15),
                    const Text("Filmografía Completa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: _filmografia.length,
                        itemBuilder: (context, index) => _itemFilmografia(
                          _filmografia[index], 
                          onRebuild: () => setModalState(() {}) // Fuerza repintado del modal
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        );
      },
    );
  }

  // WIDGET ITEM (Tarjeta de película/serie)
  Widget _itemFilmografia(dynamic trabajo, {VoidCallback? onRebuild}) {
    final poster = trabajo['poster_path'];
    final titulo = trabajo['title'] ?? trabajo['name'] ?? '';
    final int tmdbId = trabajo['id'];
    
    if (poster == null) return const SizedBox();

    // Verificamos si ya la tenemos en la colección
    bool yaLaTengo = false;
    Serie? serieExistente;
    try {
      serieExistente = _misSeriesEnLaNube.firstWhere((s) => s.tmdbId == tmdbId);
      yaLaTengo = true;
    } catch (_) { yaLaTengo = false; }

    return GestureDetector(
      onTap: () {
        if (yaLaTengo && serieExistente != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: serieExistente!)));
        } else {
          // Vista previa
          final fechaStr = trabajo['first_air_date'] ?? trabajo['release_date'];
          final anio = int.tryParse((fechaStr as String?)?.split('-').first ?? '0') ?? 0;
          final tipo = trabajo['media_type'] == 'movie' ? 'movie' : 'tv';

          final tempSerie = Serie(
            tmdbId: tmdbId, titulo: titulo, imagenUrl: 'https://image.tmdb.org/t/p/w500$poster',
            estado: 'Por ver', calificacion: 0, comentario: '', plataforma: 'Desconocido', anioLanzamiento: anio, tipo: tipo
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: tempSerie)));
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network('https://image.tmdb.org/t/p/w200$poster', fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 5),
              Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ],
          ),
          
          // Botón de Acción (Lápiz o Más)
          Positioned(
            top: 4, right: 4,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: yaLaTengo ? Colors.blue : Colors.deepPurple,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(yaLaTengo ? Icons.edit : Icons.add, size: 18, color: Colors.white),
                onPressed: () {
                   if (yaLaTengo && serieExistente != null) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: serieExistente!)));
                   } else {
                     _agregarSerieDesdeActor(trabajo, onTerminado: onRebuild);
                   }
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  // Notificación visual
  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(esError ? Icons.error_outline : Icons.check_circle, color: esError ? Colors.white : const Color(0xFFFFC107)),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: esError ? Colors.redAccent : const Color(0xFF0A1931),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      )
    );
  }
}