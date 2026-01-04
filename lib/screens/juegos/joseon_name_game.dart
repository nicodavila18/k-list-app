import 'package:flutter/material.dart';

class JoseonNameGame extends StatefulWidget {
  const JoseonNameGame({super.key});

  @override
  State<JoseonNameGame> createState() => _JoseonNameGameState();
}

class _JoseonNameGameState extends State<JoseonNameGame> {
  DateTime? _fechaSeleccionada;
  
  String _nombreRomanizado = ""; 
  String _nombreHangul = "";     
  String _significadoCompleto = "";
  
  bool _mostrarResultado = false;
  bool _mostrarSello = false; 

  // 📜 DATOS
  final List<Map<String, String>> _apellidosData = [
    {'k': 'Park (박)', 's': 'Brillante / Sencillo'}, 
    {'k': 'Kim (김)', 's': 'Oro / Realeza'},        
    {'k': 'Shin (신)', 's': 'Confianza / Fe'},      
    {'k': 'Choi (최)', 's': 'Elevado / Montaña'},   
    {'k': 'Song (송)', 's': 'Pino / Longevidad'},   
    {'k': 'Kang (강)', 's': 'Río / Fuerte'},        
    {'k': 'Han (한)', 's': 'Corea / Grande'},       
    {'k': 'Lee (이)', 's': 'Ciruelo / Sabio'},      
    {'k': 'Sung (성)', 's': 'Logro / Éxito'},       
    {'k': 'Jung (정)', 's': 'Justicia / Derecho'},  
  ];

  final List<Map<String, String>> _segundosNombresData = [
    {'k': '', 's': ''}, 
    {'k': 'Yong (용)', 's': 'Dragón'},           
    {'k': 'Ji (지)', 's': 'Sabiduría'},          
    {'k': 'Je (제)', 's': 'Emperador'},          
    {'k': 'Hye (혜)', 's': 'Inteligencia'},       
    {'k': 'Dong (동)', 's': 'Este / Cobre'},      
    {'k': 'Sang (상)', 's': 'Nobleza'},           
    {'k': 'Ha (하)', 's': 'Grandeza'},            
    {'k': 'Hyo (효)', 's': 'Piedad Filial'},      
    {'k': 'Soo (수)', 's': 'Excelencia'},          
    {'k': 'Eun (은)', 's': 'Gracia / Plata'},     
    {'k': 'Hyun (현)', 's': 'Virtud'},            
    {'k': 'Rae (래)', 's': 'Futuro'},             
  ];

  final List<Map<String, String>> _nombresData = [
    {'k': '', 's': ''}, 
    {'k': 'Hwa (화)', 's': 'Gloria'}, {'k': 'Woo (우)', 's': 'Universo'}, {'k': 'Joon (준)', 's': 'Talento'}, 
    {'k': 'Hee (희)', 's': 'Alegría'}, {'k': 'Kyo (교)', 's': 'Enseñanza'}, {'k': 'Kyung (경)', 's': 'Honor'}, 
    {'k': 'Wook (욱)', 's': 'Amanecer'}, {'k': 'Jin (진)', 's': 'Verdad'}, {'k': 'Jae (재)', 's': 'Respeto'}, 
    {'k': 'Hoon (훈)', 's': 'Mérito'}, {'k': 'Ra (라)', 's': 'Red'}, {'k': 'Bin (빈)', 's': 'Refinado'}, 
    {'k': 'Sun (선)', 's': 'Bondad'}, {'k': 'Ri (리)', 's': 'Ganancia'}, {'k': 'Soo (수)', 's': 'Vida Larga'}, 
    {'k': 'Rim (림)', 's': 'Jade'}, {'k': 'Ah (아)', 's': 'Hermoso'}, {'k': 'Ae (애)', 's': 'Amor'}, 
    {'k': 'Neul (늘)', 's': 'Cielo'}, {'k': 'Mun (문)', 's': 'Escritura'}, {'k': 'In (인)', 's': 'Humanidad'}, 
    {'k': 'Mi (미)', 's': 'Belleza'}, {'k': 'Ki (기)', 's': 'Energía'}, {'k': 'Sang (상)', 's': 'Mutuo'}, 
    {'k': 'Byung (병)', 's': 'Brillante'}, {'k': 'Seok (석)', 's': 'Piedra Fuerte'}, {'k': 'Gun (건)', 's': 'Fundador'}, 
    {'k': 'Yoo (유)', 's': 'Suave'}, {'k': 'Sup (섭)', 's': 'Llama'}, {'k': 'Won (원)', 's': 'Origen'}, 
    {'k': 'Sub (섭)', 's': 'Llama'}
  ];

  String _extraerRomanizado(String raw) => raw.split(' (')[0];
  String _extraerHangul(String raw) => raw.split(' (')[1].replaceAll(')', '');

  void _generarNombre() {
    if (_fechaSeleccionada == null) return;
    
    setState(() {
      _mostrarResultado = false;
      _mostrarSello = false;
    });

    String anioStr = _fechaSeleccionada!.year.toString();
    int idxApellido = int.parse(anioStr[anioStr.length - 1]);
    int idxMes = _fechaSeleccionada!.month;
    int idxDia = _fechaSeleccionada!.day > 30 ? 30 : _fechaSeleccionada!.day;

    var dAp = _apellidosData[idxApellido];
    var dMes = _segundosNombresData[idxMes];
    var dDia = _nombresData[idxDia];

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _nombreRomanizado = "${_extraerRomanizado(dAp['k']!)} ${_extraerRomanizado(dMes['k']!)} ${_extraerRomanizado(dDia['k']!)}";
        _nombreHangul = "${_extraerHangul(dAp['k']!)} ${_extraerHangul(dMes['k']!)} ${_extraerHangul(dDia['k']!)}";
        _significadoCompleto = "${dAp['s']} • ${dMes['s']} • ${dDia['s']}";
        _mostrarResultado = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _mostrarSello = true);
      });
    });
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4A017), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
      _generarNombre();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Tu Destino Real", style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/banner_joseon.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)), 
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu, size: 50, color: Color(0xFFD4A017)), 
                  const SizedBox(height: 10),
                  const Text(
                    "Revela tu identidad de la Era Joseon",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _seleccionarFecha,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1), 
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD4A017)), 
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _fechaSeleccionada == null 
                        ? "TOCA PARA ELEGIR FECHA" 
                        : "NACIDO EL: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}",
                      style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (_mostrarResultado)
                    Stack(
                      alignment: Alignment.topRight,
                      clipBehavior: Clip.none, // 🔓 PERMITE QUE EL SELLO SALGA DEL BORDE
                      children: [
                        // --- LA TARJETA ---
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 15, right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A), 
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFD4A017), width: 2), 
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFD4A017).withOpacity(0.2), blurRadius: 30, spreadRadius: 0)
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text("Tu nombre noble es", style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)),
                              const SizedBox(height: 20),
                              
                              // NOMBRE EN ESPAÑOL
                              Text(
                                _nombreRomanizado,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36, 
                                  fontWeight: FontWeight.w900, 
                                  color: Color(0xFFFFC107), 
                                  fontFamily: 'Serif', 
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(blurRadius: 0, color: Colors.black, offset: Offset(2, 2))
                                  ]
                                ),
                              ),

                              const SizedBox(height: 10),

                              // NOMBRE EN HANGUL
                              Text(
                                _nombreHangul,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 4.0, 
                                ),
                              ),
                              
                              const SizedBox(height: 25),
                              const Divider(color: Color(0xFFD4A017), thickness: 0.5, indent: 50, endIndent: 50),
                              const SizedBox(height: 20),

                              Text(
                                "\"$_significadoCompleto\"",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16, 
                                  color: Color(0xFFE0E0E0), 
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w300
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- SELLO ROJO ---
                        Positioned(
                          top: -20, // ⬆️ SUBIMOS EL SELLO (Antes era 0)
                          right: -10, // ➡️ LO MOVEMOS A LA DERECHA (Antes era 0)
                          child: AnimatedScale(
                            scale: _mostrarSello ? 1.0 : 3.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            child: AnimatedOpacity(
                              opacity: _mostrarSello ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Transform.rotate(
                                angle: -0.15,
                                child: Image.asset(
                                  'assets/sello_joseon.png',
                                  width: 100,
                                  fit: BoxFit.contain,
                                  // SIN FILTROS DE COLOR
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}