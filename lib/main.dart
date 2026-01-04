import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// --- IMPORTS DE PROYECTO ---
import 'firebase_options.dart';
import 'package:k_list/models/serie.dart';
import 'package:k_list/models/actor_favorito.dart';
import 'package:k_list/services/api_service.dart';
import 'package:k_list/services/auth_service.dart';

// --- PANTALLAS ---
import 'package:k_list/screens/login_screen.dart';
import 'package:k_list/screens/descubrir_screen.dart';
import 'package:k_list/screens/detalle_serie.dart';
import 'package:k_list/screens/detalle_actor.dart';
import 'package:k_list/screens/zona_k_screen.dart';
import 'screens/pantalla_juegos.dart';

// --- WIDGETS ---
import 'package:k_list/widgets/banner_klist.dart';

// ==========================================
// 🚀 PUNTO DE ENTRADA (MAIN)
// ==========================================
Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carga variables de entorno y Firebase antes de arrancar la UI
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MobileAds.instance.initialize();
  
  runApp(const KListApp());
}

// ==========================================
// 🎨 CONFIGURACIÓN GENERAL DE LA APP
// ==========================================
class KListApp extends StatelessWidget {
  const KListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-List',
      debugShowCheckedModeBanner: false, // Quita la etiqueta "Debug" de la esquina
      
      // Configuración de idioma (Español)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      
      // Tema Visual (Colores)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A1931), // Azul Navy K-List
          brightness: Brightness.light, 
          primary: const Color(0xFF0A1931), 
          secondary: const Color(0xFFFFC107), // Dorado
          background: const Color(0xFFF8F9FA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1931),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        fontFamily: 'Roboto', 
      ),
      
      // 👇 EL CEREBRO QUE DECIDE A DÓNDE IR (Login o Home)
      home: const AuthGate(),
    );
  }
}

// ==========================================
// 🧠 AUTH GATE (SEGURIDAD)
// Decide si mostrar Login, Home o Espera
// ==========================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges, // Escucha cambios de Firebase (Google)
      builder: (context, snapshot) {
        
        // 1. Si Firebase detecta usuario (Google Login)
        // Mostramos animación mientras Python valida el token en segundo plano.
        if (snapshot.hasData) {
          return const PantallaEsperaToken(); 
        }

        // 2. Si no es Google, verificamos si hay sesión guardada (Email Login)
        return FutureBuilder<String?>(
          future: AuthService().getToken(),
          builder: (context, tokenSnapshot) {
            
            // Esperando lectura de disco...
            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0A1931), 
                body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
              );
            }
            
            // Si hay token válido -> Home
            if (tokenSnapshot.hasData && tokenSnapshot.data != null) {
              return const PantallaPrincipal();
            }
            
            // Si no hay nada -> Login
            return const LoginScreen();
          },
        );
      },
    );
  }
}

// ==========================================
// 🏠 PANTALLA PRINCIPAL (CONTENEDOR)
// Maneja la navegación inferior y la carga de datos
// ==========================================
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceSeleccionado = 0;
  List<Serie> misSeries = [];
  List<ActorFavorito> misActores = [];
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _cargarDatos(); // Carga inicial
  }

  // Carga unificada de datos
  void _cargarDatos() {
    _cargarSeries();
    _cargarActores();
  }

  Future<void> _cargarSeries() async {
    final series = await _apiService.getSeries(); 
    if (mounted) setState(() => misSeries = series);
  }

  Future<void> _cargarActores() async {
    final actores = await _apiService.getActores();
    if (mounted) setState(() => misActores = actores);
  }
  
  // --- GESTIÓN DE DATOS (CRUD) ---
  
  Future<void> _agregarSerie(Serie nuevaSerie) async {
    final serieGuardada = await _apiService.addSerie(nuevaSerie);
    if (serieGuardada != null) {
      setState(() => misSeries.add(serieGuardada));
    } else {
      _mostrarMensaje("Error al guardar. Revisa tu conexión.", esError: true);
    }
  }

  Future<void> _actualizarSerieEnServidor(Serie serie) async {
    setState(() {}); // Actualización visual inmediata (Optimistic UI)
    final exito = await _apiService.updateSerie(serie);
    if (!exito) {
      _mostrarMensaje("Error al sincronizar", esError: true);
      _cargarSeries(); // Revertimos si falló
    }
  }

  Future<void> _borrarSerieEnServidor(int id) async {
    final exito = await _apiService.deleteSerie(id);
    if (exito) {
      setState(() => misSeries.removeWhere((s) => s.id == id));
    } else {
      _mostrarMensaje("Error al borrar", esError: true);
    }
  }

  Future<void> _agregarActor(ActorFavorito nuevoActor) async {
    final actorGuardado = await _apiService.addActor(nuevoActor);
    if (actorGuardado != null) {
      _cargarActores(); 
    } else {
      _mostrarMensaje("Error al guardar actor", esError: true);
    }
  }

  // 🔔 Sistema de Notificaciones Visuales (Snackbars bonitos)
  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(esError ? Icons.error_outline : Icons.check_circle, color: esError ? Colors.white : const Color(0xFFFFC107)),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: esError ? Colors.redAccent : const Color(0xFF0A1931),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 90), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtros rápidos para las pestañas
    final soloSeries = misSeries.where((s) => s.tipo == 'tv').toList();
    final soloPeliculas = misSeries.where((s) => s.tipo == 'movie').toList();

    return Scaffold(
      body: IndexedStack(
        index: _indiceSeleccionado,
        children: [
          // 0. INICIO (Listas)
          _ContenidoPrincipal(
            listaSeries: soloSeries,
            listaPeliculas: soloPeliculas,
            actores: misActores,
            onSerieChanged: _actualizarSerieEnServidor,
            onSerieDeleted: _borrarSerieEnServidor,
            onSerieAgregada: _agregarSerie,
            onRecargar: _cargarDatos,
          ),
          // 1. BUSCADOR GLOBAL
          PantallaDescubrir(
            seriesGuardadas: misSeries,
            actoresGuardados: misActores,
            onSerieAgregada: _agregarSerie,
            onActorAgregado: _agregarActor, 
          ),
          // 2. JUEGOS
          PantallaJuegos(onRecargar: _cargarActores),
          // 3. PERFIL
          PantallaZonaK(listaCompleta: misSeries),
        ],
      ),
      
      extendBody: true,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerKList(), // 👈 ¡AQUÍ APARECE LA PUBLICIDAD! 💵
          _buildBottomBar(),   // Tu barra de navegación original
        ],
      ),
      
      // Botón flotante solo visible en Inicio
      floatingActionButton: _indiceSeleccionado == 0 ? FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: const Color(0xFF0A1931),
        child: const Icon(Icons.add, size: 30),
        onPressed: () => setState(() => _indiceSeleccionado = 1), // Lleva al buscador
      ) : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), 
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 20), 
      decoration: BoxDecoration(
        color: const Color(0xFF0A1931), 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: _indiceSeleccionado,
          onTap: (index) {
            setState(() => _indiceSeleccionado = index);
            // Recargamos datos al volver a Inicio o Perfil para mantener frescura
            if (index == 0 || index == 3) _cargarDatos();
          },
          backgroundColor: const Color(0xFF0A1931),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFC107),
          unselectedItemColor: Colors.white54,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Juegos'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📑 CONTENIDO PRINCIPAL (TABS + BUSCADOR LOCAL)
// ==========================================
class _ContenidoPrincipal extends StatefulWidget {
  final List<Serie> listaSeries;
  final List<Serie> listaPeliculas;
  final List<ActorFavorito> actores;
  final Function(Serie) onSerieChanged;
  final Function(int) onSerieDeleted;
  final Function(Serie) onSerieAgregada;
  final VoidCallback onRecargar;

  const _ContenidoPrincipal({
    required this.listaSeries,
    required this.listaPeliculas,
    required this.actores,
    required this.onSerieChanged,
    required this.onSerieDeleted,
    required this.onSerieAgregada,
    required this.onRecargar,
  });

  @override
  State<_ContenidoPrincipal> createState() => _ContenidoPrincipalState();
}

class _ContenidoPrincipalState extends State<_ContenidoPrincipal> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = ""; 

  @override
  void initState() {
    super.initState();
    // Escuchamos lo que escribe el usuario para filtrar
    _searchController.addListener(() => setState(() => _filtro = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'Viendo': return Colors.green;
      case 'Por ver': return Colors.orange;
      case 'Terminada': return Colors.blueGrey;
      case 'Abandonada': return Colors.redAccent;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 LÓGICA DE FILTRADO LOCAL
    final seriesFiltradas = widget.listaSeries.where((s) => s.titulo.toLowerCase().contains(_filtro.toLowerCase())).toList();
    final pelisFiltradas = widget.listaPeliculas.where((p) => p.titulo.toLowerCase().contains(_filtro.toLowerCase())).toList();
    final actoresFiltrados = widget.actores.where((a) => a.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          title: _buildCustomTitle(), // Título con logo
          bottom: const TabBar(
            indicatorColor: Color(0xFFFFC107),
            indicatorWeight: 4,
            labelColor: Color(0xFFFFC107),
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: "SERIES"),
              Tab(text: "PELÍCULAS"),
              Tab(text: "IDOLS"),
            ],
          ),
        ),
        
        body: Column(
          children: [
            // Barra de búsqueda local (Solo si hay datos)
            if (widget.listaSeries.isNotEmpty || widget.listaPeliculas.isNotEmpty || widget.actores.isNotEmpty)
              _buildSearchBar(),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                children: [
                  _buildLista(context, seriesFiltradas, "No encontré esa serie 🤷‍♂️"),
                  _buildLista(context, pelisFiltradas, "No encontré esa peli 🎬"),
                  _buildActores(context, actoresFiltrados),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget del título (Logo + Texto)
  Widget _buildCustomTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40, width: 40,
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.2), blurRadius: 15)]),
          child: Image.asset('assets/logo-solo1.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("K-LIST", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white, height: 1.0)),
            Text("COLLECTION", style: TextStyle(fontSize: 9, color: Color(0xFFFFC107), letterSpacing: 3.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // Widget de la barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0A1931),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF0A1931), fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: "Buscar en tu colección...",
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFFC107)),
          suffixIcon: _filtro.isNotEmpty 
            ? IconButton(icon: Icon(Icons.close, color: Colors.grey[700]), onPressed: () => _searchController.clear())
            : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
      ),
    );
  }

  // Constructor de lista (Series/Películas)
  Widget _buildLista(BuildContext context, List<Serie> items, String mensajeVacio) {
    if (items.isEmpty) {
      bool esBusquedaVacia = _filtro.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esBusquedaVacia ? Icons.search_off : Icons.video_library_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(esBusquedaVacia ? mensajeVacio : "Nada por aquí...", style: const TextStyle(color: Colors.grey)),
          ],
        )
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final colorEstado = _getColorEstado(item.estado);

        return Card(
          elevation: 2, color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imagenUrl, 
                width: 50, height: 80, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 50, height: 80, color: Colors.grey[200], child: const Icon(Icons.movie, color: Colors.grey)),
              ),
            ),
            title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("${item.anioLanzamiento} • ${item.plataforma}", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorEstado)),
              child: Text(item.estado, style: TextStyle(color: colorEstado, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            onTap: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleSerie(serie: item)));
              if (res == 'BORRAR' && item.id != null) {
                widget.onSerieDeleted(item.id!);
              } else { 
                await widget.onSerieChanged(item); 
                widget.onRecargar(); 
              }
            },
          ),
        );
      },
    );
  }

  // Constructor de lista (Actores)
  Widget _buildActores(BuildContext context, List<ActorFavorito> items) {
    if (items.isEmpty) {
      bool esBusquedaVacia = _filtro.isNotEmpty;
      return Center(child: Text(esBusquedaVacia ? "No encontré a ese Idol 🕵️‍♂️" : "No tienes Idols aún ⭐", style: const TextStyle(color: Colors.grey)));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final actor = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleActor(
              actorId: actor.tmdbId,
              nombre: actor.nombre,
              fotoUrl: actor.fotoUrl,
              seriesGuardadas: [...widget.listaSeries, ...widget.listaPeliculas], 
              onSerieAgregada: widget.onSerieAgregada, 
            )));
            widget.onRecargar(); 
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                  child: ClipOval(child: Image.network(actor.fotoUrl, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 8),
              Text(actor.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// ⏳ PANTALLA DE ESPERA INTELIGENTE
// Animación mientras se sincroniza el Token
// ==========================================
class PantallaEsperaToken extends StatefulWidget {
  const PantallaEsperaToken({super.key});

  @override
  State<PantallaEsperaToken> createState() => _PantallaEsperaTokenState();
}

class _PantallaEsperaTokenState extends State<PantallaEsperaToken> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animación visual (Latido)
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _verificarTokenPython();
  }
  
  // Bucle de verificación de token
  Future<void> _verificarTokenPython() async {
    bool tokenListo = false;
    int intentos = 0;

    // Intentamos 10 veces (5 segundos máx)
    while (!tokenListo && intentos < 10) {
      final token = await AuthService().getToken();
      if (token != null && token.isNotEmpty) {
        tokenListo = true;
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        intentos++;
      }
    }

    if (!mounted) return;

    if (tokenListo) {
      // Login exitoso -> Home
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PantallaPrincipal()));
    } else {
      // Fallo -> Logout y vuelta al login
      AuthService().logout();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.15), blurRadius: 60, spreadRadius: 10)]),
                child: Image.asset('assets/logo-solo1.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 30),
            const Text("K-LIST", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text("SINCRONIZANDO...", style: TextStyle(color: Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 60),
            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Color(0xFFFFC107), strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}