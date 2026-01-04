import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Necesario para el Timer
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Modelos y Pantallas
import '../models/serie.dart';
import 'detalle_serie.dart';
import 'detalle_actor.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _resultados = []; // Lista mixta (Series + Actores)
  bool _buscando = false;
  Timer? _debounce; // Timer para esperar a que el usuario termine de escribir

  @override
  void dispose() {
    _debounce?.cancel(); // 🧹 Limpieza: Cancelamos el timer si salimos de la pantalla
    _controller.dispose();
    super.dispose();
  }

  // ==========================================
  // 🧠 LÓGICA DE BÚSQUEDA (DEBOUNCE)
  // ==========================================
  
  // Se ejecuta cada vez que el usuario teclea
  void _onSearchChanged(String query) {
    // Si hay un timer pendiente, lo cancelamos (reiniciamos el reloj)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Esperamos 500ms. Si el usuario no escribe nada más, lanzamos la búsqueda.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscarEnTMDB(query);
    });
  }

  Future<void> _buscarEnTMDB(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() { _resultados = []; _buscando = false; });
      return;
    }

    setState(() => _buscando = true);

    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    // Usamos 'search/multi' para encontrar tanto Series como Personas
    final url = Uri.parse('https://api.themoviedb.org/3/search/multi?api_key=$apiKey&language=es-ES&query=$query'); // 🌎 Puse 'es-ES' para resultados en español

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 🔍 FILTRADO: Solo queremos Series (tv) y Personas (person) que tengan FOTO.
        final listaFiltrada = (data['results'] as List).where((item) {
          final mediaType = item['media_type'];
          final tieneFoto = (mediaType == 'person' && item['profile_path'] != null) || 
                            (mediaType == 'tv' && item['poster_path'] != null);
          
          return (mediaType == 'tv' || mediaType == 'person') && tieneFoto;
        }).toList();

        // ⭐ ORDENAMIENTO: Los más populares primero
        listaFiltrada.sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));

        if (mounted) {
          setState(() {
            _resultados = listaFiltrada;
            _buscando = false;
          });
        }
      } else {
        if (mounted) setState(() => _buscando = false);
      }
    } catch (e) {
      if (mounted) setState(() => _buscando = false);
    }
  }

  // ==========================================
  // 🎨 WIDGETS DE RESULTADOS
  // ==========================================

  Widget _buildItemSerie(dynamic item) {
    final posterPath = item['poster_path'];
    final titulo = item['name'] ?? item['title'] ?? 'Sin título';
    final fecha = item['first_air_date'] ?? item['release_date'];
    final anio = (fecha as String?)?.split('-').first ?? '---';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          'https://image.tmdb.org/t/p/w200$posterPath', 
          width: 45, height: 68, fit: BoxFit.cover,
          errorBuilder: (c,e,s) => Container(width: 45, height: 68, color: Colors.grey),
        ),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Serie • $anio"),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Convertimos el JSON crudo a nuestro objeto Serie
        final nuevaSerie = Serie(
          tmdbId: item['id'],
          titulo: titulo,
          imagenUrl: 'https://image.tmdb.org/t/p/w500$posterPath',
          estado: 'Por ver',
          calificacion: 0,
          comentario: '',
          plataforma: 'Desconocido',
          anioLanzamiento: int.tryParse(anio) ?? 0,
          tipo: 'tv',
        );
        // Devolvemos la serie seleccionada a la pantalla anterior
        Navigator.pop(context, nuevaSerie);
      },
    );
  }

  Widget _buildItemActor(dynamic item) {
    final profilePath = item['profile_path'];
    final nombre = item['name'] ?? 'Desconocido';
    
    // Intentamos buscar por qué es conocido (ej: "Squid Game")
    final conocidos = item['known_for'] as List<dynamic>?;
    String conocidoPor = "";
    if (conocidos != null && conocidos.isNotEmpty) {
      final obra = conocidos.first;
      conocidoPor = obra['title'] ?? obra['name'] ?? '';
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage('https://image.tmdb.org/t/p/w200$profilePath'),
        onBackgroundImageError: (_, __) {},
      ),
      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(conocidoPor.isNotEmpty ? "Actor • $conocidoPor" : "Actor"),
      trailing: const Icon(Icons.star, color: Color(0xFFFFC107), size: 18), // Estrella dorada
      onTap: () {
        // Navegamos al detalle del actor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaDetalleActor(
              actorId: item['id'],
              nombre: nombre,
              fotoUrl: 'https://image.tmdb.org/t/p/w500$profilePath',
              // NOTA: Si necesitas pasar listas vacías o callbacks, hazlo aquí
              seriesGuardadas: const [], 
              onSerieAgregada: (_) {}, 
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Escribe para buscar...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged, // Conectamos el Debounce
        ),
        backgroundColor: const Color(0xFF0A1931), // Azul Navy K-List
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onSearchChanged(""); // Limpiamos resultados
              },
            )
        ],
      ),
      body: _buscando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _resultados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                         _controller.text.isEmpty ? "Busca tus Series o Idols" : "No se encontraron resultados",
                         style: TextStyle(color: Colors.grey[500], fontSize: 16)
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _resultados.length,
                  separatorBuilder: (c, i) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final item = _resultados[index];
                    // Decidimos qué widget dibujar según el tipo
                    if (item['media_type'] == 'person') {
                      return _buildItemActor(item);
                    } else {
                      return _buildItemSerie(item);
                    }
                  },
                ),
    );
  }
}