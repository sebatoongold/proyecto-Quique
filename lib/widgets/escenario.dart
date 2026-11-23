// ============================================================
// escenario.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v2 — paso G5
//
// CAMBIOS v2 respecto a la v1:
//  - El ocre del desierto y el mar toman los colores de PAISAJE de la
//    paleta ajustada (Colores.ocre, Colores.agua). Los demás tonos del
//    paisaje vienen de colores.dart, que ya apunta a la paleta nueva.
//
// El PAISAJE de cada lugar del viaje, dibujado con figuras geométricas
// planas (cielo, cerros, estrellas, mar…), con Sóma y, si corresponde,
// el animal del capítulo. Se usa en el inicio del niño y en las
// viñetas de la historia.
//
// Es PROVISORIO: cuando existan ilustraciones propias de cada lugar, se
// reemplaza `_PintorPaisaje` por una imagen, sin tocar las pantallas.
//
// Sóma es la imagen `assets/soma.png` (declarada en pubspec.yaml).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelos/animal_postura.dart';
import '../modelos/historia.dart';
import '../tema/colores.dart';
import 'icono_animal.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Alto de Sóma respecto del alto del escenario.
const double altoSomaEnEscenario = 0.50;
// Tamaño del animal (su ícono) respecto del alto del escenario.
const double tamanoAnimalEnEscenario = 0.34;
// Cuánto se inclina Sóma cuando "intenta" una postura y se tambalea.
const double inclinacionSomaTambalea = 0.18; // radianes

class Escenario extends StatelessWidget {
  final Lugar lugar;
  final AnimalPostura? animal; // el animal aparece a la derecha
  final bool mostrarSoma;
  final bool somaTambalea; // en "¡Ayúdame!": Sóma intenta y se tambalea
  final bool apagado; // capítulo bloqueado: todo más tenue

  const Escenario({
    super.key,
    required this.lugar,
    this.animal,
    this.mostrarSoma = true,
    this.somaTambalea = false,
    this.apagado = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final alto = c.maxHeight;
      return Opacity(
        opacity: apagado ? 0.45 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _PintorPaisaje(lugar)),
            if (mostrarSoma)
              Align(
                alignment: Alignment(animal == null ? 0 : -0.45, 0.92),
                child: Transform.rotate(
                  angle: somaTambalea ? -inclinacionSomaTambalea : 0,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/soma.png',
                    height: alto * altoSomaEnEscenario,
                    fit: BoxFit.contain,
                    // Si falta el archivo, un marcador en vez de un error rojo.
                    errorBuilder: (context, error, stack) => CircleAvatar(
                      radius: alto * 0.12,
                      backgroundColor: Colores.quique,
                      child: const Icon(Icons.pets_rounded, color: Colores.quiqueClaro),
                    ),
                  ),
                ),
              ),
            if (animal != null)
              Align(
                alignment: const Alignment(0.55, 0.85),
                child: IconoAnimal(animal: animal!, tamano: alto * tamanoAnimalEnEscenario),
              ),
          ],
        ),
      );
    });
  }
}

/// Dibuja el paisaje de cada lugar con formas planas.
class _PintorPaisaje extends CustomPainter {
  final Lugar lugar;
  _PintorPaisaje(this.lugar);

  // Colores de los paisajes (además de los de la app).
  static const _noche = Color(0xFF2B3A55);
  static const _nocheProfunda = Color(0xFF1E2A40);
  static const _ocre = Colores.ocre; // G5: de la paleta (paisaje)
  static const _ocreOscuro = Color(0xFFA8844F);
  static const _roca = Color(0xFF8C8F94);
  static const _nieve = Color(0xFFF3F1EC);
  static const _mar = Colores.agua; // G5: de la paleta (paisaje)
  static const _lago = Color(0xFF7FB0D0);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Paint p(Color c) => Paint()..color = c;

    Path cerro(List<Offset> puntos) {
      final path = Path()..moveTo(0, h);
      for (final o in puntos) {
        path.lineTo(o.dx * w, o.dy * h);
      }
      return path
        ..lineTo(w, h)
        ..close();
    }

    void estrellas(int n, double hastaY) {
      final r = math.Random(7); // siempre las mismas estrellas
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h * hastaY),
            0.8 + r.nextDouble() * 1.6, p(Colores.tarjeta.withValues(alpha: 0.5 + r.nextDouble() * 0.5)));
      }
    }

    switch (lugar) {
      case Lugar.madriguera:
        canvas.drawRect(Offset.zero & s, p(Colores.cielo));
        canvas.drawCircle(Offset(w * 0.82, h * 0.2), h * 0.08, p(Colores.ambar.withValues(alpha: 0.85)));
        canvas.drawPath(cerro([Offset(0, .68), Offset(.25, .55), Offset(.5, .66), Offset(.78, .52), Offset(1, .62)]),
            p(Colores.colina));
        canvas.drawPath(cerro([Offset(0, .8), Offset(.35, .72), Offset(.7, .8), Offset(1, .74)]), p(Colores.bosqueClaro));
        // Árboles.
        for (final (x, y, e) in [(.1, .74, 1.0), (.88, .70, .8), (.2, .82, .7)]) {
          final cx = x * w, base = y * h, t = h * 0.12 * e;
          canvas.drawRect(Rect.fromLTWH(cx - t * .08, base - t * .1, t * .16, t * .4), p(Colores.bosque));
          canvas.drawPath(
              Path()
                ..moveTo(cx - t * .45, base)
                ..lineTo(cx, base - t)
                ..lineTo(cx + t * .45, base)
                ..close(),
              p(Colores.bosque));
        }
        // La madriguera: un arco oscuro en el cerro.
        canvas.drawArc(Rect.fromCenter(center: Offset(w * .78, h * .86), width: w * .2, height: h * .2), math.pi, math.pi,
            true, p(Colores.quique));
      case Lugar.altiplano:
        canvas.drawRect(Offset.zero & s, p(_noche));
        estrellas(40, 0.55);
        canvas.drawCircle(Offset(w * 0.2, h * 0.18), h * 0.06, p(_nieve));
        canvas.drawPath(cerro([Offset(0, .62), Offset(.3, .38), Offset(.55, .6), Offset(.8, .34), Offset(1, .55)]),
            p(_ocreOscuro));
        // Nieve en las cumbres.
        for (final (x, y) in [(.3, .38), (.8, .34)]) {
          canvas.drawPath(
              Path()
                ..moveTo((x - .06) * w, (y + .08) * h)
                ..lineTo(x * w, y * h)
                ..lineTo((x + .06) * w, (y + .08) * h)
                ..close(),
              p(_nieve));
        }
        canvas.drawPath(cerro([Offset(0, .8), Offset(.5, .74), Offset(1, .8)]), p(_ocre));
      case Lugar.desierto:
        canvas.drawRect(Offset.zero & s, p(_nocheProfunda));
        estrellas(90, 0.7);
        canvas.drawPath(cerro([Offset(0, .72), Offset(.4, .62), Offset(.7, .7), Offset(1, .64)]), p(_ocreOscuro));
        canvas.drawPath(cerro([Offset(0, .84), Offset(.3, .78), Offset(.65, .86), Offset(1, .8)]), p(_ocre));
      case Lugar.costa:
        canvas.drawRect(Offset.zero & s, p(Colores.cielo));
        canvas.drawCircle(Offset(w * 0.8, h * 0.2), h * 0.07, p(Colores.ambar.withValues(alpha: 0.85)));
        canvas.drawRect(Rect.fromLTWH(0, h * .5, w, h * .5), p(_mar));
        for (var i = 0; i < 4; i++) {
          final y = h * (.56 + i * .06);
          canvas.drawLine(Offset(w * (.1 + i * .15), y), Offset(w * (.22 + i * .15), y),
              Paint()
                ..color = Colores.tarjeta.withValues(alpha: .6)
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round);
        }
        canvas.drawPath(cerro([Offset(0, .78), Offset(.2, .7), Offset(.45, .76), Offset(.75, .7), Offset(1, .78)]),
            p(_roca));
      case Lugar.lagos:
        canvas.drawRect(Offset.zero & s, p(Colores.cielo));
        // Volcán con nieve.
        canvas.drawPath(
            Path()
              ..moveTo(w * .35, h * .62)
              ..lineTo(w * .6, h * .25)
              ..lineTo(w * .85, h * .62)
              ..close(),
            p(Colores.neutro));
        canvas.drawPath(
            Path()
              ..moveTo(w * .53, h * .35)
              ..lineTo(w * .6, h * .25)
              ..lineTo(w * .67, h * .35)
              ..close(),
            p(_nieve));
        canvas.drawPath(cerro([Offset(0, .6), Offset(.3, .55), Offset(1, .62)]), p(Colores.colina));
        canvas.drawOval(Rect.fromLTWH(w * .1, h * .62, w * .8, h * .16), p(_lago));
        canvas.drawPath(cerro([Offset(0, .84), Offset(.5, .8), Offset(1, .86)]), p(Colores.bosqueClaro));
      case Lugar.patagonia:
        canvas.drawRect(Offset.zero & s, p(const Color(0xFFDDE5EC)));
        canvas.drawPath(cerro([Offset(0, .6), Offset(.2, .3), Offset(.35, .55), Offset(.5, .25), Offset(.7, .58),
              Offset(.85, .35), Offset(1, .55)]), p(Colores.neutro));
        canvas.drawPath(cerro([Offset(0, .8), Offset(.5, .75), Offset(1, .8)]), p(Colores.colina));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorPaisaje old) => old.lugar != lugar;
}
