import 'package:flutter/material.dart';
import 'package:k_list/screens/registro_screen.dart';
import 'package:k_list/services/auth_service.dart';
import 'package:k_list/main.dart'; // Necesario para acceder a PantallaEsperaToken

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  bool _cargando = false;

  // ==========================================
  // 📧 LOGIN CON EMAIL
  // ==========================================
  void _iniciarSesion() async {
    // 1. Cerramos el teclado para ver mejor la UI
    FocusScope.of(context).unfocus();

    setState(() => _cargando = true);
    
    try {
      final resultado = await _authService.login(
        _emailController.text.trim(), 
        _passController.text.trim()
      );

      if (!mounted) return;
      setState(() => _cargando = false);

      if (resultado != null) {
        // ✅ ÉXITO: Navegamos a la "Sala de Espera" para la animación de sincronización
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const PantallaEsperaToken()), 
          (route) => false,
        );
      } else {
        // ❌ ERROR: Credenciales inválidas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email o contraseña incorrectos"), backgroundColor: Colors.redAccent)
        );
      }
    } catch (_) {
      // Error de conexión u otro imprevisto
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ==========================================
  // 🌐 LOGIN CON GOOGLE
  // ==========================================
  void _loginGoogle() async {
    setState(() => _cargando = true);
    
    // Iniciamos el flujo seguro
    final user = await _authService.signInWithGoogle();
    
    if (!mounted) return;

    if (user != null) {
      // ⏳ Esperamos 1.5s para dar tiempo a que el AuthGate (en main.dart) reaccione automáticamente
      // al cambio de estado de Firebase.
      await Future.delayed(const Duration(milliseconds: 1500)); 

      // Si por alguna razón la app no navegó sola, forzamos la entrada manualmente.
      if (mounted) {
        setState(() => _cargando = false);
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const PantallaEsperaToken()), 
          (route) => false,
        );
      }
    } else {
      // Usuario canceló o falló la conexión con Google
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo iniciar sesión con Google"), backgroundColor: Colors.orange)
        );
      }
    }
  }

  // ==========================================
  // 🎨 INTERFAZ GRÁFICA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset('assets/logo-solo1.png', height: 120), 
                const SizedBox(height: 20),
                const Text("BIENVENIDO A K-LIST", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Text("Tu colección de dramas en un solo lugar", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 50),

                // CAMPOS DE TEXTO
                _InputKList(controller: _emailController, icon: Icons.email_outlined, hint: "Correo electrónico"),
                const SizedBox(height: 20),
                _InputKList(controller: _passController, icon: Icons.lock_outline, hint: "Contraseña", esPassword: true),
                const SizedBox(height: 30),

                // BOTÓN INGRESAR (EMAIL)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107), 
                      foregroundColor: const Color(0xFF0A1931),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _cargando 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF0A1931), strokeWidth: 3))
                      : const Text("INGRESAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                
                // SEPARADOR
                const Row(children: [
                   Expanded(child: Divider(color: Colors.white24)),
                   Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O", style: TextStyle(color: Colors.white54))),
                   Expanded(child: Divider(color: Colors.white24)),
                ]),
                const SizedBox(height: 20),

                // BOTÓN GOOGLE
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _loginGoogle, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Asegúrate de que 'assets/google_icon.png' exista, si no, usa un Icon(Icons.g_mobiledata) temporalmente
                        Image.asset('assets/google_icon.png', height: 24, errorBuilder: (c,e,s) => const Icon(Icons.login, color: Colors.blue)), 
                        const SizedBox(width: 12),
                        const Text("Continuar con Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // IR A REGISTRO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.white60)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
                      child: const Text("Regístrate aquí", style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// WIDGET AUXILIAR (INPUT)
class _InputKList extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool esPassword;

  const _InputKList({required this.controller, required this.icon, required this.hint, this.esPassword = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        obscureText: esPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}