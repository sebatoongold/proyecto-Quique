// ============================================================
// barra_mundos.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v6 — paso G5
//
// CAMBIOS v6 respecto a la v5:
//  - Vuelve la BARRA INFERIOR CLÁSICA, de lado a lado, en vez de las dos
//    esquinas (las esquinas tapaban contenido). Es más baja que los
//    botones principales de las pantallas (`altoBarraMundos`) y va sobre
//    Crema banda, con una línea arriba que la separa del fondo.
//  - Cada mundo es una PÍLDORA: la del mundo activo va rellena de su
//    color (niño = Bosque, apoderado = Azul noche); la otra, sin relleno.
//  - El RELOJ de la puerta parental se conserva: ahora es el CONTORNO de
//    la píldora del apoderado, que se va trazando desde arriba al centro,
//    en el sentido del reloj, durante los 3 segundos.
//  - Se conserva el seguimiento del dedo (G4): el reloj sigue mientras el
//    dedo esté DENTRO de la mitad del apoderado; se detiene al levantarlo
//    o al salir.
//  - Ya no existe `espacioBajoEsquinas`: la barra va debajo de las
//    pantallas (no encima), así que no tapa nada.
//
// De apoderado a niño es un toque; un toque corto en la píldora del
// apoderado muestra una pista para el adulto; cada intento se anota en el
// registro de uso (corto / soltada / ok).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../servicios/registro_uso.dart';
import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cuánto hay que mantener presionado para entrar al mundo apoderado.
// Más largo = más difícil para un niño entrar sin querer.
const Duration duracionPuertaParental = Duration(seconds: 3);
// Alto de la barra (sin contar la barra de gestos del teléfono). Debe
// quedar MÁS BAJA que los botones principales (92–104 en el inicio niño).
const double altoBarraMundos = 66;
// Margen entre el borde de cada mitad y su píldora.
const double margenPildora = 8;
// Grosor del contorno que se traza como reloj en la puerta parental.
const double grosorReloj = 4;
// Debajo de este avance (0..1), soltar cuenta como "toque corto".
const double umbralToqueCorto = 0.15;

enum Mundo { nino, apoderado }

class BarraMundos extends StatefulWidget {
  final Mundo actual;
  final ValueChanged<Mundo> alCambiar;

  const BarraMundos({super.key, required this.actual, required this.alCambiar});

  @override
  State<BarraMundos> createState() => _BarraMundosState();
}

class _BarraMundosState extends State<BarraMundos> with SingleTickerProviderStateMixin {
  late final AnimationController _puerta = AnimationController(
    vsync: this,
    duration: duracionPuertaParental,
  )..addStatusListener((estado) {
      if (estado == AnimationStatus.completed) {
        _presionando = false;
        RegistroUso.anotar('puerta_intento', dato: 'ok');
        _puerta.reset();
        widget.alCambiar(Mundo.apoderado);
      }
    });

  @override
  void dispose() {
    _puerta.dispose();
    super.dispose();
  }

  bool _presionando = false; // hay un dedo sobre la puerta

  void _levantar() {
    if (!_presionando) return;
    _presionando = false;
    _soltar();
  }

  void _soltar() {
    if (_puerta.isCompleted) return;
    final corto = _puerta.value < umbralToqueCorto;
    RegistroUso.anotar('puerta_intento', dato: corto ? 'corto' : 'soltada');
    // Toque corto: probablemente alguien no sabe que hay que mantener.
    if (corto) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Para el apoderado: mantén presionado «Apoderado» '
              '${duracionPuertaParental.inSeconds} segundos.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }
    _puerta.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enNino = widget.actual == Mundo.nino;
    // Respeta la barra de gestos del teléfono.
    final abajo = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colores.cremaBanda,
        border: Border(top: BorderSide(color: Colores.arenaPaleta, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: abajo),
      child: SizedBox(
        height: altoBarraMundos,
        child: Row(
          children: [
            Expanded(
              child: _mitad(
                icono: Icons.child_care_rounded,
                texto: 'Niño',
                activa: enNino,
                color: Colores.bosque,
                alTocar: enNino ? null : () => widget.alCambiar(Mundo.nino),
              ),
            ),
            Expanded(
              child: enNino
                  ? _puertaParental()
                  : _mitad(
                      icono: Icons.person_rounded,
                      texto: 'Apoderado',
                      activa: true,
                      color: Colores.azul,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Una mitad normal (sin puerta).
  Widget _mitad({
    required IconData icono,
    required String texto,
    required bool activa,
    required Color color,
    VoidCallback? alTocar,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(margenPildora),
        child: CustomPaint(
          painter: _PintorPildora(fondo: activa ? color : null),
          child: _contenido(
            icono: icono,
            texto: texto,
            color: activa ? Colores.cremaBanda : Colores.textoSecundario,
            negrita: activa,
          ),
        ),
      ),
    );
  }

  /// Mitad del apoderado vista desde el mundo niño: hay que mantenerla
  /// presionada; su contorno se traza como un reloj.
  Widget _puertaParental() {
    return LayoutBuilder(
      builder: (context, caja) {
        final ancho = caja.maxWidth;
        final alto = caja.maxHeight;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            _presionando = true;
            _puerta.forward();
          },
          // Mientras el dedo siga dentro de esta mitad, el reloj sigue.
          onPointerMove: (e) {
            if (!_presionando) return;
            final p = e.localPosition;
            final dentro = p.dx >= 0 && p.dy >= 0 && p.dx <= ancho && p.dy <= alto;
            if (!dentro) _levantar();
          },
          onPointerUp: (_) => _levantar(),
          onPointerCancel: (_) => _levantar(),
          child: Padding(
            padding: const EdgeInsets.all(margenPildora),
            child: AnimatedBuilder(
              animation: _puerta,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PintorPildora(
                    avance: _puerta.value,
                    colorAvance: Colores.azul,
                    mostrarPista: true,
                  ),
                  child: _contenido(
                    icono: Icons.lock_rounded,
                    texto: 'Apoderado',
                    color: Colores.textoSecundario,
                    negrita: false,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Ícono y etiqueta en una fila, centrados.
  Widget _contenido({
    required IconData icono,
    required String texto,
    required Color color,
    required bool negrita,
  }) {
    return Center(
      // Si el texto del teléfono es grande, se achica en vez de cortarse.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: negrita ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja una píldora (rectángulo de puntas redondas) y, si hay `avance`,
/// el reloj en su contorno: parte arriba al centro y avanza en el sentido
/// del reloj.
class _PintorPildora extends CustomPainter {
  final Color? fondo; // null = sin relleno
  final double avance; // 0..1
  final Color colorAvance;
  final bool mostrarPista; // contorno tenue con el recorrido del reloj

  _PintorPildora({
    this.fondo,
    this.avance = 0,
    this.colorAvance = Colores.azul,
    this.mostrarPista = false,
  });

  /// Contorno de la píldora empezando arriba al centro, en sentido horario.
  static Path _contorno(Rect r) {
    final radio = r.height / 2;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right - radio, r.top)
      ..arcTo(Rect.fromCircle(center: Offset(r.right - radio, r.center.dy), radius: radio), -math.pi / 2, math.pi, false)
      ..lineTo(r.left + radio, r.bottom)
      ..arcTo(Rect.fromCircle(center: Offset(r.left + radio, r.center.dy), radius: radio), math.pi / 2, math.pi, false)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(grosorReloj / 2);
    final contorno = _contorno(rect);

    if (fondo != null) canvas.drawPath(contorno, Paint()..color = fondo!);

    if (avance > 0 || mostrarPista) {
      final trazo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosorReloj
        ..strokeCap = StrokeCap.round;
      if (mostrarPista) {
        canvas.drawPath(contorno, trazo..color = colorAvance.withValues(alpha: 0.18));
      }
      final a = avance.clamp(0.0, 1.0).toDouble();
      if (a > 0) {
        for (final m in contorno.computeMetrics()) {
          canvas.drawPath(m.extractPath(0, m.length * a), trazo..color = colorAvance);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorPildora old) =>
      old.avance != avance || old.fondo != fondo || old.mostrarPista != mostrarPista;
}
