// ============================================================
// juego.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso G2b
//
// CAMBIOS v3 respecto a la v2:
//  - `nombreSinViuda` y `descripcionSinViuda`: el mismo texto, pero con
//    las DOS ÚLTIMAS PALABRAS unidas por un espacio que no se corta
//    (U+00A0). Así, si el título ocupa dos líneas, la última nunca queda
//    con una sola palabra ("viuda"). Usarlos en tarjetas y títulos.
//
// Un JUEGO es: su nombre, desde qué lado se ve la figura y cómo se
// arman sus poses con los parámetros del panel. La pantalla del juego
// (ejecucion_screen.dart) es la misma para todos.
//
//  - «De izquierda a derecha»: juego LATERAL (inclinarse hacia los lados),
//    figura de frente.
//  - «Desde arriba para abajo»: juego FRONTAL (erguido, a medio camino,
//    bolita), figura de costado.
//
// El `id` es lo que queda en los registros y en la exportación.
// ============================================================

import 'parametros_juego.dart';
import 'pose.dart';

class Juego {
  final String id;
  final String nombre;
  final String descripcion; // frase corta para la tarjeta del niño
  final VistaFigura vista;
  final List<Pose> Function(ParametrosJuego) poses;

  const Juego({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.vista,
    required this.poses,
  });

  bool get esFrontal => vista == VistaFigura.costado;

  String get nombreSinViuda => sinViuda(nombre);
  String get descripcionSinViuda => sinViuda(descripcion);
}

/// Une las dos últimas palabras con un espacio que no se corta (U+00A0),
/// para que la última línea de un texto nunca quede con una sola palabra.
String sinViuda(String texto) {
  final i = texto.trimRight().lastIndexOf(' ');
  if (i <= 0) return texto;
  return '${texto.substring(0, i)}\u00A0${texto.substring(i + 1)}';
}

const Juego juegoImitaAQuique = Juego(
  id: 'imita_a_quique',
  nombre: 'De izquierda a derecha',
  descripcion: 'Inclínate hacia los lados',
  vista: VistaFigura.frente,
  poses: posesImitaAQuiqueCon,
);

const Juego juegoDeLoAltoALoBajo = Juego(
  id: 'de_lo_alto_a_lo_bajo',
  nombre: 'Desde arriba para abajo',
  descripcion: 'Estírate, curva la espalda y hazte bolita',
  vista: VistaFigura.costado,
  poses: posesDeLoAltoALoBajoCon,
);

/// Los juegos que aparecen en el inicio del niño, en orden.
const List<Juego> juegosDisponibles = [juegoImitaAQuique, juegoDeLoAltoALoBajo];
