// ============================================================
// grafico_recorrido.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F4 (solo modo desarrollador)
//
// Gráfico de línea del RECORRIDO de una pose, en su eje principal:
//  - eje horizontal: segundos desde "¡Vamos!";
//  - eje vertical: inclinación (unidades, relativa al cero);
//  - banda verde: la ZONA de la pose (objetivo ± margen);
//  - línea azul: lo que hizo el niño;
//  - líneas ámbar verticales: cuándo apareció la pista.
// Así se ve de un vistazo si partió al lado contrario, si oscilaba en
// el borde o si se pasó de largo.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/registro_juego.dart';
import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
const double altoGraficoRecorrido = 96;

class GraficoRecorrido extends StatelessWidget {
  final MetricaPose pose;
  final bool ejeLateral; // true = lateral; false = adelante
  final List<int> pistasMs; // ms desde "¡Vamos!" en que apareció la pista

  const GraficoRecorrido({
    super.key,
    required this.pose,
    required this.ejeLateral,
    this.pistasMs = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altoGraficoRecorrido,
      width: double.infinity,
      child: CustomPaint(
        painter: _Pintor(
          ms: pose.recorridoMs,
          valores: ejeLateral ? pose.recorridoLateral : pose.recorridoAdelante,
          objetivo: (ejeLateral ? pose.objetivoLateral : pose.objetivoAdelante) ?? 0,
          margen: (ejeLateral ? pose.margenLateral : (pose.margenAdelante ?? pose.margenLateral)) ?? 0,
          pistasMs: pistasMs,
        ),
      ),
    );
  }
}

class _Pintor extends CustomPainter {
  final List<int> ms;
  final List<double> valores;
  final double objetivo;
  final double margen;
  final List<int> pistasMs;

  _Pintor({
    required this.ms,
    required this.valores,
    required this.objetivo,
    required this.margen,
    required this.pistasMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ms.isEmpty) return;
    // Rango vertical: todo lo dibujado debe caber, con un poco de aire.
    var minV = objetivo - margen, maxV = objetivo + margen;
    for (final v in valores) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final aire = (maxV - minV) * 0.1 + 1;
    minV -= aire;
    maxV += aire;
    final tMax = ms.last <= 0 ? 1 : ms.last;
    double x(int t) => t / tMax * size.width;
    double y(double v) => size.height - (v - minV) / (maxV - minV) * size.height;

    // Fondo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = Colores.fondo,
    );

    // Zona de la pose.
    canvas.drawRect(
      Rect.fromLTRB(0, y(objetivo + margen), size.width, y(objetivo - margen)),
      Paint()..color = Colores.comodo.withValues(alpha: 0.22),
    );
    canvas.drawLine(
      Offset(0, y(objetivo)),
      Offset(size.width, y(objetivo)),
      Paint()
        ..color = Colores.comodo
        ..strokeWidth = 1,
    );

    // Pistas.
    final pista = Paint()
      ..color = Colores.ambar
      ..strokeWidth = 2;
    for (final t in pistasMs) {
      if (t < 0 || t > tMax) continue;
      canvas.drawLine(Offset(x(t), 0), Offset(x(t), size.height), pista);
    }

    // Recorrido.
    final camino = Path()..moveTo(x(ms.first), y(valores.first));
    for (var i = 1; i < ms.length; i++) {
      camino.lineTo(x(ms[i]), y(valores[i]));
    }
    canvas.drawPath(
      camino,
      Paint()
        ..color = Colores.azul
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    // Punto de partida.
    canvas.drawCircle(Offset(x(ms.first), y(valores.first)), 3.5, Paint()..color = Colores.azul);
  }

  @override
  bool shouldRepaint(covariant _Pintor old) =>
      old.ms != ms || old.valores != valores || old.objetivo != objetivo || old.margen != margen;
}
