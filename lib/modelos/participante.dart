// ============================================================
// participante.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso F3
//
// CAMBIOS v3 respecto a la v2:
//  - El perfil guarda la CALIBRACIÓN de la postura neutral del niño
//    (clase Calibracion, abajo): su promedio adelante/lateral, qué
//    frase se le dijo, qué tan quieto estuvo y qué parte del tiempo el
//    firmware marcó "mala postura" estando en su postura neutral.
//    Ese último dato es la evidencia para justificar (o no) la
//    calibración relativa: si el umbral fijo marca como mala la postura
//    neutral de un niño, el umbral fijo no le sirve.
//
// Un PARTICIPANTE es un niño del testeo: separa los datos de cada niño
// aunque todos usen el mismo teléfono y el mismo cinturón.
//  - codigo: identificador del testeo (P01, P02…), lo que se exporta.
//  - nombre: OPCIONAL, solo para saludarlo en la app.
//  - edad: años cumplidos (null = sin registrar).
//  - calibracion: postura neutral medida con el botón (null = sin calibrar).
// ============================================================

// ---------- PARÁMETROS AJUSTABLES ----------
// Rango de edades que se pueden elegir al crear un participante. Es
// algo más amplio que el público (6 a 12) por si llega alguien fuera.
const int edadMinima = 4;
const int edadMaxima = 14;

class Participante {
  final String codigo; // P01, P02… (único)
  String nombre; // opcional; '' = sin nombre
  int? edad; // años; null = sin registrar (perfiles antiguos)
  final DateTime creado;
  Calibracion? calibracion; // null = todavía no se calibra

  Participante({
    required this.codigo,
    this.nombre = '',
    required this.edad,
    required this.creado,
    this.calibracion,
  });

  /// Cómo se nombra al niño en pantalla: su nombre si lo tiene; si no,
  /// el código.
  String get nombreVisible => nombre.trim().isEmpty ? codigo : nombre.trim();

  /// "8 años", "1 año" o "edad sin registrar".
  String get edadTexto {
    final e = edad;
    if (e == null) return 'edad sin registrar';
    return e == 1 ? '1 año' : '$e años';
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        'edad': edad,
        'creado': creado.toIso8601String(),
        'calibracion': calibracion?.toJson(),
      };

  factory Participante.desdeJson(Map<String, dynamic> j) {
    final cal = j['calibracion'];
    return Participante(
      codigo: j['codigo'] as String? ?? '?',
      nombre: j['nombre'] as String? ?? '',
      edad: (j['edad'] as num?)?.toInt(),
      creado: DateTime.tryParse(j['creado'] as String? ?? '') ?? DateTime(2000),
      calibracion: cal is Map<String, dynamic> ? Calibracion.desdeJson(cal) : null,
    );
  }
}

/// La postura neutral de un niño, medida con el botón "Calibrar".
/// Valores en las mismas unidades que usa el juego (con signo):
///  adelante: + hacia adelante, − hacia atrás;
///  lateral:  + hacia la derecha, − hacia la izquierda.
class Calibracion {
  final double adelante; // promedio durante la captura
  final double lateral;
  final double difXs; // lo mismo, tal como lo envía el firmware (para el comando CAL, paso F7)
  final double difYs;
  final double variacion; // cuánto se movió durante la captura (máx − mín, unidades)
  final double fraccionMalaPostura; // 0..1: parte de la captura en que el firmware marcó mala postura
  final int muestras; // lecturas promediadas
  final String instruccion; // frase que se le dijo al niño
  final DateTime fecha;

  const Calibracion({
    required this.adelante,
    required this.lateral,
    required this.difXs,
    required this.difYs,
    required this.variacion,
    required this.fraccionMalaPostura,
    required this.muestras,
    required this.instruccion,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'adelante': adelante,
        'lateral': lateral,
        'difXs': difXs,
        'difYs': difYs,
        'variacion': variacion,
        'fraccionMalaPostura': fraccionMalaPostura,
        'muestras': muestras,
        'instruccion': instruccion,
        'fecha': fecha.toIso8601String(),
      };

  factory Calibracion.desdeJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return Calibracion(
      adelante: n('adelante'),
      lateral: n('lateral'),
      difXs: n('difXs'),
      difYs: n('difYs'),
      variacion: n('variacion'),
      fraccionMalaPostura: n('fraccionMalaPostura'),
      muestras: (j['muestras'] as num?)?.toInt() ?? 0,
      instruccion: j['instruccion'] as String? ?? '',
      fecha: DateTime.tryParse(j['fecha'] as String? ?? '') ?? DateTime(2000),
    );
  }
}
