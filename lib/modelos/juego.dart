// ============================================================
// juego.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F6.2 (dos tipos de juego)
//
// Un JUEGO es: su nombre, desde qué lado se ve la figura y cómo se
// arman sus poses con los parámetros del panel. La pantalla del juego
// (ejecucion_screen.dart) es la misma para todos.
//
//  - «Imita a Quique»: juego LATERAL (inclinarse hacia los lados),
//    figura de frente.
//  - «De lo alto a lo bajo»: juego FRONTAL (erguido, a medio camino,
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
}

const Juego juegoImitaAQuique = Juego(
  id: 'imita_a_quique',
  nombre: 'Imita a Quique',
  descripcion: 'Inclínate hacia los lados',
  vista: VistaFigura.frente,
  poses: posesImitaAQuiqueCon,
);

const Juego juegoDeLoAltoALoBajo = Juego(
  id: 'de_lo_alto_a_lo_bajo',
  nombre: 'De lo alto a lo bajo',
  descripcion: 'Estírate, curva la espalda y hazte bolita',
  vista: VistaFigura.costado,
  poses: posesDeLoAltoALoBajoCon,
);

/// Los juegos que aparecen en el inicio del niño, en orden.
const List<Juego> juegosDisponibles = [juegoImitaAQuique, juegoDeLoAltoALoBajo];
