import 'package:flutter/material.dart';
import 'package:k_list/services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  bool _cargando = false;

  void _registrarse() async {
    // Capturamos los textos limpios (sin espacios a los lados)
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    // 🛡️ VALIDACIÓN 1: Que no haya nada vacío
    if (nombre.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Por favor completa todos los campos"), 
          backgroundColor: Colors.orange
        )
      );
      return;
    }

    // 🛡️ VALIDACIÓN 2: Mínimo 6 caracteres (Simple pero efectivo)
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ La contraseña debe tener al menos 6 caracteres"), 
          backgroundColor: Colors.orange
        )
      );
      return;
    }

    setState(() => _cargando = true);
    
    final exito = await _authService.registrar(nombre, email, pass);

    if (!mounted) return; // Seguridad por si cambiaste de pantalla
    setState(() => _cargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Cuenta creada! Inicia sesión 🚀"), backgroundColor: Colors.green)
      );
      Navigator.pop(context); // Volver al login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrarse (¿Email duplicado?)"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text("CREAR CUENTA", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              _InputKList(controller: _nombreController, icon: Icons.person_outline, hint: "Tu Nombre o Nickname"),
              const SizedBox(height: 20),
              _InputKList(controller: _emailController, icon: Icons.email_outlined, hint: "Correo electrónico"),
              const SizedBox(height: 20),
              _InputKList(controller: _passController, icon: Icons.lock_outline, hint: "Contraseña (mínimo 6 caracteres)", esPassword: true),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrarse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107), 
                    foregroundColor: const Color(0xFF0A1931), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  child: _cargando 
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Color(0xFF0A1931), strokeWidth: 3)
                        )
                      : const Text("REGISTRARSE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reutilizamos el input (puedes copiar la clase _InputKList aquí también o sacarla a un archivo aparte widgets/input_klist.dart)
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
      child: TextField(controller: controller, obscureText: esPassword, style: const TextStyle(color: Colors.white), decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.white54), hintText: hint, hintStyle: const TextStyle(color: Colors.white30), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))),
    );
  }
}