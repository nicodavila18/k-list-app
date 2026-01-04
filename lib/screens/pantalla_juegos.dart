import 'package:flutter/material.dart';

// Importación de los minijuegos
import 'juegos/joseon_name_game.dart';
import 'juegos/mbti_game.dart';
import 'juegos/adivina_drama.dart';

class PantallaJuegos extends StatelessWidget {
  // Callback opcional para recargar datos en la pantalla principal (ej. si ganan un premio)
  final VoidCallback? onRecargar;

  const PantallaJuegos({super.key, this.onRecargar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Fondo gris suave (Premium)
      
      // ==========================================
      // 1. CABECERA MODERNA (Estilo iOS/Clean)
      // ==========================================
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5), 
        elevation: 0, 
        scrolledUnderElevation: 0, 
        centerTitle: false, 
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Arcade K-List 🎮",
            style: TextStyle(
              color: Color(0xFF0A1931), // Azul Navy
              fontSize: 28, 
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5
            ),
          ),
        ),
        automaticallyImplyLeading: false, // Sin botón de atrás
      ),

      // ==========================================
      // 2. LISTA DE JUEGOS
      // ==========================================
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Subtítulo
          const Text(
            "   Elige tu próxima aventura",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 25), 

          // 🏯 JUEGO 1: JOSEON
          _GameCardPro(
            titulo: "Tu Nombre Joseon",
            subtitulo: "¿Quién serías en la era antigua?",
            colorInicio: Colors.orange.shade800,
            colorFin: Colors.deepOrange.shade400,
            icono: Icons.history_edu,
            rutaImagen: 'assets/banner_joseon.png',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoseonNameGame())),
          ),

          const SizedBox(height: 20),

          // 🧠 JUEGO 2: MBTI (Con recarga de Idols al volver)
          _GameCardPro(
            titulo: "Test MBTI K-Drama",
            subtitulo: "Descubre qué personaje eres",
            colorInicio: Colors.teal.shade800,
            colorFin: Colors.tealAccent.shade700,
            icono: Icons.psychology,
            rutaImagen: 'assets/banner_mbti.png',
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const MbtiGame()));
              // Si nos pasaron la función de recargar, la ejecutamos al volver
              if (onRecargar != null) onRecargar!();
            },
          ),

          const SizedBox(height: 20),

          // 🎬 JUEGO 3: QUIZ
          _GameCardPro(
            titulo: "Adivina la Escena",
            subtitulo: "¿Reconoces este momento icónico?",
            colorInicio: Colors.purple.shade900, 
            colorFin: Colors.deepPurpleAccent,
            icono: Icons.movie_filter_rounded,
            rutaImagen: 'assets/banner_quiz.png',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdivinaDramaGame())),
          ),

          // Espacio extra al final para que el último item no quede pegado al borde
          const SizedBox(height: 120), 
        ],
      ),
    );
  }
}

// ==========================================
// 🎨 WIDGET: TARJETA DE JUEGO "PRO"
// ==========================================
class _GameCardPro extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Color colorInicio;
  final Color colorFin;
  final IconData icono;
  final String? rutaImagen;
  final VoidCallback onTap;
  final bool bloqueado;

  const _GameCardPro({
    required this.titulo,
    required this.subtitulo,
    required this.colorInicio,
    required this.colorFin,
    required this.icono,
    required this.onTap,
    this.rutaImagen,
    this.bloqueado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [
          BoxShadow(
            color: colorInicio.withOpacity(0.25), 
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              // A. FONDO (Gradiente + Imagen Opcional)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [colorInicio, colorFin],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: (rutaImagen != null && rutaImagen!.isNotEmpty)
                      ? DecorationImage(
                          image: AssetImage(rutaImagen!),
                          fit: BoxFit.cover,
                          opacity: 0.8, 
                        )
                      : null,
                ),
              ),

              // B. SOMBRA DE TEXTO (Para legibilidad)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0], 
                  ),
                ),
              ),

              // C. CONTENIDO (Icono + Textos)
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    // C1. Icono circular
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
                      ),
                      child: Icon(icono, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 18),
                    
                    // C2. Textos
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black, offset: Offset(1,1), blurRadius: 4)]
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500,
                              shadows: const [Shadow(color: Colors.black87, offset: Offset(1,1), blurRadius: 3)]
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // C3. Indicador de Acción (Play / Candado)
                    Icon(
                      bloqueado ? Icons.lock_outline : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}