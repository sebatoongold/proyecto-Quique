// ============================================================
// pose.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso C4, corrección tras la primera prueba física
//
// CAMBIOS v2 respecto a la v1:
//  - Cada pose tiene su propio margen POR EJE (lateral y adelante), en
//    vez de una sola distancia. Así, en una pose de inclinarse de lado,
//    se evalúa sobre todo el lado, que es lo que la figura muestra.
//  - Márgenes más amplios (antes 6 unidades ≈ 4°, demasiado estricto).
//
// Una pose es una postura objetivo que el niño debe alcanzar y
// mantener. Se mide RELATIVA a su postura cero (cómo se sienta
// derecho), en las mismas "unidades" que envía el sensor.
//
// Referencia de unidades: cerca de la postura erguida,
//   unidades ≈ 90 × seno(ángulo)  ->  18 unidades ≈ 11,5°,
//   10 unidades ≈ 6,5°, 30 unidades ≈ 19,5°.
// ============================================================

// ---------- MÁRGENES POR DEFECTO (unidades) ----------
// Cuánto puede alejarse el niño de la pose y que igual cuente.
// Más grande = más fácil. 9 unidades ≈ 6°, 20 unidades ≈ 13°.
const double margenLateralPorDefecto = 9;
// Hacia adelante/atrás, en poses de lado, el margen es amplio a
// propósito: solo frena un encorvamiento marcado (al inclinarse de
// lado, el cuerpo se encorva un poco de forma natural).
const double margenAdelantePorDefecto = 20;

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
// Para cambiar el juego, se edita solo esta lista: agregar, quitar,
// reordenar, o ajustar cuánto hay que inclinarse.
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
