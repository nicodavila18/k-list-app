import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Modelos y Servicios
import '../models/serie.dart';
import 'package:k_list/services/api_service.dart';
import 'detalle_actor.dart';

class PantallaDetalleSerie extends StatefulWidget {
  final Serie serie;

  const PantallaDetalleSerie({super.key, required this.serie});

  @override
  State<PantallaDetalleSerie> createState() => _PantallaDetalleSerieState();
}

class _PantallaDetalleSerieState extends State<PantallaDetalleSerie> {
  final _apiService = ApiService();
  
  // Estado local para edición
  late String _estadoActual;
  late double _calificacionActual;
  List<dynamic> _actores = [];
  bool _cargandoActores = true;
  bool _editandoTitulo = false;
  
  // Controladores de Texto
  late TextEditingController _comentarioController;
  late TextEditingController _plataformaController;
  late TextEditingController _tituloController;

  @override
  void initState() {
    super.initState();
    // Inicializamos controladores con datos existentes
    _estadoActual = widget.serie.estado;
    _calificacionActual = widget.serie.calificacion;
    _comentarioController = TextEditingController(text: widget.serie.comentario);
    _plataformaController = TextEditingController(text: widget.serie.plataforma);
    _tituloController = TextEditingController(text: widget.serie.titulo);
    
    _cargarActoresTMDB();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _plataformaController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  // ==========================================
  // 💾 LÓGICA DE GUARDADO (CRUD)
  // ==========================================

  Future<void> _guardarCambios() async {
    FocusScope.of(context).unfocus(); // Cierra teclado

    // 1. Actualizamos el objeto localmente
    setState(() {
      widget.serie.estado = _estadoActual;
      widget.serie.calificacion = _calificacionActual;
      widget.serie.comentario = _comentarioController.text;
      widget.serie.plataforma = _plataformaController.text;
      widget.serie.titulo = _tituloController.text;
    });

    bool exito = false;

    // 2. Decidimos si es CREAR o ACTUALIZAR
    if (widget.serie.id == null) {
      // CASO: Serie nueva (Viene de búsqueda)
      final nuevaSerie = await _apiService.addSerie(widget.serie);
      if (nuevaSerie != null) {
        exito = true;
        widget.serie.id = nuevaSerie.id; // Asignamos ID real
      }
    } else {
      // CASO: Serie existente (Edición)
      exito = await _apiService.updateSerie(widget.serie);
    }

    if (!mounted) return;

    if (exito) {
      _mostrarMensaje('¡Guardado correctamente! ✅');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true); // Volver y recargar
    } else {
      _mostrarMensaje('Error al guardar. Verifica tu conexión ❌', esError: true);
    }
  }

  // ==========================================
  // 📥 CARGA DE DATOS EXTERNOS (TMDB)
  // ==========================================

  Future<void> _cargarActoresTMDB() async {
    if (widget.serie.tmdbId == 0) {
      if (mounted) setState(() => _cargandoActores = false);
      return;
    }

    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    final url = Uri.parse('https://api.themoviedb.org/3/tv/${widget.serie.tmdbId}/credits?api_key=$apiKey&language=en-US');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _actores = data['cast'];
            _cargandoActores = false;
          });
        }
      }
    } catch (_) {
      // Fallo silencioso (simplemente no muestra actores)
      if (mounted) setState(() => _cargandoActores = false);
    }
  }

  // ==========================================
  // 🗑️ GESTIÓN DE EPISODIOS Y BORRADO
  // ==========================================

  void _confirmarBorrado(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar serie?"),
        content: const Text("La serie se eliminará de tu colección permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'BORRAR'); // Código especial para main.dart
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _editarTotalCapitulos(BuildContext context) async {
      final controllerTotal = TextEditingController(text: widget.serie.totalEpisodios.toString());
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Definir total de capítulos"),
          content: TextField(
            controller: controllerTotal,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(suffixText: "caps"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            FilledButton(
              onPressed: () {
                setState(() {
                  widget.serie.totalEpisodios = int.tryParse(controllerTotal.text) ?? 0;
                });
                Navigator.pop(ctx);
              },
              child: const Text("Guardar"),
            ),
          ],
        )
      );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================
  // 🎨 INTERFAZ GRÁFICA (BUILD)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: CustomScrollView(
        slivers: [
          // 1. Appbar Elástico (Imagen de fondo)
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: const Color(0xFF0A1931),
            leading: IconButton(
               icon: const CircleAvatar(backgroundColor: Colors.black45, child: Icon(Icons.arrow_back, color: Colors.white)),
               onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.black45, child: Icon(Icons.delete, color: Colors.white, size: 20)),
                onPressed: () => _confirmarBorrado(context),
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                widget.serie.titulo,
                style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.serie.imagenUrl, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.movie, size: 50, color: Colors.white24))),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Formulario
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContenidoFormulario(),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Guardar", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.save, color: Colors.white),
        backgroundColor: const Color(0xFF0A1931),
        onPressed: _guardarCambios,
      ),
    );
  }

  // --- FORMULARIO COMPLETO ---
  Widget _buildContenidoFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Título Editable
        Row(
          children: [
            Expanded(
              child: _editandoTitulo
                  ? TextField(
                      controller: _tituloController,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      autofocus: true,
                      onSubmitted: (_) => setState(() => _editandoTitulo = false),
                    )
                  : Text(
                      _tituloController.text,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                    ),
            ),
            IconButton(
              icon: Icon(_editandoTitulo ? Icons.check : Icons.edit_note, color: Colors.blueGrey),
              onPressed: () => setState(() => _editandoTitulo = !_editandoTitulo),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // B. Año y Plataforma
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
              child: Text(
                widget.serie.anioLanzamiento > 0 ? "${widget.serie.anioLanzamiento}" : "Año?",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _plataformaController.text != 'Desconocido' ? _plataformaController.text : "Sin plataforma",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 25),

        // C. Contador de Episodios
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _botonCircular(Icons.remove, () {
                    if (widget.serie.episodiosVistos > 0) {
                      setState(() {
                         widget.serie.episodiosVistos--;
                         if (_estadoActual == 'Terminada' && widget.serie.episodiosVistos < widget.serie.totalEpisodios) {
                            _estadoActual = 'Viendo';
                         }
                      });
                    }
                  }),
                  Column(
                    children: [
                      Text("Capítulo ${widget.serie.episodiosVistos}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1931))),
                      Text(widget.serie.totalEpisodios > 0 ? "de ${widget.serie.totalEpisodios}" : "Sin límite", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  _botonCircular(Icons.add, () {
                     setState(() {
                        if (widget.serie.totalEpisodios == 0 || widget.serie.episodiosVistos < widget.serie.totalEpisodios) {
                          widget.serie.episodiosVistos++;
                        }
                        // Auto-completar lógica
                        if (widget.serie.totalEpisodios > 0 && widget.serie.episodiosVistos == widget.serie.totalEpisodios) {
                          _estadoActual = 'Terminada';
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Serie completada! 🎉'), backgroundColor: Colors.green, duration: Duration(milliseconds: 1000)));
                        } else if (_estadoActual == 'Terminada' || _estadoActual == 'Por ver') {
                           _estadoActual = 'Viendo';
                        }
                     });
                  }),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.serie.totalEpisodios > 0 ? (widget.serie.episodiosVistos / widget.serie.totalEpisodios) : 0,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFFFFC107),
                  minHeight: 8,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 12, color: Colors.grey),
                label: const Text("Editar total de caps", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onPressed: () => _editarTotalCapitulos(context),
              )
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 10),

        // D. Estado
        const Text("Estado:", style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _estadoActual,
          isExpanded: true,
          underline: Container(height: 1, color: Colors.grey[300]),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: <String>['Por ver', 'Viendo', 'Terminada', 'Abandonada']
              .map((String valor) => DropdownMenuItem(value: valor, child: Text(valor)))
              .toList(),
          onChanged: (nuevo) => setState(() => _estadoActual = nuevo!),
        ),

        const SizedBox(height: 20),

        // E. Plataforma (Autocomplete)
        const Text("Plataforma:", style: TextStyle(fontWeight: FontWeight.bold)),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue val) {
            if (val.text == '') return const Iterable<String>.empty();
            const List<String> opciones = ['Netflix', 'Disney+', 'Amazon Prime', 'HBO Max', 'Apple TV', 'Viki', 'Crunchyroll', 'Telegram', 'YouTube'];
            return opciones.where((o) => o.toLowerCase().contains(val.text.toLowerCase()));
          },
          onSelected: (selection) => _plataformaController.text = selection,
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            if (controller.text.isEmpty) controller.text = _plataformaController.text;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: () { _plataformaController.text = controller.text; onEditingComplete(); },
              onChanged: (text) => _plataformaController.text = text,
              decoration: const InputDecoration(
                hintText: 'Ej: Netflix...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                prefixIcon: Icon(Icons.tv, color: Colors.grey),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // F. Calificación
        const Text("Tu Calificación:", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(index < _calificacionActual ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
              onPressed: () => setState(() => _calificacionActual = (index + 1).toDouble()),
            );
          }),
        ),

        const SizedBox(height: 20),

        // G. Actores (Carrusel)
        if (_actores.isNotEmpty) ...[
          const Text("Reparto Principal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _actores.length > 10 ? 10 : _actores.length,
              itemBuilder: (context, index) {
                final actor = _actores[index];
                final foto = actor['profile_path'];
                final fotoUrl = foto != null ? 'https://image.tmdb.org/t/p/w200$foto' : 'https://via.placeholder.com/200x300?text=?';
                return InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleActor(
                      actorId: actor['id'], nombre: actor['name'], fotoUrl: fotoUrl
                    )));
                  },
                  child: Container(
                    width: 80, margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 30, backgroundImage: NetworkImage(fotoUrl)),
                        const SizedBox(height: 5),
                        Text(actor['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        Text(actor['character'], style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ],

        // H. Comentarios
        const Text("Tus notas / Reseña:", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _comentarioController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(hintText: 'Escribe aquí qué te pareció la serie...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _botonCircular(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]),
        child: Icon(icon, color: const Color(0xFF0A1931)),
      ),
    );
  }
}