// ============================================================
// registro_juego.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F3
//
// CAMBIOS v4 respecto a la v3:
//  - Cada juego guarda qué TIPO DE CERO usó: 'automatico', 'calibrado'
//    o 'automatico_sin_calibracion' (se pidió calibrado pero el
//    participante no tenía). null en juegos anteriores a F3.
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
  double? segundosHastaEntrar;
  double? segundosHastaCompletar;
  int salidasDeZona = 0;
  int pistasUsadas = 0;
  int ayudasOfrecidas = 0;
  String resultado = 'intentada'; // 'completada' | 'intentada'

  MetricaPose({required this.indice, required this.instruccion});

  bool get completada => resultado == 'completada';

  Map<String, dynamic> toJson() => {
        'indice': indice,
        'instruccion': instruccion,
        'segundosHastaEntrar': segundosHastaEntrar,
        'segundosHastaCompletar': segundosHastaCompletar,
        'salidasDeZona': salidasDeZona,
        'pistasUsadas': pistasUsadas,
        'ayudasOfrecidas': ayudasOfrecidas,
        'resultado': resultado,
      };

  factory MetricaPose.desdeJson(Map<String, dynamic> j) {
    final m = MetricaPose(
      indice: (j['indice'] as num?)?.toInt() ?? 0,
      instruccion: j['instruccion'] as String? ?? '',
    );
    m.segundosHastaEntrar = (j['segundosHastaEntrar'] as num?)?.toDouble();
    m.segundosHastaCompletar = (j['segundosHastaCompletar'] as num?)?.toDouble();
    m.salidasDeZona = (j['salidasDeZona'] as num?)?.toInt() ?? 0;
    m.pistasUsadas = (j['pistasUsadas'] as num?)?.toInt() ?? 0;
    m.ayudasOfrecidas = (j['ayudasOfrecidas'] as num?)?.toInt() ?? 0;
    m.resultado = j['resultado'] as String? ?? 'intentada';
    return m;
  }
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
    return r;
  }
}
