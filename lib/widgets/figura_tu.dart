// ============================================================
// figura_tu.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso C4, corrección tras la primera prueba física
//
// CAMBIOS v2 respecto a la v1:
//  - De frente ya NO se muestra el encorvamiento (antes "acortaba" la
//    espalda, algo difícil de leer y que confundía). Esta vista muestra
//    solo la inclinación hacia los lados; para juegos de adelante/atrás
//    se hará una vista de costado. El encorvamiento se avisa con texto.
//  - Se dibuja la ZONA de la pose: una cuña clara alrededor de la
//    silueta, del ancho exacto del margen que usa el juego. Si la cabeza
//    de «Tú» está dentro de la cuña, cuenta. Lo que se ve = lo que cuenta.
//  - Silueta más delgada (antes, por gruesa, parecía que la figura
//    calzaba aunque estuviera corrida).
//
// Dibuja dos figuras de frente, superpuestas:
//  - la SILUETA (gris azulado claro, más gruesa): la pose objetivo;
//  - «TÚ» (de color): la postura real del niño, en vivo.
// El niño mueve su figura hasta que calce con la silueta.
//
// Cómo se arma la figura (coherente con lo que miden los sensores):
//  - La cadera queda FIJA (sensor de cadera = referencia).
//  - La espalda baja sube recta desde la cadera.
//  - La espalda alta se inclina hacia un lado según la diferencia
//    lateral cuello − cadera.
//
// Todo el estilo (grosores, proporciones) está en los parámetros de
// abajo, para ajustarlo al diseño definitivo sin tocar la lógica.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES DEL DIBUJO ----------
// Exagera la inclinación en pantalla para que el niño la note mejor.
// 1.0 = ángulo real aproximado. La silueta usa el mismo factor, así
// que calzar con ella sigue significando lo mismo.
const double amplificacionVisual = 1.5;

// ESPEJO: true = la figura se mueve como en un espejo (si el niño se
// inclina a SU izquierda, la figura va hacia la izquierda de la
// pantalla). Es lo más intuitivo con el teléfono frente al niño.
const bool modoEspejo = true;

// Proporciones (relativas al lado menor del área de dibujo).
const double largoEspaldaBaja = 0.20;
const double largoEspaldaAlta = 0.22;
const double radioCabeza = 0.075;
const double anchoHombros = 0.10;
const double largoBrazos = 0.17;
const double grosorTronco = 0.07;
const double grosorExtremidades = 0.045;
const double grosorExtraSilueta = 1.3; // la silueta es algo más gruesa: se ve como contorno
const double opacidadZona = 0.45; // qué tan visible es la cuña de la zona

/// Convierte las "unidades" del sensor (escala 0–180) a grados
/// aproximados: unidades ≈ 90 × seno(ángulo).
double unidadesAGrados(double unidades) =>
    math.asin((unidades / 90).clamp(-1.0, 1.0)) * 180 / math.pi;

class FiguraTu extends StatelessWidget {
  final double adelante; // unidades, relativas a la postura cero
  final double lateral;
  final double siluetaAdelante; // pose objetivo
  final double siluetaLateral;
  final Color color;
  final bool mostrarSilueta;
  final double? margenLateral; // ancho de la zona (unidades); null = sin zona

  const FiguraTu({
    super.key,
    required this.adelante,
    required this.lateral,
    required this.siluetaAdelante,
    required this.siluetaLateral,
    required this.color,
    this.mostrarSilueta = true,
    this.margenLateral,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PintorFigura(
        adelante: adelante,
        lateral: lateral,
        siluetaAdelante: siluetaAdelante,
        siluetaLateral: siluetaLateral,
        color: color,
        mostrarSilueta: mostrarSilueta,
        margenLateral: margenLateral,
      ),
    );
  }
}

class _PintorFigura extends CustomPainter {
  final double adelante, lateral, siluetaAdelante, siluetaLateral;
  final Color color;
  final bool mostrarSilueta;
  final double? margenLateral;

  _PintorFigura({
    required this.adelante,
    required this.lateral,
    required this.siluetaAdelante,
    required this.siluetaLateral,
    required this.color,
    required this.mostrarSilueta,
    required this.margenLateral,
  });

  double get _signo => modoEspejo ? 1.0 : -1.0;

  /// Unidades laterales -> ángulo en radianes, tal como se dibuja.
  double _anguloLateral(double unidades) =>
      _signo * unidadesAGrados(unidades) * amplificacionVisual * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final m = margenLateral;
    if (mostrarSilueta && m != null) _dibujarZona(canvas, size, m);
    if (mostrarSilueta) {
      _dibujarCuerpo(canvas, size, siluetaAdelante, siluetaLateral,
          Colores.silueta, grosorExtraSilueta, false);
    }
    _dibujarCuerpo(canvas, size, adelante, lateral, color, 1.0, true);
  }

  /// Cuña clara alrededor de la espalda alta de la silueta: desde la
  /// pose −margen hasta la pose +margen. Si la cabeza de «Tú» cae
  /// dentro, el juego cuenta ese eje como logrado.
  void _dibujarZona(Canvas canvas, Size size, double margen) {
    final u = math.min(size.width, size.height);
    final cadera = Offset(size.width / 2, size.height * 0.80);
    final medio = cadera.translate(0, -u * largoEspaldaBaja);
    final desde = _anguloLateral(siluetaLateral - margen);
    final hasta = _anguloLateral(siluetaLateral + margen);
    final inicio = math.min(desde, hasta);
    final barrido = (hasta - desde).abs();
    final radio = u * (largoEspaldaAlta + radioCabeza * 2.6);
    // En el lienzo, "hacia arriba" es −90°: por eso se resta pi/2.
    canvas.drawArc(
      Rect.fromCircle(center: medio, radius: radio),
      inicio - math.pi / 2,
      barrido,
      true,
      Paint()..color = Colores.silueta.withValues(alpha: opacidadZona),
    );
  }

  void _dibujarCuerpo(Canvas canvas, Size size, double uAdelante,
      double uLateral, Color c, double grosor, bool conSensores) {
    final u = math.min(size.width, size.height);
    final cadera = Offset(size.width / 2, size.height * 0.80);

    // Inclinación lateral -> ángulo de la espalda alta.
    // (uAdelante no se usa en la vista de frente; se mantiene para la
    // futura vista de costado.)
    final phi = _anguloLateral(uLateral);

    final medio = cadera.translate(0, -u * largoEspaldaBaja);
    final direccion = Offset(math.sin(phi), -math.cos(phi));
    final perpendicular = Offset(math.cos(phi), math.sin(phi));
    final hombros = medio + direccion * (u * largoEspaldaAlta);
    final r = u * radioCabeza;
    final cabeza = hombros + direccion * (r * 1.35);

    final tronco = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = u * grosorTronco * grosor;
    final extremidad = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = u * grosorExtremidades * grosor;

    // Piernas (sentado, de frente: se ven cortas).
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(
        cadera + Offset(s * u * 0.05, 0),
        cadera + Offset(s * u * 0.07, u * 0.15),
        extremidad,
      );
    }

    // Espalda: cadera -> medio -> hombros.
    final espalda = Path()
      ..moveTo(cadera.dx, cadera.dy)
      ..lineTo(medio.dx, medio.dy)
      ..lineTo(hombros.dx, hombros.dy);
    canvas.drawPath(espalda, tronco);

    // Hombros y brazos (los brazos cuelgan; los sensores no los miden).
    for (final s in [-1.0, 1.0]) {
      final hombro = hombros + perpendicular * (s * u * anchoHombros);
      canvas.drawLine(hombros, hombro, extremidad);
      canvas.drawLine(hombro, hombro + Offset(s * u * 0.02, u * largoBrazos), extremidad);
    }

    // Cabeza.
    canvas.drawCircle(cabeza, r * (grosor > 1 ? 1.25 : 1.0), Paint()..color = c);

    // Los dos sensores del cinturón (solo en la figura real).
    if (conSensores) {
      final punto = Paint()..color = Colores.tarjeta;
      canvas.drawCircle(cadera.translate(0, -u * 0.02), u * 0.014, punto);
      canvas.drawCircle(hombros, u * 0.014, punto);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorFigura old) =>
      old.adelante != adelante ||
      old.lateral != lateral ||
      old.siluetaAdelante != siluetaAdelante ||
      old.siluetaLateral != siluetaLateral ||
      old.color != color ||
      old.mostrarSilueta != mostrarSilueta ||
      old.margenLateral != margenLateral;
}
