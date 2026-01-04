import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // 👈 Necesario para el Debounce (Timer)
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Modelos y Pantallas
import 'package:k_list/models/serie.dart';
import 'package:k_list/models/actor_favorito.dart';
import 'package:k_list/screens/detalle_serie.dart'; 
import 'package:k_list/screens/detalle_actor.dart'; 

class PantallaDescubrir extends StatefulWidget {
  final Function(Serie) onSerieAgregada; 
  final Function(ActorFavorito) onActorAgregado;
  final List<Serie> seriesGuardadas;
  final List<ActorFavorito> actoresGuardados;

  const PantallaDescubrir({
    super.key, 
    required this.onSerieAgregada,
    required this.onActorAgregado,
    required this.seriesGuardadas,
    required this.actoresGuardados,
  });

  @override
  State<PantallaDescubrir> createState() => _PantallaDescubrirState();
}

class _PantallaDescubrirState extends State<PantallaDescubrir> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _resultadosBusqueda = []; 
  bool _buscando = false; 
  late TabController _tabController;
  Timer? _debounce; // ⏱️ Timer para controlar la búsqueda

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Escuchamos el teclado
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Limpiamos el timer
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🧠 LÓGICA DE BÚSQUEDA (OPTIMIZADA)
  // ==========================================
  void _onSearchChanged() {
    // Si borró todo, volvemos a las pestañas
    if (_searchController.text.isEmpty) {
      if (_buscando) setState(() => _buscando = false);
      return;
    }

    // Activamos modo búsqueda visualmente
    if (!_buscando) setState(() => _buscando = true);

    // Cancelamos búsqueda anterior si sigue escribiendo
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Esperamos 500ms antes de llamar a la API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscarEnTMDB(_searchController.text);
    });
  }

  Future<void> _buscarEnTMDB(String query) async {
    if (query.isEmpty) return;
    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    
    // Usamos 'es-MX' para mejores resultados en Latino
    final url = Uri.parse('https://api.themoviedb.org/3/search/multi?api_key=$apiKey&query=$query&language=es-MX&include_adult=false');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _resultadosBusqueda = data['results']; 
          });
        }
      }
    } catch (_) {
      // Error silencioso en UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 80, 
        backgroundColor: const Color(0xFFF8F9FA), 
        elevation: 0,
        title: _buildSearchBar(), // Barra de búsqueda extraída
      ),

      body: Column(
        children: [
          // Solo mostramos tabs si NO estamos buscando
          if (!_buscando) 
            Container(
              color: const Color(0xFFF8F9FA),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0A1931),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFFC107),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Corea 🇰🇷"),
                  Tab(text: "Japón 🇯🇵"),
                  Tab(text: "Tailandia 🇹🇭"),
                ],
              ),
            ),
          
          Expanded(
            child: _buscando 
              ? _buildResultadosBusqueda() 
              : TabBarView(
                  controller: _tabController,
                  children: [
                     _ListaRecomendada(pais: "KR", onSerieAgregada: widget.onSerieAgregada, seriesGuardadas: widget.seriesGuardadas),
                     _ListaRecomendada(pais: "JP", onSerieAgregada: widget.onSerieAgregada, seriesGuardadas: widget.seriesGuardadas),
                     _ListaRecomendada(pais: "TH", onSerieAgregada: widget.onSerieAgregada, seriesGuardadas: widget.seriesGuardadas),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Series, Pelis o Idols...",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0A1931)),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          filled: false,
        ),
      ),
    );
  }

  // ==========================================
  // 📋 RESULTADOS DE BÚSQUEDA
  // ==========================================
  Widget _buildResultadosBusqueda() {
    if (_resultadosBusqueda.isEmpty) {
      return Center(child: Text("No encontramos nada...", style: TextStyle(color: Colors.grey[400])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _resultadosBusqueda.length,
      itemBuilder: (context, index) {
        final json = _resultadosBusqueda[index];
        final mediaType = json['media_type'] ?? 'tv';
        
        // Extracción de datos segura
        final String titulo = json['name'] ?? json['title'] ?? 'Sin título';
        final String? path = json['poster_path'] ?? json['profile_path'];
        final String imagenUrl = path != null ? 'https://image.tmdb.org/t/p/w500$path' : '';
        
        // Configuración visual según tipo
        String subtitulo = "Desconocido";
        IconData iconoTipo = Icons.tv;

        bool yaTengoActor = false;
        bool yaTengoSerie = false;
        Serie? serieExistente;
        
        
        if (mediaType == 'person') {
          subtitulo = "Actor / Idol ⭐";
          iconoTipo = Icons.person;
          yaTengoActor = widget.actoresGuardados.any((a) => a.tmdbId == json['id']);
        } else if (mediaType == 'movie') {
          subtitulo = "Película 🎬";
          iconoTipo = Icons.movie;
        } else {
          String fecha = json['first_air_date'] ?? '';
          String anio = fecha.length >= 4 ? fecha.substring(0, 4) : '????';
          subtitulo = "Serie • $anio";
        }

        // ¿Ya la tengo guardada?
        if (mediaType != 'person') {
          try {
            serieExistente = widget.seriesGuardadas.firstWhere((s) => s.tmdbId == json['id']);
            yaTengoSerie = true;
          } catch (_) {}
        }

        return Card(
          elevation: 0, color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imagenUrl.isNotEmpty 
                ? Image.network(imagenUrl, width: 50, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 80, color: Colors.grey[200], child: Icon(iconoTipo, color: Colors.grey)))
                : Container(width: 50, height: 80, color: Colors.grey[200], child: Icon(iconoTipo, color: Colors.grey)),
            ),
            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitulo, style: TextStyle(color: Colors.blueGrey[400])),
                
                // Etiquetas de "YA LO TIENES"
                if (yaTengoSerie) 
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("EN TU LISTA", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (yaTengoActor)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("FAVORITO ❤️", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            
            // LÓGICA DEL CLIC
            onTap: () {
               if (yaTengoSerie && serieExistente != null) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: serieExistente!)));
               } 
               else if (mediaType == 'person') {
                 if (yaTengoActor) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya es tu favorito! ❤️"), backgroundColor: Colors.redAccent));
                 } else {
                   // Ir al detalle para agregar
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleActor(
                     actorId: json['id'], nombre: titulo, fotoUrl: imagenUrl,
                     seriesGuardadas: widget.seriesGuardadas, onSerieAgregada: widget.onSerieAgregada,
                   )));
                 }
               } 
               else {
                 final tempSerie = _crearSerieTemporal(json, mediaType, titulo, imagenUrl);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: tempSerie)));
               }
            },

            // BOTÓN LATERAL (Aquí ponemos el corazón o el +)
            trailing: _buildBotonAccion(
              yaTengoSerie: yaTengoSerie, 
              yaTengoActor: yaTengoActor, 
              mediaType: mediaType,
              json: json, titulo: titulo, imagenUrl: imagenUrl, serieExistente: serieExistente
            ),
          ),
        );
      },
    );
  }

  // WIDGET AUXILIAR PARA EL BOTÓN
  Widget _buildBotonAccion({
    required bool yaTengoSerie, 
    required bool yaTengoActor, 
    required String mediaType,
    required dynamic json,
    required String titulo,
    required String imagenUrl,
    Serie? serieExistente
  }) {
    // CASO 1: IDOL YA AGREGADO -> ❤️
    if (mediaType == 'person' && yaTengoActor) {
      return IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red, size: 32),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya lo tienes en tu corazón! ❤️")));
        },
      );
    }

    // CASO 2: SERIE YA AGREGADA -> Lápiz Azul ✏️
    if (yaTengoSerie) {
      return IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue, size: 32),
        onPressed: () {
          if (serieExistente != null) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: serieExistente)));
          }
        },
      );
    }

    // CASO 3: NO LO TENGO -> Botón Amarillo (+)
    return IconButton(
      icon: const Icon(Icons.add_circle, color: Color(0xFFFFC107), size: 32),
      onPressed: () {
        _procesarAgregado(json, mediaType, titulo, imagenUrl);
      },
    );
  }

  // Helper para crear objeto Serie rápido
  Serie _crearSerieTemporal(dynamic json, String mediaType, String titulo, String imagenUrl) {
    String fecha = json['first_air_date'] ?? json['release_date'] ?? ''; 
    String anioStr = fecha.length >= 4 ? fecha.substring(0, 4) : '0';
    return Serie(
      id: null, tmdbId: json['id'], titulo: titulo, imagenUrl: imagenUrl,
      estado: 'Por ver', calificacion: 0, episodiosVistos: 0, totalEpisodios: 0, comentario: '', plataforma: 'Desconocido',
      anioLanzamiento: int.tryParse(anioStr) ?? 0,
      tipo: (mediaType == 'movie') ? 'movie' : 'tv'
    );
  }

  // ==========================================
  // ➕ LÓGICA DE AGREGADO (Con Traducción)
  // ==========================================
  Future<void> _procesarAgregado(dynamic json, String mediaType, String tituloOriginal, String imagenUrl) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Agregar a tu lista?"),
        content: Text("Vas a agregar '$tituloOriginal'"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _searchController.clear(); 
              
              if (mediaType == 'person') {
                String nombreFinal = tituloOriginal;
                // Si es nombre coreano, intentamos traducir al inglés (más común internacionalmente)
                if (_esCoreano(tituloOriginal)) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Traduciendo nombre... 🌏"), duration: Duration(milliseconds: 500)));
                   nombreFinal = await _traducirNombreActor(json['id']) ?? tituloOriginal;
                }

                final nuevoActor = ActorFavorito(
                  id: null, tmdbId: json['id'], nombre: nombreFinal,
                  fotoUrl: imagenUrl.isNotEmpty ? imagenUrl : 'https://via.placeholder.com/150',
                );
                widget.onActorAgregado(nuevoActor); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Idol agregado! ⭐")));

              } else {
                final nuevaSerie = _crearSerieTemporal(json, mediaType, tituloOriginal, imagenUrl);
                widget.onSerieAgregada(nuevaSerie); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Agregado a tu colección! 🎬")));
              }
            },
            child: const Text("AGREGAR"),
          )
        ],
      ),
    );
  }

  Future<String?> _traducirNombreActor(int id) async {
    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    final url = Uri.parse('https://api.themoviedb.org/3/person/$id?api_key=$apiKey&language=en-US');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['name'];
      }
    } catch (_) {}
    return null;
  }

  bool _esCoreano(String texto) {
    return RegExp(r'[\uAC00-\uD7AF]').hasMatch(texto);
  }
}

// ==========================================
// 🇰🇷🇯🇵🇹🇭 TAB DE RECOMENDACIONES
// ==========================================
class _ListaRecomendada extends StatefulWidget {
  final String pais; 
  final Function(Serie) onSerieAgregada;
  final List<Serie> seriesGuardadas;

  const _ListaRecomendada({required this.pais, required this.onSerieAgregada, required this.seriesGuardadas});

  @override
  State<_ListaRecomendada> createState() => _ListaRecomendadaState();
}

class _ListaRecomendadaState extends State<_ListaRecomendada> {
  List<dynamic> _series = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTendencias();
  }

  Future<void> _cargarTendencias() async {
    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    // Usamos discover para traer series del país seleccionado
    final url = Uri.parse('https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&with_origin_country=${widget.pais}&sort_by=popularity.desc&language=es-MX&include_adult=false');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() { _series = data['results']; _cargando = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)));
    if (_series.isEmpty) return const Center(child: Text("No hay datos disponibles"));

    return GridView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16,
      ),
      itemCount: _series.length,
      itemBuilder: (context, index) {
        final json = _series[index];
        final String imagenPath = json['poster_path'] ?? '';
        final String imagenUrl = imagenPath.isNotEmpty 
            ? 'https://image.tmdb.org/t/p/w500$imagenPath' 
            : '';
        final String titulo = json['name'] ?? 'Sin título';

        bool yaLaTengo = false;
        try {
          // Buscamos si ya existe en la lista
          widget.seriesGuardadas.firstWhere((s) => s.tmdbId == json['id']);
          yaLaTengo = true;
        } catch (e) {
          yaLaTengo = false;
        }

        // Lógica para ir al detalle (La sacamos afuera para reutilizar)
        void irAlDetalle() {
            if (yaLaTengo) {
               // Buscamos la serie real para editarla
               final serieReal = widget.seriesGuardadas.firstWhere((s) => s.tmdbId == json['id']);
               Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: serieReal)));
            } else {
               // Creamos borrador para ver detalle
               String fecha = json['first_air_date'] ?? ''; 
               String anioStr = fecha.length >= 4 ? fecha.substring(0, 4) : '0';
               final tempSerie = Serie(
                id: null, tmdbId: json['id'], titulo: titulo, imagenUrl: imagenUrl,
                estado: 'Por ver', calificacion: 0, episodiosVistos: 0, totalEpisodios: 0, comentario: '', plataforma: 'Desconocido',
                anioLanzamiento: int.tryParse(anioStr) ?? 0, tipo: 'tv', 
              );
              Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleSerie(serie: tempSerie)));
            }
        }

        return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey[300], 
              image: imagenUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imagenUrl), fit: BoxFit.cover) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]
            ),
            child: Stack(
              children: [
                if (imagenUrl.isEmpty) const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)), 
                
                // CAPA 1: DETECTOR DE TOQUE GIGANTE (FONDO)
                // Usamos Positioned.fill para que ocupe todo el espacio
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: irAlDetalle, // <--- Aquí va al detalle
                    ),
                  ),
                ),
                
                // Texto (Visual)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                      gradient: LinearGradient(colors: [Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                    ),
                    child: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ),

                // CAPA 2: BOTÓN DE AGREGAR (FLOTANTE ENCIMA)
                Positioned(
                  top: 5, right: 5,
                  child: GestureDetector( // Usamos GestureDetector aquí para interceptar el toque
                    onTap: () {
                       // Lógica de AGREGAR (No navegar)
                       if (yaLaTengo) {
                         // Si ya la tengo, abrimos detalle para editar
                         irAlDetalle();
                       } else {
                         String fecha = json['first_air_date'] ?? ''; 
                         String anioStr = fecha.length >= 4 ? fecha.substring(0, 4) : '0';
                         
                         final nuevaSerie = Serie(
                            id: null, tmdbId: json['id'], titulo: titulo, imagenUrl: imagenUrl,
                            estado: 'Por ver', calificacion: 0, episodiosVistos: 0, totalEpisodios: 0, comentario: '', plataforma: 'Desconocido',
                            anioLanzamiento: int.tryParse(anioStr) ?? 0,
                            tipo: 'tv',
                         );
                         widget.onSerieAgregada(nuevaSerie);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Agregada! 🎬")));
                       }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: yaLaTengo ? Colors.blue.withOpacity(0.9) : const Color(0xFFFFC107).withOpacity(0.9),
                      child: Icon(
                        yaLaTengo ? Icons.edit : Icons.add, 
                        size: 18, 
                        color: yaLaTengo ? Colors.white : const Color(0xFF0A1931)
                      ),
                    ),
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}