import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../detalle_actor.dart'; 

class MbtiGame extends StatefulWidget {
  const MbtiGame({super.key});

  @override
  State<MbtiGame> createState() => _MbtiGameState();
}

class _MbtiGameState extends State<MbtiGame> {
  int _preguntaActual = 0;
  final Map<String, int> _puntajes = {'EI': 0, 'SN': 0, 'TF': 0, 'JP': 0};

  // 📝 LAS PREGUNTAS (Se mantienen igual)
  final List<Map<String, dynamic>> _preguntas = [
    {
      'texto': 'Es viernes por la noche después de una semana dura. ¿Qué haces?',
      'eje': 'EI',
      'opA': 'Salgo de fiesta con amigos (Soju Time! 🍾)', 'valA': 1,
      'opB': 'Me quedo en casa viendo K-Dramas con mascarilla 🧖‍♀️', 'valB': -1,
    },
    {
      'texto': 'En un grupo de amigos, tú sueles ser...',
      'eje': 'EI',
      'opA': 'Quien cuenta los chistes y organiza todo 🗣️', 'valA': 1,
      'opB': 'Quien escucha y observa tranquilamente 👀', 'valB': -1,
    },
    {
      'texto': 'Ves un drama histórico. ¿En qué te fijas más?',
      'eje': 'SN',
      'opA': 'En el vestuario, los escenarios y hechos reales 🏯', 'valA': 1,
      'opB': 'En el simbolismo, el destino y las teorías 🔮', 'valB': -1,
    },
    {
      'texto': 'Tu personaje favorito toma una decisión arriesgada...',
      'eje': 'SN',
      'opA': 'Pienso: "Eso no es realista, se va a morir" 😒', 'valA': 1,
      'opB': 'Pienso: "¡Qué romántico! El amor lo puede todo" 😍', 'valB': -1,
    },
    {
      'texto': 'Un amigo te cuenta que cortó con su pareja. ¿Qué haces?',
      'eje': 'TF',
      'opA': 'Analizo por qué pasó y le doy consejos lógicos 🧠', 'valA': 1,
      'opB': 'Lo abrazo y lloro con él/ella 😭', 'valB': -1,
    },
    {
      'texto': '¿Qué tipo de villano te da más miedo?',
      'eje': 'TF',
      'opA': 'El que es incompetente y arruina planes por error 📉', 'valA': 1,
      'opB': 'El que es cruel y manipula los sentimientos 💔', 'valB': -1,
    },
    {
      'texto': 'En una discusión, lo más importante es...',
      'eje': 'TF',
      'opA': 'Tener la razón y decir la verdad ☝️', 'valA': 1,
      'opB': 'No herir los sentimientos del otro 🤝', 'valB': -1,
    },
    {
      'texto': 'Vas a viajar a Corea del Sur. ¿Cómo lo planeas?',
      'eje': 'JP',
      'opA': 'Excel con horarios, rutas y reservas meses antes 📅', 'valA': 1,
      'opB': 'Compro el pasaje y veo qué hago al llegar ✈️', 'valB': -1,
    },
    {
      'texto': 'Tienes que entregar un trabajo importante...',
      'eje': 'JP',
      'opA': 'Lo termino días antes para estar tranquilo ✅', 'valA': 1,
      'opB': 'La inspiración me llega la noche anterior a la entrega 🔥', 'valB': -1,
    },
    {
      'texto': 'Tu habitación o escritorio suele estar...',
      'eje': 'JP',
      'opA': 'Impecable, todo tiene su lugar ✨', 'valA': 1,
      'opB': 'Un "caos organizado" donde yo entiendo todo 🌀', 'valB': -1,
    },
  ];

  void _siguientePregunta(String eje, int valor) {
    setState(() {
      _puntajes[eje] = (_puntajes[eje] ?? 0) + valor;
      _preguntaActual++;
    });
  }

  // 🧠 RESULTADOS CON IDs REALES DE TMDB (Para evitar errores)
  Map<String, dynamic> _obtenerResultado() {
    String mbti = "";
    mbti += (_puntajes['EI']! >= 0) ? "E" : "I";
    mbti += (_puntajes['SN']! < 0) ? "N" : "S";
    mbti += (_puntajes['TF']! >= 0) ? "T" : "F";
    mbti += (_puntajes['JP']! >= 0) ? "J" : "P";

    if (mbti.startsWith("E") && mbti.contains("F")) {
      return {
        'titulo': 'Protagonista Solar\n(Sunshine)',
        // ✅ USAMOS OBJETOS CON ID Y NOMBRE CORRECTO
        'actores': [
          {'nombre': 'Park Eun-bin', 'id': 1134684}, // 1134684
          {'nombre': 'Kim Se-jeong', 'id': 1834241}, // 1834241
        ], 
        'desc': 'Eres pura energía y alegría. Aunque a veces eres torpe, tu corazón noble enamora al CEO frío. ¡Tu superpoder es la resistencia!',
        'tipo': '$mbti • Alma de la Fiesta',
        'color': '0xFFFFA726',
        'icono': Icons.wb_sunny_rounded,
      };
    } else if (mbti.startsWith("I") && mbti.contains("T") && mbti.contains("J")) {
      return {
        'titulo': 'CEO Frío /\nGenio Estratega',
        'actores': [
          {'nombre': 'Park Seo-joon', 'id': 1347525}, // 1347525
          {'nombre': 'Lee Jun-ho', 'id': 1320503}, // 1320503
        ],
        'desc': 'Pareces distante y calculador, pero eres leal a muerte. Tienes un plan para todo y buscas la perfección.',
        'tipo': '$mbti • El Arquitecto',
        'color': '0xFF3F51B5',
        'icono': Icons.business_center_rounded,
      };
    } else if (mbti.contains("N") && mbti.contains("F")) {
      return {
        'titulo': 'Héroe Trágico /\nEl Poeta',
        'actores': [
          {'nombre': 'Gong Yoo', 'id': 150903}, // 150903
          {'nombre': 'IU (Lee Ji-eun)', 'id': 1252318}, // 1252318
        ],
        'desc': 'Vives con intensidad y pasión. Te guías por tus ideales y la intuición. Eres misterioso/a y atraes el destino.',
        'tipo': '$mbti • El Idealista',
        'color': '0xFFE91E63',
        'icono': Icons.auto_awesome,
      };
    } else if (mbti.contains("S") && mbti.contains("J")) {
      return {
        'titulo': 'Mejor Amigo Leal /\nProtector',
        'actores': [
          {'nombre': 'Jung Hae-in', 'id': 1470763}, // 1470763
          {'nombre': 'Kim Seon-ho', 'id': 1863349}, // 1863349
        ],
        'desc': 'Eres la roca del grupo. Confiable, práctico y siempre estás ahí para limpiar el desastre de los demás.',
        'tipo': '$mbti • El Guardián',
        'color': '0xFF43A047',
        'icono': Icons.shield_rounded,
      };
    } else {
      return {
        'titulo': 'Bad Boy\nCarismático',
        'actores': [
          {'nombre': 'Song Kang', 'id': 1878952}, // 1878952
          {'nombre': 'Han So-hee', 'id': 2112859}, // 2112859
        ],
        'desc': 'Haces tus propias reglas. Eres impredecible, encantador y muy astuto. No te gusta la rutina.',
        'tipo': '$mbti • El Aventurero',
        'color': '0xFF9C27B0',
        'icono': Icons.motorcycle_rounded,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preguntaActual >= _preguntas.length) {
      final resultado = _obtenerResultado();
      final colorTema = Color(int.parse(resultado['color']!));
      // Casteamos a lista de mapas
      final listaActores = resultado['actores'] as List<Map<String, dynamic>>;

      return Scaffold(
        backgroundColor: colorTema, 
        appBar: AppBar(
          title: const Text("TU ARQUETIPO", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)), 
          backgroundColor: Colors.transparent, 
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. HEADER 
            Expanded(
              flex: 3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                      ),
                      child: Icon(resultado['icono'], size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      resultado['tipo'],
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      resultado['titulo'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        height: 1.1
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. INFO CARD
            Expanded(
              flex: 5, 
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(30, 35, 30, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Text(
                      resultado['desc'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 25),
                    
                    const Text("TUS GEMELOS DE K-DRAMA", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 20),
                    
                    // 👇 AHORA PASAMOS EL OBJETO COMPLETO (NOMBRE + ID)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: listaActores.map((actor) => _ActorMiniatura(
                        nombre: actor['nombre'], 
                        tmdbId: actor['id']
                      )).toList(),
                    ),
                    
                    const Spacer(),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => setState(() {
                          _preguntaActual = 0;
                          _puntajes.updateAll((key, val) => 0);
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorTema,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text("VOLVER A JUGAR", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // PANTALLA DE PREGUNTAS (Sin cambios importantes, solo estéticos previos)
    final pregunta = _preguntas[_preguntaActual];
    final progreso = (_preguntaActual + 1) / _preguntas.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Pregunta ${_preguntaActual + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text("${_preguntas.length}", style: TextStyle(color: Colors.grey[400]))),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progreso, backgroundColor: Colors.grey[300], color: Colors.teal, minHeight: 8,
                ),
              ),
              const Spacer(flex: 1),
              Text(
                pregunta['texto'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3436), height: 1.3),
              ),
              const Spacer(flex: 2),
              _OpcionCard(texto: pregunta['opA'], letra: "A", color: Colors.indigo, onTap: () => _siguientePregunta(pregunta['eje'], pregunta['valA'])),
              const SizedBox(height: 16),
              _OpcionCard(texto: pregunta['opB'], letra: "B", color: Colors.purple, onTap: () => _siguientePregunta(pregunta['eje'], pregunta['valB'])),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  final String texto;
  final String letra;
  final Color color;
  final VoidCallback onTap;
  const _OpcionCard({required this.texto, required this.letra, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 22,
              child: Text(letra, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
          ],
        ),
      ),
    );
  }
}

// ⭐ WIDGET OPTIMIZADO: YA NO BUSCA, USA EL ID DIRECTO
class _ActorMiniatura extends StatefulWidget {
  final String nombre;
  final int tmdbId; // Recibimos el ID exacto

  const _ActorMiniatura({required this.nombre, required this.tmdbId});

  @override
  State<_ActorMiniatura> createState() => _ActorMiniaturaState();
}

class _ActorMiniaturaState extends State<_ActorMiniatura> {
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _obtenerFoto();
  }

  // Ahora es mucho más rápido y seguro
  Future<void> _obtenerFoto() async {
    final apiKey = dotenv.env['TMDB_KEY'] ?? '';
    // Pedimos los detalles directos del ID
    final url = Uri.parse('https://api.themoviedb.org/3/person/${widget.tmdbId}?api_key=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _fotoUrl = data['profile_path'];
          });
        }
      }
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegamos al perfil para agregarlo a favoritos
        Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleActor(
          actorId: widget.tmdbId, 
          nombre: widget.nombre, 
          fotoUrl: _fotoUrl != null ? 'https://image.tmdb.org/t/p/w500$_fotoUrl' : '',
        )));
      },
      child: Column(
        children: [
          Container(
            width: 70, height: 70, 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
              image: _fotoUrl != null 
                ? DecorationImage(image: NetworkImage('https://image.tmdb.org/t/p/w200$_fotoUrl'), fit: BoxFit.cover)
                : null,
            ),
            child: _fotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(height: 8),
          Text(
            widget.nombre.split(' ')[0], 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.nombre.split(' ').length > 1 ? widget.nombre.split(' ')[1] : "", 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}