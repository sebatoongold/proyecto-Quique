// ============================================================
// icono_animal.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F9.1b
//
// CAMBIOS v2 respecto a la v1:
//  - `espejar`: dibuja el ícono reflejado (izquierda ↔ derecha). Sirve
//    para que el pingüino se incline hacia el mismo lado que la pose.
//
// Ícono geométrico de cada animal (jirafa, tortuga, armadillo,
// pingüino), dentro de su círculo de color. Mismo dibujo que la
// lámina lamina_tarjetas_postura_v1: círculos, elipses y rectángulos
// redondeados, ojo de punto. Sin emojis ni imágenes: se dibuja con
// código, así se ve igual en todos los teléfonos y a cualquier tamaño.
//
// Uso: IconoAnimal(animal: AnimalPostura.tortuga, tamano: 56)
//
// Cómo está dibujado: en coordenadas de −46 a 46 (el círculo de fondo
// tiene radio 46); se escala al `tamano` pedido. Para retocar un
// animal, se cambian los números de su función (_jirafa, _tortuga…).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelos/animal_postura.dart';
import '../tema/colores.dart';

class IconoAnimal extends StatelessWidget {
  final AnimalPostura animal;
  final double tamano; // diámetro del círculo, en píxeles lógicos
  final bool conFondo; // círculo de color detrás
  final bool espejar; // reflejado izquierda ↔ derecha

  const IconoAnimal(
      {super.key, required this.animal, this.tamano = 56, this.conFondo = true, this.espejar = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: animal.nombre,
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: CustomPaint(painter: _PintorAnimal(animal, conFondo, espejar)),
      ),
    );
  }
}

class _PintorAnimal extends CustomPainter {
  final AnimalPostura animal;
  final bool conFondo;
  final bool espejar;

  _PintorAnimal(this.animal, this.conFondo, this.espejar);

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.shortestSide / 92;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(espejar ? -escala : escala, escala);
    final circulo = Rect.fromCircle(center: Offset.zero, radius: 46);
    if (conFondo) canvas.drawOval(circulo, Paint()..color = animal.fondo);
    // Lo que sale del círculo se recorta (p. ej. el cuello de la jirafa).
    canvas.clipPath(Path()..addOval(circulo));
    switch (animal) {
      case AnimalPostura.jirafa:
        _jirafa(canvas);
      case AnimalPostura.tortuga:
        _tortuga(canvas);
      case AnimalPostura.armadillo:
        _armadillo(canvas);
      case AnimalPostura.pinguino:
        _pinguino(canvas);
    }
    canvas.restore();
  }

  // ---------- Ayudas de dibujo ----------
  static Paint _relleno(Color c) => Paint()..color = c;

  static Paint _trazo(Color c, double ancho) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = ancho
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static void _circulo(Canvas c, double x, double y, double r, Color color) =>
      c.drawCircle(Offset(x, y), r, _relleno(color));

  /// Elipse girada `grados` alrededor de su centro.
  static void _elipse(Canvas c, double x, double y, double rx, double ry, double grados, Color color) {
    c.save();
    c.translate(x, y);
    c.rotate(grados * math.pi / 180);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), _relleno(color));
    c.restore();
  }

  static void _rect(Canvas c, double x, double y, double w, double h, double r, Color color) =>
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), _relleno(color));

  static Path _poligono(List<Offset> puntos) => Path()..addPolygon(puntos, true);

  // ---------- Jirafa (de perfil, mirando a la derecha) ----------
  static const _jirafaCuerpo = Color(0xFFE3A73B);
  static const _jirafaMancha = Color(0xFFC2862A);

  void _jirafa(Canvas c) {
    c.drawPath(_poligono(const [Offset(-20, 46), Offset(-9, -12), Offset(5, -12), Offset(3, 46)]),
        _relleno(_jirafaCuerpo)); // cuello
    _rect(c, -14, -30, 38, 20, 10, _jirafaCuerpo); // cabeza
    final cacho = _trazo(_jirafaMancha, 3.5);
    c.drawLine(const Offset(-7, -29), const Offset(-9, -39), cacho); // cachitos
    c.drawLine(const Offset(2, -29), const Offset(2, -40), cacho);
    _circulo(c, -9, -40, 3.4, _jirafaMancha);
    _circulo(c, 2, -41, 3.4, _jirafaMancha);
    _elipse(c, -15, -25, 6, 3, -25, _jirafaMancha); // oreja
    _circulo(c, -7, 2, 4.2, _jirafaMancha); // manchas
    _circulo(c, -3, 20, 5, _jirafaMancha);
    _circulo(c, -12, 34, 4, _jirafaMancha);
    _circulo(c, -1, -6, 2.8, _jirafaMancha);
    _circulo(c, 5, -22, 2.8, Colores.azul); // ojo
    _circulo(c, 20, -16, 1.6, _jirafaMancha); // nariz
  }

  // ---------- Tortuga (tranquila, ojo medio cerrado) ----------
  static const _tortugaCapa = Color(0xFFA9B85E);
  static const _tortugaBorde = Color(0xFF7D8C3C);
  static const _tortugaPiel = Color(0xFFC7CF93);

  void _tortuga(Canvas c) {
    c.drawPath(_poligono(const [Offset(-36, 14), Offset(-42, 18), Offset(-34, 18)]), _relleno(_tortugaPiel)); // cola
    _rect(c, -28, 12, 10, 14, 5, _tortugaPiel); // patas
    _rect(c, 8, 12, 10, 14, 5, _tortugaPiel);
    c.drawPath(_poligono(const [Offset(18, 6), Offset(26, -2), Offset(32, 4), Offset(24, 12)]),
        _relleno(_tortugaPiel)); // cuello
    _circulo(c, 31, -4, 10, _tortugaPiel); // cabeza
    // Caparazón: media luna sobre el borde.
    c.drawPath(
      Path()
        ..addArc(Rect.fromCircle(center: const Offset(-6, 12), radius: 28), math.pi, math.pi)
        ..close(),
      _relleno(_tortugaCapa),
    );
    c.drawArc(Rect.fromCircle(center: const Offset(-6, 12), radius: 14), math.pi, math.pi, false,
        _trazo(_tortugaBorde, 3));
    final linea = _trazo(_tortugaBorde, 3);
    c.drawLine(const Offset(-6, -2), const Offset(-6, -15), linea);
    c.drawLine(const Offset(-18, 5), const Offset(-27, -4), linea);
    c.drawLine(const Offset(6, 5), const Offset(14, -4), linea);
    _rect(c, -38, 9, 64, 7, 3.5, _tortugaBorde); // borde del caparazón
    // Ojo medio cerrado y ceja: la tortuga sabia.
    c.drawPath(
      Path()
        ..moveTo(30, -6)
        ..quadraticBezierTo(33.5, -3.5, 37, -6),
      _trazo(Colores.azul, 2.4),
    );
    c.drawLine(const Offset(29, -11), const Offset(37, -10), _trazo(_tortugaBorde, 2));
  }

  // ---------- Armadillo (ya enrollado: la bolita) ----------
  static const _armadilloCuerpo = Color(0xFFB5A385);
  static const _armadilloBanda = Color(0xFF8C7A5C);
  static const _armadilloPiel = Color(0xFFD9CDB7);

  void _armadillo(Canvas c) {
    c.drawPath(
      Path()
        ..moveTo(-28, 22)
        ..quadraticBezierTo(-40, 26, -36, 14),
      _trazo(_armadilloBanda, 5),
    ); // cola
    _circulo(c, 0, 2, 30, _armadilloCuerpo); // bolita
    final banda = _trazo(_armadilloBanda, 3.5);
    for (final (x, arriba, abajo) in const [(-14.0, -25.0, 29.0), (0.0, -28.0, 32.0), (14.0, -25.0, 29.0)]) {
      c.drawPath(
        Path()
          ..moveTo(x, arriba)
          ..quadraticBezierTo(x + 10, 2, x, abajo),
        banda,
      );
    }
    final hocico = _poligono(const [Offset(16, 10), Offset(36, 20), Offset(18, 26)]);
    c.drawPath(hocico, _relleno(_armadilloPiel));
    c.drawPath(hocico, _trazo(_armadilloPiel, 4));
    _elipse(c, 17, 4, 4, 7, -20, _armadilloPiel); // oreja
    _circulo(c, 23, 16, 2.4, Colores.azul); // ojo
  }

  // ---------- Pingüino (inclinado hacia un lado) ----------
  static const _pinguinoCuerpo = Color(0xFF243851);
  static const _pinguinoPanza = Color(0xFFFBF9F5);
  static const _pinguinoPico = Color(0xFFE3A73B);

  void _pinguino(Canvas c) {
    c.save();
    c.rotate(-14 * math.pi / 180);
    _elipse(c, -11, 37, 8, 4, 0, _pinguinoPico); // patas
    _elipse(c, 9, 37, 8, 4, 0, _pinguinoPico);
    _elipse(c, -22, 10, 6, 16, 18, _pinguinoCuerpo); // aletas
    _elipse(c, 22, 10, 6, 16, -18, _pinguinoCuerpo);
    _elipse(c, 0, 4, 21, 33, 0, _pinguinoCuerpo); // cuerpo
    _elipse(c, 0, 12, 14, 23, 0, _pinguinoPanza); // panza
    _circulo(c, -7, -15, 4, _pinguinoPanza); // ojos
    _circulo(c, 7, -15, 4, _pinguinoPanza);
    _circulo(c, -6, -15, 2, _pinguinoCuerpo);
    _circulo(c, 8, -15, 2, _pinguinoCuerpo);
    final pico = _poligono(const [Offset(-4, -9), Offset(4, -9), Offset(0, -3)]);
    c.drawPath(pico, _relleno(_pinguinoPico));
    c.drawPath(pico, _trazo(_pinguinoPico, 2));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _PintorAnimal old) =>
      old.animal != animal || old.conFondo != conFondo || old.espejar != espejar;
}
