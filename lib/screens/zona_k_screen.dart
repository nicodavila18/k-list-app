import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

// Importaciones del proyecto
import 'package:k_list/models/serie.dart';
import 'package:k_list/services/auth_service.dart';
import 'package:k_list/services/api_config.dart';
import 'package:k_list/screens/login_screen.dart';

class PantallaZonaK extends StatefulWidget {
  final List<Serie> listaCompleta;
  const PantallaZonaK({super.key, required this.listaCompleta});

  @override
  State<PantallaZonaK> createState() => _PantallaZonaKState();
}

class _PantallaZonaKState extends State<PantallaZonaK> {
  final AuthService _authService = AuthService();
  
  // Estado Local
  XFile? _imagenSeleccionada;
  String _nombreMostrar = "Cargando...";
  bool _notificacionesActivas = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // ==========================================
  // 📥 CARGA DE DATOS (Perfil y Config)
  // ==========================================
  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Nombre: Prioridad Local -> Firebase -> Default
    String? nombreLocal = prefs.getString('userName');
    User? usuarioFirebase = FirebaseAuth.instance.currentUser;
    
    // 2. Foto: Recuperamos ruta local
    String? rutaFoto = prefs.getString('foto_perfil_local');

    if (mounted) {
      setState(() {
        _nombreMostrar = nombreLocal ?? usuarioFirebase?.displayName ?? "K-Lover";
        _notificacionesActivas = prefs.getBool('notificaciones') ?? true;

        if (rutaFoto != null && File(rutaFoto).existsSync()) {
          _imagenSeleccionada = XFile(rutaFoto);
        }
      });
    }
  }

  // ==========================================
  // 📸 GESTIÓN DE FOTO DE PERFIL
  // ==========================================
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Guardamos la ruta persistente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('foto_perfil_local', pickedFile.path);
      
      setState(() => _imagenSeleccionada = pickedFile);
    }
  }

  ImageProvider _obtenerImagenPerfil(String? fotoUrlGoogle) {
    // 1. Si el usuario eligió foto manual
    if (_imagenSeleccionada != null) {
      if (kIsWeb) return NetworkImage(_imagenSeleccionada!.path);
      return FileImage(File(_imagenSeleccionada!.path));
    }
    // 2. Si tiene foto de Google
    if (fotoUrlGoogle != null) return NetworkImage(fotoUrlGoogle);
    
    // 3. Avatar por defecto (Generado por iniciales)
    return const NetworkImage('https://ui-avatars.com/api/?name=K+L&background=0D8ABC&color=fff&size=150');
  }

  // ==========================================
  // ✏️ EDICIÓN DE NOMBRE (Sincronización Total)
  // ==========================================
  Future<void> _editarNombre() async {
    final TextEditingController controller = TextEditingController(text: _nombreMostrar);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Nombre"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "¿Cómo quieres llamarte?"),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              String nuevoNombre = controller.text.trim();
              if (nuevoNombre.isNotEmpty) {
                Navigator.pop(context); // Cerramos diálogo rápido
                
                // 1. Actualizar Backend Python
                try {
                   final baseUrl = await ApiConfig.getBaseUrl();
                   final token = await _authService.getToken();
                   if (token != null) {
                     await http.put(
                       Uri.parse('$baseUrl/usuario/me'),
                       headers: {
                         "Content-Type": "application/json",
                         "Authorization": "Bearer $token"
                       },
                       body: jsonEncode({"nombre": nuevoNombre}),
                     );
                   }
                } catch (_) {}

                // 2. Actualizar Memoria Local
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userName', nuevoNombre);

                // 3. Actualizar Firebase Auth
                User? usuarioFirebase = FirebaseAuth.instance.currentUser;
                if (usuarioFirebase != null) {
                  await usuarioFirebase.updateDisplayName(nuevoNombre);
                }

                // 4. Actualizar UI
                if (mounted) {
                  setState(() => _nombreMostrar = nuevoNombre);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre actualizado ✨")));
                }
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  // ==========================================
  // ⚙️ CONFIGURACIÓN Y LOGOUT
  // ==========================================
  void _mostrarConfiguracion() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Ajustes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Switch Notificaciones
            StatefulBuilder(
              builder: (context, setStateModal) {
                return SwitchListTile(
                  title: const Text("Notificaciones"),
                  subtitle: const Text("Estrenos y Novedades"),
                  value: _notificacionesActivas,
                  activeColor: const Color(0xFF0A1931),
                  onChanged: (val) async {
                    setStateModal(() => _notificacionesActivas = val);
                    setState(() => _notificacionesActivas = val); 
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool('notificaciones', val);
                  },
                );
              }
            ),

            // Botón Acerca De
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF0A1931)),
              title: const Text("Acerca de K-List"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: "K-List",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "Creado por Nicolás Davila © 2026",
                  applicationIcon: const Icon(Icons.movie_filter, size: 50, color: Color(0xFF0A1931)),
                  children: [
                    const SizedBox(height: 20),
                    const Text("Tu colección personal de K-Dramas y Películas. Organiza, califica y descubre tu próximo vicio."),
                  ]
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    // 1. 👇 NUEVO: Borramos la memoria local del teléfono
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ¡PUM! Borrón y cuenta nueva.

    // 2. Borrar datos de Auth
    await _authService.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // ==========================================
  // 🏆 LÓGICA DE GAMIFICACIÓN (RANGOS)
  // ==========================================
  int _calcularTerminadas() => widget.listaCompleta.where((s) => s.estado == 'Terminada').length;

  Map<String, dynamic> _obtenerRangoInfo() {
     int terminadas = _calcularTerminadas();
     if (terminadas >= 50) return {'titulo': 'Ser Inmortal 🗡️', 'gradient': const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFF000000)]), 'sombra': Colors.redAccent};
     if (terminadas >= 20) return {'titulo': 'Rey de Joseon 👑', 'gradient': const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]), 'sombra': Colors.amber};
     if (terminadas >= 10) return {'titulo': 'Heredero Chaebol 💎', 'gradient': const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]), 'sombra': Colors.blueAccent};
     if (terminadas >= 3) return {'titulo': 'Secretario Kim 👔', 'gradient': const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]), 'sombra': Colors.green};
     return {'titulo': 'Turista en Seúl 📸', 'gradient': const LinearGradient(colors: [Color(0xFFbdc3c7), Color(0xFF2c3e50)]), 'sombra': Colors.grey};
  }

  // ==========================================
  // 🎨 INTERFAZ GRÁFICA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final terminadas = _calcularTerminadas();
    final rangoInfo = _obtenerRangoInfo();
    final String? fotoUrlGoogle = FirebaseAuth.instance.currentUser?.photoURL;
    final Color colorFondoApp = const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: colorFondoApp, 
      body: CustomScrollView(
        slivers: [
          // CABECERA ELÁSTICA
          SliverAppBar(
            backgroundColor: const Color(0xFF0A1931),
            expandedHeight: 330.0,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text("MI PERFIL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white, fontSize: 18)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Imagen de Fondo
                  Positioned(
                    top: 0, left: 0, right: 0, bottom: 50, 
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                         Image.asset('assets/banner_perfil.jpg', fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.blueGrey)),
                         Container(color: Colors.black.withOpacity(0.3)),
                      ],
                    ),
                  ),
                  // Conector Blanco curvo
                  Positioned(bottom: 0, left: 0, right: 0, height: 51, child: Container(color: colorFondoApp)),
                  // Avatar Flotante
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: colorFondoApp, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]),
                            child: CircleAvatar(radius: 65, backgroundColor: Colors.grey[200], backgroundImage: _obtenerImagenPerfil(fotoUrlGoogle)),
                          ),
                          GestureDetector(
                            onTap: _seleccionarFoto,
                            child: Container(
                              margin: const EdgeInsets.all(5), padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF0A1931)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _mostrarConfiguracion),
            ],
          ),

          // CONTENIDO DEL PERFIL
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 15),
                // Nombre
                Text(_nombreMostrar.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0A1931))),
                const SizedBox(height: 10),
                // Etiqueta de Rango
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  decoration: BoxDecoration(gradient: rangoInfo['gradient'], borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: rangoInfo['sombra'].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: Text(rangoInfo['titulo'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    children: [
                       // Tarjetas de Estadísticas
                       Row(
                        children: [
                          Expanded(child: _StatCard(titulo: "TERMINADAS", valor: "$terminadas", icono: Icons.check_circle, color: const Color(0xFF43A047), colorFondo: const Color(0xFFE8F5E9))),
                          const SizedBox(width: 15),
                          Expanded(child: _StatCard(titulo: "TOTAL LISTA", valor: "${widget.listaCompleta.length}", icono: Icons.video_library, color: const Color(0xFF1E88E5), colorFondo: const Color(0xFFE3F2FD))),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Opciones de Menú
                      _OpcionPerfil(icon: Icons.edit_note_rounded, text: "Editar Nombre", onTap: _editarNombre),
                      _OpcionPerfil(icon: Icons.notifications_active_rounded, text: "Notificaciones", onTap: _mostrarConfiguracion),
                      _OpcionPerfil(icon: Icons.logout_rounded, text: "Cerrar Sesión", esRojo: true, onTap: _cerrarSesion),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🧩 WIDGETS AUXILIARES
// ==========================================

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final Color colorFondo;

  const _StatCard({required this.titulo, required this.valor, required this.icono, required this.color, required this.colorFondo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0A1931).withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorFondo, shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool esRojo;
  final VoidCallback onTap;

  const _OpcionPerfil({required this.icon, required this.text, this.esRojo = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), 
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: esRojo ? Colors.red[50] : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: esRojo ? Colors.red : const Color(0xFF0A1931), size: 22),
        ),
        title: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: esRojo ? Colors.red : const Color(0xFF0A1931))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: Colors.white,
      ),
    );
  }
}