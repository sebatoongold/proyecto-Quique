// ============================================================
// quiz.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F9.2 (quiz antes y después de jugar)
//
// El QUIZ mide la Lectura del lado del niño: si reconoce la postura
// recta, cuál cansa si se mantiene, cuál siente cómoda y (al final)
// cuál le gustó. Se hace dos veces en la sesión, con el MISMO formato,
// para comparar antes y después de jugar:
//
//   pregunta                                        antes  después
//   recta   ¿En cuál la espalda está más recta?       ✓      ✓
//   cansa   ¿En cuál se cansa más tu espalda…?        ✓      ✓
//   comoda  ¿Cuál es la más cómoda?                   ✓      ✓
//   gusto   ¿Cuál te gustó más hacer?                        ✓
//
// Opciones: las 4 tarjetas de postura completas (figura en azul +
// ícono + nombre) en orden mezclado, más "No sé". Sin corrección.
//
// Por qué la tarjeta COMPLETA en ambos quiz (decisión del 19-10):
//  - Mismo formato antes y después: la diferencia se atribuye al juego,
//    no a un cambio en cómo se preguntó.
//  - La pista que da el animal (jirafa = alta; armadillo = bolita) está
//    en la IDEA del animal, no en la palabra: sacar el nombre y dejar el
//    ícono no la elimina. Los más chicos no leen (usan el ícono) y a los
//    que leen el nombre solo les confirma lo que ven.
//  - Que el niño "deduzca" la postura por el animal es lo que busca la
//    metáfora: si pasa, es evidencia de Lectura. Al estar igual en los
//    dos quiz, sube el punto de partida pero no sesga la comparación.
//  - Si las tarjetas ayudan a recordar se mira en la OBSERVACIÓN (si el
//    niño nombra los animales solo), no en el quiz.
//
// Lectura de cada respuesta (para Datos de prueba y la exportación):
//  - recta:  jirafa = esperada.
//  - cansa:  armadillo = esperada; tortuga = parcial (entiende que
//            curvarse cansa).
//  - comoda y gusto: sin respuesta correcta. Si marca ARMADILLO en
//    "cansa" y en "comoda", se destaca: la mala postura se siente cómoda.
// ============================================================

import 'animal_postura.dart';

/// Antes o después de jugar.
enum MomentoQuiz {
  antes('Antes de jugar'),
  despues('Después de jugar');

  final String titulo;
  const MomentoQuiz(this.titulo);

  static MomentoQuiz desdeNombre(String? n) => n == 'despues' ? despues : antes;
}

class PreguntaQuiz {
  final String id; // queda en los registros
  final String texto; // lo que lee el investigador y dice Quique
  final bool soloDespues;

  const PreguntaQuiz(this.id, this.texto, {this.soloDespues = false});
}

// ---------- PREGUNTAS (editar aquí el texto o el orden) ----------
const List<PreguntaQuiz> preguntasQuiz = [
  PreguntaQuiz('recta', '¿En cuál la espalda está más recta?'),
  PreguntaQuiz('cansa', '¿En cuál se cansa más tu espalda si te quedas así mucho rato?'),
  PreguntaQuiz('comoda', '¿Cuál es la más cómoda?'),
  PreguntaQuiz('gusto', '¿Cuál te gustó más hacer?', soloDespues: true),
];

/// Las preguntas que van en cada momento, en orden.
List<PreguntaQuiz> preguntasDe(MomentoQuiz m) =>
    [for (final p in preguntasQuiz) if (m == MomentoQuiz.despues || !p.soloDespues) p];

String textoPregunta(String id) =>
    preguntasQuiz.firstWhere((p) => p.id == id, orElse: () => PreguntaQuiz(id, id)).texto;

/// Respuesta "No sé" (lo demás son ids de AnimalPostura).
const String respuestaNoSe = 'no_se';

/// Cómo se lee una respuesta.
enum LecturaRespuesta {
  esperada('esperada'),
  parcial('parcial'),
  otra('otra'),
  noSe('no sabe'),
  sinCorrecta('—'); // pregunta sin respuesta correcta

  final String texto;
  const LecturaRespuesta(this.texto);
}

LecturaRespuesta leerRespuesta(String pregunta, String respuesta) {
  if (respuesta == respuestaNoSe) return LecturaRespuesta.noSe;
  switch (pregunta) {
    case 'recta':
      return respuesta == AnimalPostura.jirafa.id ? LecturaRespuesta.esperada : LecturaRespuesta.otra;
    case 'cansa':
      if (respuesta == AnimalPostura.armadillo.id) return LecturaRespuesta.esperada;
      if (respuesta == AnimalPostura.tortuga.id) return LecturaRespuesta.parcial;
      return LecturaRespuesta.otra;
    default:
      return LecturaRespuesta.sinCorrecta;
  }
}

/// Nombre para mostrar una respuesta ("Armadillo", "No sé").
String nombreRespuesta(String respuesta) =>
    respuesta == respuestaNoSe ? 'No sé' : (AnimalPostura.desdeId(respuesta)?.nombre ?? respuesta);

class RespuestaQuiz {
  final String pregunta; // id de la pregunta
  final String respuesta; // id del animal o 'no_se'
  final List<String> orden; // cómo se mostraron las tarjetas (de izq. a der., arriba a abajo)
  final int? msPrimerToque; // desde que apareció la pregunta hasta el primer toque
  final int msListo; // desde que apareció hasta tocar "¡Listo!"
  final int cambios; // cuántas veces cambió de opción antes de "¡Listo!"

  const RespuestaQuiz({
    required this.pregunta,
    required this.respuesta,
    required this.orden,
    required this.msPrimerToque,
    required this.msListo,
    required this.cambios,
  });

  LecturaRespuesta get lectura => leerRespuesta(pregunta, respuesta);

  Map<String, dynamic> toJson() => {
        'pregunta': pregunta,
        'respuesta': respuesta,
        'lectura': lectura.name,
        'orden': orden,
        'msPrimerToque': msPrimerToque,
        'msListo': msListo,
        'cambios': cambios,
      };

  factory RespuestaQuiz.desdeJson(Map<String, dynamic> j) => RespuestaQuiz(
        pregunta: j['pregunta'] as String? ?? '',
        respuesta: j['respuesta'] as String? ?? respuestaNoSe,
        orden: (j['orden'] as List?)?.whereType<String>().toList() ?? const [],
        msPrimerToque: (j['msPrimerToque'] as num?)?.toInt(),
        msListo: (j['msListo'] as num?)?.toInt() ?? 0,
        cambios: (j['cambios'] as num?)?.toInt() ?? 0,
      );
}

/// Un quiz hecho (antes o después) por un participante.
class SesionQuiz {
  final String? participante;
  final MomentoQuiz momento;
  final DateTime inicio;
  DateTime? fin;
  bool completo = false; // false = se salió antes de terminar
  final List<RespuestaQuiz> respuestas = [];

  SesionQuiz({required this.participante, required this.momento, required this.inicio});

  RespuestaQuiz? respuestaA(String pregunta) {
    for (final r in respuestas) {
      if (r.pregunta == pregunta) return r;
    }
    return null;
  }

  /// Marcó el armadillo como el que más cansa Y como el más cómodo.
  bool get armadilloCansaYComodo =>
      respuestaA('cansa')?.respuesta == AnimalPostura.armadillo.id &&
      respuestaA('comoda')?.respuesta == AnimalPostura.armadillo.id;

  Map<String, dynamic> toJson() => {
        'participante': participante,
        'momento': momento.name,
        'inicio': inicio.toIso8601String(),
        'fin': fin?.toIso8601String(),
        'completo': completo,
        'armadilloCansaYComodo': armadilloCansaYComodo,
        'respuestas': respuestas.map((r) => r.toJson()).toList(),
      };

  factory SesionQuiz.desdeJson(Map<String, dynamic> j) {
    final s = SesionQuiz(
      participante: j['participante'] as String?,
      momento: MomentoQuiz.desdeNombre(j['momento'] as String?),
      inicio: DateTime.tryParse(j['inicio'] as String? ?? '') ?? DateTime(2000),
    );
    s.fin = DateTime.tryParse(j['fin'] as String? ?? '');
    s.completo = j['completo'] == true;
    final rs = j['respuestas'];
    if (rs is List) {
      s.respuestas.addAll(rs.whereType<Map<String, dynamic>>().map(RespuestaQuiz.desdeJson));
    }
    return s;
  }
}
