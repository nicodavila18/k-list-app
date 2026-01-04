import 'package:flutter/material.dart';
import 'package:k_list/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación de Latido
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), 
      vsync: this,
    )..repeat(reverse: true); 

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );

    // Navegar después de 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931), // Fondo Navy
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO FLOTANTE ANIMADO 🎬❤️
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 160, 
                height: 160,
                // Efecto de resplandor dorado detrás del logo
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Sombra circular detrás
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.15), 
                      blurRadius: 60,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Image.asset(
                  'assets/logo-solo1.png', // 👈 IMAGEN SIN TEXTO
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // TEXTO DEBAJO (Opcional, ya que es el Splash)
            const Text(
              "K-LIST",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
             const Text(
              "COLLECTION",
              style: TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),

            const SizedBox(height: 60),

            // INDICADOR DE CARGA
            const SizedBox(
              width: 30, height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFFFFC107),
                strokeWidth: 2,
              ),
            )
          ],
        ),
      ),
    );
  }
}