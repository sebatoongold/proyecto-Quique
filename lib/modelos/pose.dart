// ============================================================
// pose.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F6.2
//
// CAMBIOS v4 respecto a la v3:
//  - Una pose puede tener una ZONA ADELANTE CON LÍMITES (`adelanteDesde`
//    y/o `adelanteHasta`) en vez de objetivo ± margen. Un límite en null
//    = sin límite: así se hacen zonas de UN SOLO LADO ("todo lo erguido
//    o más", "todo lo curvado o más"). Ver errorAdelanteDe().
//  - Cada pose puede tener sus propios SEGUNDOS para mantenerla
//    (`segundos`; null = los del panel) y sus BRAZOS (`brazos`).
//  - Aquí viven ahora los tipos VistaFigura y ModoBrazos (antes en
//    figura_tu.dart).
//  - Nueva función posesDeLoAltoALoBajoCon(parametros): el juego frontal.
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

/// Desde qué lado se dibuja la figura en un juego.
enum VistaFigura { frente, costado }

/// Qué hacen los brazos en una pose (solo dibujo: no se miden).
enum ModoBrazos { apoyados, abrazo, arriba }

class Pose {
  final String instruccion; // frase grande para el niño (simple, corta)
  final String detalle; // frase secundaria
  final double adelante; // objetivo: + hacia adelante, − hacia atrás
  final double lateral; // objetivo: + hacia la derecha, − hacia la izquierda
  final double margenLateral; // cuánto puede desviarse hacia los lados
  final double? margenAdelante; // ídem adelante/atrás; null = no se evalúa
  // Zona adelante con límites (unidades). Si alguno no es null, manda
  // sobre margenAdelante. null = sin límite por ese lado.
  final double? adelanteDesde;
  final double? adelanteHasta;
  final double? segundos; // segundos para mantenerla; null = los del panel
  final ModoBrazos brazos;

  const Pose({
    required this.instruccion,
    required this.detalle,
    required this.adelante,
    required this.lateral,
    this.margenLateral = margenLateralPorDefecto,
    this.margenAdelante = margenAdelantePorDefecto,
    this.adelanteDesde,
    this.adelanteHasta,
    this.segundos,
    this.brazos = ModoBrazos.apoyados,
  });

  bool get usaRango => adelanteDesde != null || adelanteHasta != null;

  /// Cuánto le falta en el eje adelante (unidades). 0 = dentro.
  /// Positivo: debe curvarse más hacia adelante. Negativo: debe
  /// enderezarse. Con zona de límites, se mide hasta el límite más
  /// cercano; si no, hasta el objetivo.
  double errorAdelanteDe(double actual) {
    if (!usaRango) return adelante - actual;
    final d = adelanteDesde, h = adelanteHasta;
    if (d != null && actual < d) return d - actual;
    if (h != null && actual > h) return h - actual;
    return 0;
  }

  /// ¿El eje adelante está dentro de la zona?
  bool adelanteDentro(double error) =>
      usaRango ? error == 0 : (margenAdelante == null || error.abs() <= margenAdelante!);
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

// ---------- POSES DEL JUEGO FRONTAL ("De lo alto a lo bajo") ----------
// Vista de costado. Alto → medio camino → bolita → alto otra vez.
// Los números vienen del panel (Parámetros → Juego frontal):
//  - alto: cuenta todo lo erguido o más (adelante ≤ altoHasta);
//  - medio camino: zona angosta alrededor de anguloMedio (± margenMedio):
//    es la pose que pide control fino;
//  - bolita: cuenta todo lo curvado o más (adelante ≥ bolitaDesde), y se
//    mantiene menos tiempo (segundosBolita).
// En las cuatro, el lado tiene un margen amplio: solo cuenta adelante.
// `adelante` es solo dónde se DIBUJA la silueta.
const double margenLateralJuegoFrontal = 35;

List<Pose> posesDeLoAltoALoBajoCon(ParametrosJuego p) {
  Pose alto(String instruccion, String detalle) => Pose(
        instruccion: instruccion,
        detalle: detalle,
        adelante: 0,
        lateral: 0,
        margenLateral: margenLateralJuegoFrontal,
        adelanteHasta: p.altoHasta,
      );
  return [
    alto('Siéntate muy alto, como una jirafa', 'Estira la espalda hacia el techo.'),
    Pose(
      instruccion: 'Ahora curva un poquito la espalda',
      detalle: 'Solo un poco: a medio camino.',
      adelante: p.anguloMedio,
      lateral: 0,
      margenLateral: margenLateralJuegoFrontal,
      adelanteDesde: p.anguloMedio - p.margenMedio,
      adelanteHasta: p.anguloMedio + p.margenMedio,
    ),
    Pose(
      instruccion: 'Hazte bolita: abraza tus rodillas',
      detalle: 'Con los pies en el suelo.',
      adelante: p.bolitaDesde + 12,
      lateral: 0,
      margenLateral: margenLateralJuegoFrontal,
      adelanteDesde: p.bolitaDesde,
      segundos: p.segundosBolita,
      brazos: ModoBrazos.abrazo,
    ),
    alto('Vuelve a sentarte muy alto', '¡Como la jirafa!'),
  ];
}
