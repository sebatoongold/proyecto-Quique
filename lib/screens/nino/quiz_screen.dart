// ============================================================
// quiz_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F9.2 (quiz antes y después de jugar)
//
// Pantalla del QUIZ, en el mundo del niño. La abre el INVESTIGADOR
// (Configuración → Testeo → Quiz) y la lee en voz alta.
//
// Cada pregunta:
//  - Quique con la pregunta en su globo;
//  - las 4 TARJETAS DE POSTURA (figura en AZUL + ícono + nombre) en
//    grilla de 2×2, en orden MEZCLADO en cada pregunta;
//  - "No sé" debajo;
//  - tocar marca la opción (borde grueso); "¡Listo!" la confirma. Se
//    puede cambiar de opción antes de confirmar (y se cuenta).
//  - Sin corrección: Quique solo dice "¡Gracias!".
//
// NEUTRAL A PROPÓSITO: las figuras van todas en azul (nunca el verde
// de "cómodo" del juego, que daría la respuesta), y la opción marcada
// se destaca igual para todas (borde azul grueso + ✓).
//
// Se guarda: respuesta, orden mostrado, ms hasta el primer toque, ms
// hasta "¡Listo!" y cambios de opción (ver modelos/quiz.dart). Si se
// sale a medias, queda guardado como incompleto.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../modelos/animal_postura.dart';
import '../../modelos/pose.dart';
import '../../modelos/quiz.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../servicios/servicio_quiz.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/figura_tu.dart';
import '../../widgets/icono_animal.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cuánto se muestra "¡Gracias!" antes de pasar a la siguiente pregunta.
const Duration duracionGracias = Duration(milliseconds: 900);
// Tamaño del ícono del animal en cada tarjeta.
const double iconoTarjetaQuiz = 36;
// Opacidad del color de fondo del animal en la tarjeta (0 = blanca).
const double opacidadFondoTarjetaQuiz = 0.35;

class QuizScreen extends StatefulWidget {
  final MomentoQuiz momento;
  const QuizScreen({super.key, required this.momento});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _azar = math.Random();
  late final List<PreguntaQuiz> _preguntas = preguntasDe(widget.momento);
  late final SesionQuiz _sesion = SesionQuiz(
    participante: ServicioParticipantes.instancia.activo.value?.codigo,
    momento: widget.momento,
    inicio: DateTime.now(),
  );

  int _indice = 0;
  List<AnimalPostura> _orden = [];
  String? _elegida; // id del animal o respuestaNoSe
  int _cambios = 0;
  int? _msPrimerToque;
  final Stopwatch _reloj = Stopwatch();
  bool _agradeciendo = false;
  bool _terminado = false;
  bool _guardado = false;

  @override
  void initState() {
    super.initState();
    _prepararPregunta();
  }

  void _prepararPregunta() {
    _orden = [...AnimalPostura.values]..shuffle(_azar);
    _elegida = null;
    _cambios = 0;
    _msPrimerToque = null;
    _reloj
      ..reset()
      ..start();
  }

  void _elegir(String opcion) {
    if (_agradeciendo) return;
    setState(() {
      _msPrimerToque ??= _reloj.elapsedMilliseconds;
      if (_elegida != null && _elegida != opcion) _cambios++;
      _elegida = opcion;
    });
  }

  Future<void> _listo() async {
    final elegida = _elegida;
    if (elegida == null || _agradeciendo) return;
    _sesion.respuestas.add(RespuestaQuiz(
      pregunta: _preguntas[_indice].id,
      respuesta: elegida,
      orden: [for (final a in _orden) a.id],
      msPrimerToque: _msPrimerToque,
      msListo: _reloj.elapsedMilliseconds,
      cambios: _cambios,
    ));
    setState(() => _agradeciendo = true);
    await Future<void>.delayed(duracionGracias);
    if (!mounted) return;
    setState(() {
      _agradeciendo = false;
      if (_indice < _preguntas.length - 1) {
        _indice++;
        _prepararPregunta();
      } else {
        _terminado = true;
        _sesion.completo = true;
        _guardar();
      }
    });
  }

  Future<void> _guardar() async {
    if (_guardado) return;
    _guardado = true;
    _sesion.fin = DateTime.now();
    await ServicioQuiz.instancia.guardar(_sesion);
  }

  /// Salir a medias: se pregunta y se guarda como incompleto.
  Future<void> _salir() async {
    if (_terminado) {
      Navigator.of(context).pop();
      return;
    }
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del quiz?'),
        content: const Text('Las respuestas que lleva se guardan como quiz incompleto.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salir')),
        ],
      ),
    );
    if (salir != true || !mounted) return;
    if (_sesion.respuestas.isNotEmpty) await _guardar();
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------
  // PANTALLA
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        backgroundColor: Colores.arena,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _terminado ? _cierre() : _pregunta(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pregunta() {
    final pregunta = _preguntas[_indice];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Salir',
              icon: const Icon(Icons.close_rounded, color: Colores.azul),
              onPressed: _salir,
            ),
            Expanded(
              child: Text('Pregunta ${_indice + 1} de ${_preguntas.length}',
                  textAlign: TextAlign.center, style: Textos.cuerpoDestacado),
            ),
            const SizedBox(width: 48), // equilibra el botón de salir
          ],
        ),
        _puntos(),
        const SizedBox(height: 10),
        _quique(_agradeciendo ? '¡Gracias!' : pregunta.texto),
        const SizedBox(height: 12),
        Expanded(child: _grilla()),
        const SizedBox(height: 10),
        Center(child: _botonNoSe()),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 58)),
          onPressed: _elegida == null || _agradeciendo ? null : _listo,
          child: const Text('¡Listo!'),
        ),
      ],
    );
  }

  Widget _puntos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _preguntas.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= _indice ? Colores.bosque : Colores.linea,
            ),
          ),
      ],
    );
  }

  /// Quique con la pregunta (o "¡Gracias!") en su globo.
  Widget _quique(String frase) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(color: Colores.quique, shape: BoxShape.circle),
          child: Icon(
            _agradeciendo ? Icons.sentiment_very_satisfied_rounded : Icons.sentiment_satisfied_rounded,
            size: 36,
            color: Colores.quiqueClaro,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colores.tarjeta,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colores.linea),
            ),
            child: Text(frase,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colores.azul)),
          ),
        ),
      ],
    );
  }

  Widget _grilla() {
    Widget fila(int a, int b) => Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _tarjeta(_orden[a])),
              const SizedBox(width: 12),
              Expanded(child: _tarjeta(_orden[b])),
            ],
          ),
        );
    return Column(
      children: [
        fila(0, 1),
        const SizedBox(height: 12),
        fila(2, 3),
      ],
    );
  }

  /// Tarjeta de postura del quiz: figura en azul, ícono y nombre.
  Widget _tarjeta(AnimalPostura animal) {
    final marcada = _elegida == animal.id;
    final p = ServicioParametros.instancia.actual.value;
    // La postura de cada animal (unidades), con los números del panel.
    final (vista, adelante, lateral, brazos) = switch (animal) {
      AnimalPostura.jirafa => (VistaFigura.costado, 0.0, 0.0, ModoBrazos.apoyados),
      AnimalPostura.tortuga => (VistaFigura.costado, p.anguloMedio, 0.0, ModoBrazos.apoyados),
      AnimalPostura.armadillo => (VistaFigura.costado, p.bolitaDesde + 12, 0.0, ModoBrazos.abrazo),
      AnimalPostura.pinguino => (VistaFigura.frente, 0.0, -p.anguloLateral, ModoBrazos.apoyados),
    };
    // El ícono del pingüino se inclina hacia el mismo lado que la figura.
    final espejarIcono = animal == AnimalPostura.pinguino && lateral * (p.espejo ? 1 : -1) > 0;

    return GestureDetector(
      onTap: () => _elegir(animal.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
              animal.fondo.withValues(alpha: opacidadFondoTarjetaQuiz), Colores.tarjeta),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: marcada ? Colores.azul : animal.borde,
            width: marcada ? 5 : 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 30),
                child: FiguraTu(
                  adelante: adelante,
                  lateral: lateral,
                  siluetaAdelante: 0,
                  siluetaLateral: 0,
                  color: Colores.azul, // NEUTRAL: igual para todas
                  mostrarSilueta: false,
                  mostrarSensores: false,
                  vista: vista,
                  brazos: brazos,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconoAnimal(animal: animal, tamano: iconoTarjetaQuiz, espejar: espejarIcono),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 6,
              child: Text(animal.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colores.azul)),
            ),
            if (marcada)
              const Positioned(
                top: 6,
                left: 6,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colores.azul,
                  child: Icon(Icons.check_rounded, size: 18, color: Colores.tarjeta),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _botonNoSe() {
    final marcada = _elegida == respuestaNoSe;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(180, 46),
        shape: const StadiumBorder(),
        foregroundColor: Colores.azul,
        backgroundColor: marcada ? Colores.tarjeta : null,
        side: BorderSide(color: marcada ? Colores.azul : Colores.neutro, width: marcada ? 4 : 1.5),
      ),
      onPressed: () => _elegir(respuestaNoSe),
      child: const Text('No sé', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    );
  }

  /// Fin: agradecimiento sin resultados. El botón es para el investigador.
  Widget _cierre() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: 56,
          backgroundColor: Colores.quique,
          child: Icon(Icons.sentiment_very_satisfied_rounded, size: 60, color: Colores.quiqueClaro),
        ),
        const SizedBox(height: 24),
        const Text('¡Gracias por ayudarme!', textAlign: TextAlign.center, style: Textos.titulo),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Terminar'),
        ),
      ],
    );
  }
}
