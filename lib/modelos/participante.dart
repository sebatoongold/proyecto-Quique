// ============================================================
// participante.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F1b
//
// CAMBIOS v2 respecto a la v1:
//  - Se guarda la EDAD EXACTA (en años) en vez del grupo de edad
//    ('6-8' / '9-12'). Los grupos se arman después, en el análisis,
//    como se necesite.
//  - Perfiles creados con la v1: no tienen edad, así que aparecen como
//    "edad sin registrar" (no fallan). Conviene eliminarlos y crearlos
//    de nuevo antes del testeo.
//
// Un PARTICIPANTE es un niño del testeo: separa los datos de cada niño
// aunque todos usen el mismo teléfono y el mismo cinturón.
//  - codigo: identificador del testeo (P01, P02…), lo que se exporta.
//  - nombre: OPCIONAL, solo para saludarlo en la app.
//  - edad: años cumplidos (null = sin registrar).
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

  Participante({
    required this.codigo,
    this.nombre = '',
    required this.edad,
    required this.creado,
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
      };

  factory Participante.desdeJson(Map<String, dynamic> j) => Participante(
        codigo: j['codigo'] as String? ?? '?',
        nombre: j['nombre'] as String? ?? '',
        edad: (j['edad'] as num?)?.toInt(),
        creado: DateTime.tryParse(j['creado'] as String? ?? '') ?? DateTime(2000),
      );
}
