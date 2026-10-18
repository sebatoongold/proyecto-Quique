// ============================================================
// pose.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso F2
//
// CAMBIOS v3 respecto a la v2:
//  - Nueva función posesImitaAQuiqueCon(parametros): arma las poses del
//    juego con el ángulo y los márgenes elegidos en el panel de
//    parámetros. La lista posesImitaAQuique queda como PLANTILLA (las
//    frases y el orden); sus números se reemplazan por los del panel.
//  - Los márgenes por defecto ahora viven en parametros_juego.dart.
//
// Una pose es una postura objetivo que el niño debe alcanzar y
// mantener. Se mide RELATIVA a su postura cero (cómo se sienta
// derecho), en las mismas "unidades" que envía el sensor.
//
// Referencia de unidades: cerca de la postura erguida,
//   unidades ≈ 90 × seno(ángulo)  ->  18 unidades ≈ 11,5°,
//   10 unidades ≈ 6,5°, 30 unidades ≈ 19,5°.
// ============================================================

import 'parametros_juego.dart';

// Márgenes por defecto: se toman de parametros_juego.dart (un solo
// lugar para cambiarlos).
const double margenLateralPorDefecto = defectoMargenLateral;
const double margenAdelantePorDefecto = defectoMargenAdelante;

class Pose {
  final String instruccion; // frase grande para el niño (simple, corta)
  final String detalle; // frase secundaria
  final double adelante; // objetivo: + hacia adelante, − hacia atrás
  final double lateral; // objetivo: + hacia la derecha, − hacia la izquierda
  final double margenLateral; // cuánto puede desviarse hacia los lados
  final double? margenAdelante; // ídem adelante/atrás; null = no se evalúa

  const Pose({
    required this.instruccion,
    required this.detalle,
    required this.adelante,
    required this.lateral,
    this.margenLateral = margenLateralPorDefecto,
    this.margenAdelante = margenAdelantePorDefecto,
  });
}

// ---------- POSES DEL JUEGO DE PRUEBA ("Imita a Quique") ----------
// PLANTILLA: para cambiar las frases o el orden, se edita esta lista.
// Cuánto hay que inclinarse y los márgenes los pone el panel de
// parámetros (ver posesImitaAQuiqueCon, al final del archivo).
// OJO: la vista de frente muestra solo la inclinación hacia los lados.
// El encorvamiento no se dibuja: si es lo que falla, Quique lo dice
// con texto. Para juegos de adelante/atrás se hará una vista de costado.
const List<Pose> posesImitaAQuique = [
  Pose(
    instruccion: 'Inclínate hacia tu izquierda',
    detalle: 'Despacito, como Quique.',
    adelante: 0,
    lateral: -18,
  ),
  Pose(
    instruccion: 'Ahora hacia tu derecha',
    detalle: 'Despacito.',
    adelante: 0,
    lateral: 18,
  ),
  Pose(
    instruccion: 'Vuelve al centro, bien derecho',
    detalle: '¡Ya casi terminamos!',
    adelante: 0,
    lateral: 0,
    // Aquí sí importa estar derecho: margen hacia adelante más estricto.
    margenAdelante: 10,
  ),
];

/// Las poses del juego con los números del panel de parámetros:
///  - poses de lado: se inclina `anguloLateral` hacia su lado (se
///    conserva el signo de la plantilla), con `margenLateral` y
///    `margenAdelante`;
///  - pose del centro (lateral 0 en la plantilla): con
///    `margenAdelanteCentro`, porque ahí sí importa estar derecho.
List<Pose> posesImitaAQuiqueCon(ParametrosJuego p) => [
      for (final base in posesImitaAQuique)
        Pose(
          instruccion: base.instruccion,
          detalle: base.detalle,
          adelante: base.adelante,
          lateral: base.lateral == 0 ? 0.0 : base.lateral.sign * p.anguloLateral,
          margenLateral: p.margenLateral,
          margenAdelante: base.lateral == 0 ? p.margenAdelanteCentro : p.margenAdelante,
        ),
    ];
