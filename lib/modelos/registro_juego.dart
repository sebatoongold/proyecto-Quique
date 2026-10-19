// ============================================================
// registro_juego.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v7 — paso F9.1
//
// CAMBIOS v7 respecto a la v6:
//  - Cada pose guarda su ANIMAL (`animal`: 'jirafa', 'tortuga',
//    'armadillo' o 'pinguino'; null en juegos anteriores a F9.1). Sirve
//    para cruzar el juego con las respuestas del quiz (F9.2).
//
// Qué guarda (resumen):
//  - Cada juego guarda su LÍNEA DE EVENTOS (`eventos`): qué pasó y en
//    qué milisegundo desde el inicio del juego (viñeta, "¡Vamos!",
//    entró/salió de la zona, pista, ayuda y su respuesta, completó,
//    pausa, salida…). Ver la lista de tipos en EventoJuego.
//  - Cada pose guarda su RECORRIDO (`recorrido`): cada lectura del
//    cinturón desde "¡Vamos!" hasta completarla o saltarla (~3 por
//    segundo): ms desde "¡Vamos!", inclinación lateral y hacia adelante,
//    ya relativas a la postura cero.
//  - Cada pose guarda también su OBJETIVO y sus MÁRGENES, para poder
//    analizar el recorrido después (analisis_recorrido.dart).
//  - Todo es opcional: los juegos anteriores a F4 se leen igual.
//
// Lo que se guarda de cada juego jugado. Lo verá el APODERADO (y sirve
// para el análisis del testeo); el niño nunca ve estos números.
//
// Por cada POSE:
//  - segundosHastaEntrar: cuánto tardó en entrar a la zona por primera
//    vez (null = nunca entró). Mucho tiempo + muchas pistas sugiere que
//    la viñeta no se entiende.
//  - segundosHastaCompletar: cuánto tardó en completar los 10 s
//    (null = no la completó).
//  - salidasDeZona: cuántas veces salió de la zona después de entrar.
//    Entrar rápido pero salir mucho sugiere que la pose cuesta mantenerla.
//  - pistasUsadas: cuántas veces apareció la pista de los 20 s.
//  - ayudasOfrecidas: cuántas veces Quique ofreció ayuda (al minuto).
//  - resultado: "completada" o "intentada" (nunca "fallida").
//
// Por JUEGO: inicio y fin (sirven también para que los episodios de
// mala postura durante el juego no cuenten en el monitoreo), si fue
// interrumpido, si se completaron todas las poses, y la postura cero
// usada.
// ============================================================

class MetricaPose {
  final int indice; // 0, 1, 2…
  final String instruccion; // para reconocer la pose al leer el registro
  String? animal; // F9.1: id del animal de la pose (null = juego anterior)
  double? segundosHastaEntrar;
  double? segundosHastaCompletar;
  int salidasDeZona = 0;
  int pistasUsadas = 0;
  int ayudasOfrecidas = 0;
  String resultado = 'intentada'; // 'completada' | 'intentada'

  // F4: objetivo y márgenes de la pose (unidades, relativas al cero).
  double? objetivoLateral;
  double? objetivoAdelante;
  double? margenLateral;
  double? margenAdelante; // null = no se evaluaba adelante
  double? zonaAdelanteDesde; // F6.2: zona de límites (null = sin límite)
  double? zonaAdelanteHasta;

  // F4: recorrido. Tres listas del mismo largo.
  final List<int> recorridoMs = []; // ms desde "¡Vamos!"
  final List<double> recorridoLateral = [];
  final List<double> recorridoAdelante = [];

  MetricaPose({required this.indice, required this.instruccion});

  bool get tieneRecorrido => recorridoMs.isNotEmpty && objetivoLateral != null;

  bool get completada => resultado == 'completada';

  Map<String, dynamic> toJson() => {
        'indice': indice,
        'instruccion': instruccion,
        'animal': animal,
        'segundosHastaEntrar': segundosHastaEntrar,
        'segundosHastaCompletar': segundosHastaCompletar,
        'salidasDeZona': salidasDeZona,
        'pistasUsadas': pistasUsadas,
        'ayudasOfrecidas': ayudasOfrecidas,
        'resultado': resultado,
        'objetivoLateral': objetivoLateral,
        'objetivoAdelante': objetivoAdelante,
        'margenLateral': margenLateral,
        'margenAdelante': margenAdelante,
        'zonaAdelanteDesde': zonaAdelanteDesde,
        'zonaAdelanteHasta': zonaAdelanteHasta,
        'recorrido': {
          'ms': recorridoMs,
          'lateral': recorridoLateral,
          'adelante': recorridoAdelante,
        },
      };

  factory MetricaPose.desdeJson(Map<String, dynamic> j) {
    final m = MetricaPose(
      indice: (j['indice'] as num?)?.toInt() ?? 0,
      instruccion: j['instruccion'] as String? ?? '',
    );
    m.animal = j['animal'] as String?;
    m.segundosHastaEntrar = (j['segundosHastaEntrar'] as num?)?.toDouble();
    m.segundosHastaCompletar = (j['segundosHastaCompletar'] as num?)?.toDouble();
    m.salidasDeZona = (j['salidasDeZona'] as num?)?.toInt() ?? 0;
    m.pistasUsadas = (j['pistasUsadas'] as num?)?.toInt() ?? 0;
    m.ayudasOfrecidas = (j['ayudasOfrecidas'] as num?)?.toInt() ?? 0;
    m.resultado = j['resultado'] as String? ?? 'intentada';
    m.objetivoLateral = (j['objetivoLateral'] as num?)?.toDouble();
    m.objetivoAdelante = (j['objetivoAdelante'] as num?)?.toDouble();
    m.margenLateral = (j['margenLateral'] as num?)?.toDouble();
    m.margenAdelante = (j['margenAdelante'] as num?)?.toDouble();
    m.zonaAdelanteDesde = (j['zonaAdelanteDesde'] as num?)?.toDouble();
    m.zonaAdelanteHasta = (j['zonaAdelanteHasta'] as num?)?.toDouble();
    final r = j['recorrido'];
    if (r is Map<String, dynamic>) {
      final ms = (r['ms'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
      final la = (r['lateral'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
      final ad = (r['adelante'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
      // Solo si las tres listas calzan (si no, datos dañados).
      if (ms.length == la.length && ms.length == ad.length) {
        m.recorridoMs.addAll(ms);
        m.recorridoLateral.addAll(la);
        m.recorridoAdelante.addAll(ad);
      }
    }
    return m;
  }
}

/// Un evento del juego, en orden. `ms`: milisegundos desde el inicio
/// del juego. `pose`: índice de la pose (null si no aplica).
///
/// Tipos (`tipo`):
///   cero          se fijó la postura cero (dato: automatico / calibrado…)
///   vineta        apareció la explicación (viñetas) de una pose
///   vamos         el niño tocó "¡Vamos!"
///   entro         entró a la zona de la pose
///   salio         salió de la zona (más de la gracia)
///   pista         apareció la pista
///   ayuda         Quique ofreció ayuda
///   ayuda_resp    qué eligió (dato: seguir / saltar / salir)
///   completo      completó la pose (empieza la celebración)
///   pausa         abrió la pausa
///   pausa_resp    qué eligió (dato: seguir / salir)
///   fin           terminó el juego (llegó al cierre)
///   salida        salió del juego antes de terminar
///   otra_vez      tocó "Otra vez" en el cierre
class EventoJuego {
  final int ms;
  final String tipo;
  final int? pose;
  final String? dato;

  const EventoJuego(this.ms, this.tipo, {this.pose, this.dato});

  Map<String, dynamic> toJson() => {
        'ms': ms,
        'tipo': tipo,
        if (pose != null) 'pose': pose,
        if (dato != null) 'dato': dato,
      };

  factory EventoJuego.desdeJson(Map<String, dynamic> j) => EventoJuego(
        (j['ms'] as num?)?.toInt() ?? 0,
        j['tipo'] as String? ?? '',
        pose: (j['pose'] as num?)?.toInt(),
        dato: j['dato'] as String?,
      );
}

class RegistroJuego {
  final String juego; // identificador, ej. 'imita_a_quique'
  String? participante; // código del participante (P01…); null = sin participante
  Map<String, dynamic>? parametros; // parámetros del juego usados (ver parametros_juego.dart)
  String? tipoCero; // 'automatico' | 'calibrado' | 'automatico_sin_calibracion'
  final DateTime inicio; // reloj del celular
  DateTime? fin;
  bool interrumpido = false; // salió antes de terminar
  bool completado = false; // completó TODAS las poses
  double ceroAdelante = 0; // postura cero usada (unidades)
  double ceroLateral = 0;
  final List<MetricaPose> poses = [];
  final List<EventoJuego> eventos = []; // F4: línea de eventos, en orden

  /// Agrega un evento con la hora actual (ms desde el inicio del juego).
  void evento(String tipo, {int? pose, String? dato}) {
    eventos.add(EventoJuego(
      DateTime.now().difference(inicio).inMilliseconds,
      tipo,
      pose: pose,
      dato: dato,
    ));
  }

  RegistroJuego({required this.juego, required this.inicio});

  int get posesCompletadas => poses.where((p) => p.completada).length;

  Duration get duracion => (fin ?? inicio).difference(inicio);

  Map<String, dynamic> toJson() => {
        'juego': juego,
        'participante': participante,
        'parametros': parametros,
        'tipoCero': tipoCero,
        'inicio': inicio.toIso8601String(),
        'fin': fin?.toIso8601String(),
        'interrumpido': interrumpido,
        'completado': completado,
        'ceroAdelante': ceroAdelante,
        'ceroLateral': ceroLateral,
        'poses': poses.map((p) => p.toJson()).toList(),
        'eventos': eventos.map((e) => e.toJson()).toList(),
      };

  factory RegistroJuego.desdeJson(Map<String, dynamic> j) {
    final r = RegistroJuego(
      juego: j['juego'] as String? ?? '',
      inicio: DateTime.tryParse(j['inicio'] as String? ?? '') ?? DateTime(2000),
    );
    r.participante = j['participante'] as String?;
    final par = j['parametros'];
    if (par is Map<String, dynamic>) r.parametros = par;
    r.tipoCero = j['tipoCero'] as String?;
    final fin = j['fin'] as String?;
    r.fin = fin == null ? null : DateTime.tryParse(fin);
    r.interrumpido = j['interrumpido'] == true;
    r.completado = j['completado'] == true;
    r.ceroAdelante = (j['ceroAdelante'] as num?)?.toDouble() ?? 0;
    r.ceroLateral = (j['ceroLateral'] as num?)?.toDouble() ?? 0;
    final lista = j['poses'];
    if (lista is List) {
      for (final p in lista) {
        if (p is Map<String, dynamic>) r.poses.add(MetricaPose.desdeJson(p));
      }
    }
    final ev = j['eventos'];
    if (ev is List) {
      for (final e in ev) {
        if (e is Map<String, dynamic>) r.eventos.add(EventoJuego.desdeJson(e));
      }
    }
    return r;
  }
}
