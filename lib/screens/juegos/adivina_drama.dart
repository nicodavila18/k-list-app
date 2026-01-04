import 'package:flutter/material.dart';
import 'dart:ui'; // Para el efecto borroso
import 'dart:math';

class AdivinaDramaGame extends StatefulWidget {
  const AdivinaDramaGame({super.key});

  @override
  State<AdivinaDramaGame> createState() => _AdivinaDramaGameState();
}

class _AdivinaDramaGameState extends State<AdivinaDramaGame> {
  int _nivelActual = 0;
  int _puntaje = 0;
  bool _revelado = false;
  bool _juegoTerminado = false;

  // 🎬 LOS 10 NIVELES (Referencia a tus archivos locales)
  final List<Map<String, dynamic>> _niveles = [
    {
      'imagen': 'assets/quiz/drama1.jpg', // Goblin
      'correcta': 'Goblin (Guardian)',
      'opciones': ['Goblin (Guardian)', 'Doom at Your Service', 'Tale of the Nine Tailed', 'My Demon']
    },
    {
      'imagen': 'assets/quiz/drama2.jpg', // Squid Game
      'correcta': 'El Juego del Calamar',
      'opciones': ['Alice in Borderland', 'Sweet Home', 'El Juego del Calamar', 'All of Us Are Dead']
    },
    {
      'imagen': 'assets/quiz/drama3.jpg', // Woo Young Woo
      'correcta': 'Woo, una abogada extraordinaria',
      'opciones': ['Doctor Slump', 'Woo, una abogada extraordinaria', 'Start-Up', 'Hometown Cha-Cha-Cha']
    },
    {
      'imagen': 'assets/quiz/drama4.jpg', // Descendants of the Sun
      'correcta': 'Descendientes del Sol',
      'opciones': ['Crash Landing on You', 'Descendientes del Sol', 'Vincenzo', 'The Heirs']
    },
    {
      'imagen': 'assets/quiz/drama5.jpg', // Crash Landing on You
      'correcta': 'Aterrizaje de Emergencia',
      'opciones': ['Queen of Tears', 'Aterrizaje de Emergencia', 'King the Land', 'Something in the Rain']
    },
    {
      'imagen': 'assets/quiz/drama6.jpg', // Itaewon Class
      'correcta': 'Itaewon Class',
      'opciones': ['Start-Up', 'Itaewon Class', 'Fight for My Way', 'Reply 1988']
    },
    {
      'imagen': 'assets/quiz/drama7.jpg', // Vincenzo
      'correcta': 'Vincenzo',
      'opciones': ['Lawless Lawyer', 'The K2', 'Vincenzo', 'Big Mouth']
    },
    {
      'imagen': 'assets/quiz/drama8.jpg', // True Beauty
      'correcta': 'True Beauty',
      'opciones': ['My ID is Gangnam Beauty', 'True Beauty', 'Extraordinary You', 'Weightlifting Fairy']
    },
    {
      'imagen': 'assets/quiz/drama9.jpg', // Twenty-Five Twenty-One
      'correcta': 'Veinticinco, Veintiuno',
      'opciones': ['Our Beloved Summer', 'Veinticinco, Veintiuno', 'Start-Up', 'Weightlifting Fairy']
    },
    {
      'imagen': 'assets/quiz/drama10.jpg', // Business Proposal
      'correcta': 'Propuesta Laboral',
      'opciones': ['King the Land', 'What\'s Wrong with Secretary Kim', 'Propuesta Laboral', 'Her Private Life']
    },
  ];

  late List<String> _opcionesMezcladas;

  @override
  void initState() {
    super.initState();
    _prepararNivel();
  }

  void _prepararNivel() {
    _revelado = false;
    _opcionesMezcladas = List<String>.from(_niveles[_nivelActual]['opciones']);
    _opcionesMezcladas.shuffle(); // Mezclamos para que no sea obvio
  }

  void _verificarRespuesta(String respuesta) {
    if (_revelado) return;

    setState(() {
      _revelado = true;
    });

    bool esCorrecta = respuesta == _niveles[_nivelActual]['correcta'];

    if (esCorrecta) {
      _puntaje += 10;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("¡CORRECTO! 🎬✨", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ups... era ${_niveles[_nivelActual]['correcta']}", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (_nivelActual < _niveles.length - 1) {
            _nivelActual++;
            _prepararNivel();
          } else {
            _juegoTerminado = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_juegoTerminado) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1931),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text("¡Juego Terminado!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Puntaje Final: $_puntaje / ${_niveles.length * 10}", style: const TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nivelActual = 0;
                    _puntaje = 0;
                    _juegoTerminado = false;
                    _prepararNivel();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                child: const Text("JUGAR DE NUEVO"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("VOLVER AL MENÚ", style: TextStyle(color: Colors.white54)),
              )
            ],
          ),
        ),
      );
    }

    final nivel = _niveles[_nivelActual];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        title: Text("Nivel ${_nivelActual + 1}/${_niveles.length}"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
            child: Text("Pts: $_puntaje", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. LA IMAGEN MISTERIOSA
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // AHORA USAMOS IMAGE.ASSET
                    Image.asset(
                      nivel['imagen'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(child: Text("❌ Falta imagen", style: TextStyle(color: Colors.white))),
                    ),
                    
                    // EFECTO BORROSO
                    if (!_revelado)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      
                    // INTERROGACIÓN
                    if (!_revelado)
                      const Center(
                        child: Icon(Icons.question_mark_rounded, size: 80, color: Colors.white54),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. OPCIONES
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "¿Qué drama es?",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ..._opcionesMezcladas.map((opcion) {
                    bool esLaCorrecta = opcion == nivel['correcta'];
                    
                    Color colorBoton = Colors.white;
                    Color colorTexto = Colors.black;
                    
                    if (_revelado) {
                      if (esLaCorrecta) {
                        colorBoton = Colors.green;
                        colorTexto = Colors.white;
                      } else {
                        colorBoton = Colors.grey.shade800;
                        colorTexto = Colors.grey;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _verificarRespuesta(opcion),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorBoton,
                            foregroundColor: colorTexto,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(opcion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}