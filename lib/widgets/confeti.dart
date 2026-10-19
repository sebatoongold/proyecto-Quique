// ============================================================
// confeti.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F8 (celebración más viva)
//
// Estallido de confeti (papelitos y estrellas) dibujado por la app, sin
// librerías nuevas. No tiene reloj propio: la pantalla le pasa
// `tiempo` (segundos desde que empezó) en cada cuadro, igual que al
// resto del juego. Con la misma `semilla`, el estallido sale igual.
//
// Los papelitos salen desde `origen` (fracción del área: 0,5 / 0,5 =
// centro), hacia arriba en abanico, y caen con gravedad. Se desvanecen
// al final de `duracion`.
//
// Uso: dentro de un Stack, en un Positioned.fill con IgnorePointer
// (no debe tapar los toques).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES DEL CONFETI ----------
// Colores de los papelitos (los de Quique y del río).
const List<Color> coloresConfeti = [
  Colores.ambar,
  Colores.comodo,
  Colores.rio,
  Colores.quiqueClaro,
  Colores.colina,
  Colores.rioClaro,
];
// Abanico de salida (radianes a cada lado de "hacia arriba").
const double aperturaConfeti = 0.9;
// Velocidad de salida, en "altos del área" por segundo (mín. y máx.).
const double velocidadMinConfeti = 0.7;
const double velocidadMaxConfeti = 1.3;
// Gravedad, en "altos del área" por segundo².
const double gravedadConfeti = 1.6;
// Tamaño de cada papelito, en píxeles lógicos (mín. y máx.).
const double tamanoMinConfeti = 7;
const double tamanoMaxConfeti = 13;
// Parte de cada papelito que es estrella (el resto, rectángulos).
const double fraccionEstrellas = 0.3;
// Fracción final de la duración en que el confeti se desvanece.
const double fraccionDesvanecer = 0.3;

class _Papelito {
  final double angulo, velocidad, giro, tamano, retraso;
  final Color color;
  final bool estrella;
  const _Papelito(this.angulo, this.velocidad, this.giro, this.tamano, this.retraso, this.color,
      this.estrella);
}

class Confeti extends StatelessWidget {
  final double tiempo; // segundos desde que empezó el estallido
  final double duracion; // segundos hasta que desaparece
  final int cantidad;
  final Offset origen; // fracción del área (0..1, 0..1)
  final int semilla;
  // Segundos en que van saliendo los papelitos (0 = todos de golpe).
  final double salidaEscalonada;

  const Confeti({
    super.key,
    required this.tiempo,
    this.duracion = 2.5,
    this.cantidad = 40,
    this.origen = const Offset(0.5, 0.55),
    this.semilla = 1,
    this.salidaEscalonada = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (tiempo < 0 || tiempo > duracion) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _PintorConfeti(this),
    );
  }
}

class _PintorConfeti extends CustomPainter {
  final Confeti c;
  late final List<_Papelito> _papelitos;

  _PintorConfeti(this.c) {
    final r = math.Random(c.semilla);
    _papelitos = List.generate(c.cantidad, (_) {
      return _Papelito(
        (r.nextDouble() * 2 - 1) * aperturaConfeti,
        velocidadMinConfeti + r.nextDouble() * (velocidadMaxConfeti - velocidadMinConfeti),
        (r.nextDouble() * 2 - 1) * 8, // giro (radianes por segundo)
        tamanoMinConfeti + r.nextDouble() * (tamanoMaxConfeti - tamanoMinConfeti),
        r.nextDouble() * c.salidaEscalonada,
        coloresConfeti[r.nextInt(coloresConfeti.length)],
        r.nextDouble() < fraccionEstrellas,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final alto = size.height;
    final o = Offset(c.origen.dx * size.width, c.origen.dy * alto);
    // Desvanecer al final.
    final inicioDesvanecer = c.duracion * (1 - fraccionDesvanecer);
    final opacidad = c.tiempo <= inicioDesvanecer
        ? 1.0
        : (1 - (c.tiempo - inicioDesvanecer) / (c.duracion * fraccionDesvanecer)).clamp(0.0, 1.0).toDouble();

    for (final p in _papelitos) {
      final t = c.tiempo - p.retraso;
      if (t < 0) continue;
      final v = p.velocidad * alto;
      final vx = math.sin(p.angulo) * v;
      final vy = -math.cos(p.angulo) * v;
      final pos = o + Offset(vx * t, vy * t + 0.5 * gravedadConfeti * alto * t * t);
      if (pos.dy > alto + 20) continue;
      final pincel = Paint()..color = p.color.withValues(alpha: opacidad);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.giro * t);
      if (p.estrella) {
        canvas.drawPath(_estrella(p.tamano * 0.75), pincel);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.tamano, height: p.tamano * 0.55),
            const Radius.circular(2),
          ),
          pincel,
        );
      }
      canvas.restore();
    }
  }

  /// Estrella de 5 puntas centrada en (0, 0).
  static Path _estrella(double radio) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radio : radio * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final punto = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _PintorConfeti old) =>
      old.c.tiempo != c.tiempo || old.c.semilla != c.semilla || old.c.cantidad != c.cantidad;
}
