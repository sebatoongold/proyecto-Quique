// ============================================================
// animal_postura.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F9.1 (tarjetas de postura)
//
// Cada postura de los juegos tiene un ANIMAL: nombre, ícono y color
// propio. La figura, el ícono y el nombre aparecen siempre juntos
// (viñeta, tarjeta de la pose, miniatura del juego, cierre y, en F9.2,
// el quiz), para que el niño las recuerde y las distinga sin leer.
// Ver lamina_tarjetas_postura_v1.
//
//   jirafa     espalda estirada, bien alto (los dos juegos)
//   tortuga    a medio camino («De lo alto a lo bajo»)
//   armadillo  bolita: abraza tus rodillas («De lo alto a lo bajo»)
//   pinguino   inclinarse hacia un lado («Imita a Quique»)
//
// El `id` es lo que queda en los registros y en la exportación (sin
// tildes ni ñ, para no tener problemas al analizar).
// El dibujo de cada ícono está en widgets/icono_animal.dart.
// ============================================================

import 'package:flutter/painting.dart';

enum AnimalPostura {
  jirafa(
    id: 'jirafa',
    nombre: 'Jirafa',
    articulo: 'una',
    articuloDefinido: 'la',
    bueno: 'buena',
    // Ocre: el cuerpo de la jirafa; fondo del círculo; borde de tarjetas.
    color: Color(0xFFE3A73B),
    fondo: Color(0xFFF6E6C4),
    borde: Color(0xFFE3A73B),
  ),
  tortuga(
    id: 'tortuga',
    nombre: 'Tortuga',
    articulo: 'una',
    articuloDefinido: 'la',
    bueno: 'buena',
    color: Color(0xFFA9B85E),
    fondo: Color(0xFFE7EBCD),
    borde: Color(0xFF8E9C45),
  ),
  armadillo(
    id: 'armadillo',
    nombre: 'Armadillo',
    articulo: 'un',
    articuloDefinido: 'el',
    bueno: 'buen',
    color: Color(0xFFB5A385),
    fondo: Color(0xFFECE5D8),
    borde: Color(0xFF9C8A6C),
  ),
  pinguino(
    id: 'pinguino',
    nombre: 'Pingüino',
    articulo: 'un',
    articuloDefinido: 'el',
    bueno: 'buen',
    color: Color(0xFF243851),
    fondo: Color(0xFFD3E6EF),
    borde: Color(0xFF5E93BD),
  );

  final String id;
  final String nombre;
  final String articulo; // "¡Sé una jirafa!" / "¡Sé un pingüino!"
  final String articuloDefinido; // "¡Mira la jirafa de la esquina!"
  final String bueno; // "¡Qué buena jirafa!" / "¡Qué buen pingüino!"
  final Color color;
  final Color fondo;
  final Color borde;

  const AnimalPostura({
    required this.id,
    required this.nombre,
    required this.articulo,
    required this.articuloDefinido,
    required this.bueno,
    required this.color,
    required this.fondo,
    required this.borde,
  });

  /// "¡Sé una tortuga!"
  String get llamado => '¡Sé $articulo ${nombre.toLowerCase()}!';

  /// "la tortuga"
  String get conArticulo => '$articuloDefinido ${nombre.toLowerCase()}';

  /// "¡Qué buena tortuga!"
  String get felicitacion => '¡Qué $bueno ${nombre.toLowerCase()}!';

  static AnimalPostura? desdeId(String? id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return null;
  }
}
