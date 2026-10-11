// ============================================================
// datos_postura.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — un dato en vivo del wearable, ya interpretado
//
// Convierte el texto JSON que envía el ESP32 cada ~330 ms en un objeto
// de Dart fácil de usar desde cualquier pantalla. Ejemplo de lo que
// llega (firmware v7):
// {"x":87,"y":102,"diff":15,"diffY":4,"difXs":-15,"difYs":4,"malaPostura":true}
//
// Funciona también con firmware anterior a v7 (sin difXs/difYs): en
// ese caso la dirección queda en 0 y "conDireccion" es false.
// ============================================================

import 'dart:convert';

class DatosPostura {
  // ############################################################
  // ## DIRECCIÓN SEGÚN EL MONTAJE DE LOS SENSORES               ##
  // ############################################################
  // Verificado el 11-10-2026 en el Monitor Serial:
  //   encorvarse hacia ADELANTE  -> DifXs NEGATIVO (hacia atrás: positivo)
  //   inclinarse a la IZQUIERDA  -> DifYs NEGATIVO (a la derecha: positivo)
  //
  // Con estos signos, en la app:
  //   "adelante" positivo = hacia adelante, negativo = hacia atrás
  //   "lateral"  positivo = hacia la derecha, negativo = hacia la izquierda
  //
  // Si se cambia cómo están montados los sensores, se ajustan SOLO
  // estos dos números (1 o -1) y todo lo demás sigue funcionando.
  static const int signoAdelante = -1;
  static const int signoDerecha = 1;

  final int x; // ángulo del cuello, eje X (escala 0–180, no grados reales)
  final int y; // ángulo del cuello, eje Y
  final int diff; // diferencia cuello-cadera hacia adelante/atrás, sin signo
  final int diffY; // diferencia cuello-cadera lateral, sin signo
  final int difXs; // la misma diferencia X, CON signo (v7)
  final int difYs; // la misma diferencia Y, CON signo (v7)
  final bool malaPostura; // decidido por el firmware según sus umbrales
  final bool conDireccion; // true si el firmware envía difXs/difYs (v7 o superior)

  const DatosPostura({
    required this.x,
    required this.y,
    required this.diff,
    required this.diffY,
    required this.difXs,
    required this.difYs,
    required this.malaPostura,
    required this.conDireccion,
  });

  /// Cuánto se inclina hacia adelante (+) o hacia atrás (−), en unidades.
  int get adelante => difXs * signoAdelante;

  /// Cuánto se inclina hacia la derecha (+) o la izquierda (−), en unidades.
  int get lateral => difYs * signoDerecha;

  factory DatosPostura.desdeJson(Map<String, dynamic> json) {
    // Si un campo no viene (firmware antiguo) se usa 0, en vez de que
    // la app falle.
    int leer(String clave) => (json[clave] as num?)?.round() ?? 0;

    return DatosPostura(
      x: leer('x'),
      y: leer('y'),
      diff: leer('diff'),
      diffY: leer('diffY'),
      difXs: leer('difXs'),
      difYs: leer('difYs'),
      malaPostura: json['malaPostura'] == true,
      conDireccion: json.containsKey('difXs'),
    );
  }

  /// Devuelve null si el texto llegó incompleto o corrupto (puede pasar
  /// de vez en cuando con Bluetooth). Quien lo use simplemente espera
  /// el siguiente dato.
  static DatosPostura? desdeTexto(String texto) {
    try {
      final decodificado = jsonDecode(texto);
      if (decodificado is Map<String, dynamic>) {
        return DatosPostura.desdeJson(decodificado);
      }
    } catch (_) {
      // dato corrupto: se ignora
    }
    return null;
  }
}
