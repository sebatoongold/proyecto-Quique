// ============================================================
// barra_mundos.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v5 — paso G4
//
// CAMBIOS v5 respecto a la v4:
//  - PUERTA PARENTAL: si el dedo se mueve un poco, el reloj ya no se
//    detiene. Antes se usaba un "toque" (que se cancela al mover el
//    dedo); ahora se sigue al dedo directamente (Listener): el tiempo
//    sigue sumando mientras el dedo esté DENTRO del cuarto de círculo, y
//    solo se detiene al levantarlo o al salir de la esquina.
//
// La barra de mundos son DOS ESQUINAS (cuartos de círculo) encima de
// las pantallas: a la izquierda el mundo niño y a la derecha el mundo
// apoderado; la del mundo activo va rellena de su color. Las pantallas
// dejan `espacioBajoEsquinas` libre abajo.
// De apoderado a niño es un toque; un toque corto
// en la esquina del apoderado muestra una pista para el adulto; cada
// intento se anota en el registro de uso (corto / soltada / ok).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../servicios/registro_uso.dart';
import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cuánto hay que mantener presionado para entrar al mundo apoderado.
// Más largo = más difícil para un niño entrar sin querer.
const Duration duracionPuertaParental = Duration(seconds: 3);
// Radio de cada esquina (cuarto de círculo), en puntos. Más grande =
// más fácil de tocar y el relleno se ve más alrededor del dedo.
const double radioEsquinaMundos = 116;
// Espacio que las pantallas deben dejar libre abajo para que las
// esquinas no tapen su contenido.
const double espacioBajoEsquinas = radioEsquinaMundos - 20;
// Grosor del arco que se llena como reloj en la puerta parental.
const double grosorReloj = 9;
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

  bool _presionando = false; // G4: hay un dedo sobre la puerta

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
              'Para el apoderado: mantén presionada la esquina '
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
    // Respeta la barra de gestos del teléfono: la esquina crece hacia abajo.
    final abajo = MediaQuery.of(context).padding.bottom;

    // Stack sin hijos normales: solo ocupa (y recibe toques en) las esquinas;
    // el resto de la pantalla sigue tocándose como siempre.
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: _esquina(
            izquierda: true,
            abajo: abajo,
            icono: Icons.child_care_rounded,
            texto: 'Niño',
            activa: enNino,
            color: Colores.bosque,
            alTocar: enNino ? null : () => widget.alCambiar(Mundo.nino),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: enNino
              ? _puertaParental(abajo)
              : _esquina(
                  izquierda: false,
                  abajo: abajo,
                  icono: Icons.person_rounded,
                  texto: 'Apoderado',
                  activa: true,
                  color: Colores.azul,
                ),
        ),
      ],
    );
  }

  /// Una esquina normal (sin puerta).
  Widget _esquina({
    required bool izquierda,
    required double abajo,
    required IconData icono,
    required String texto,
    required bool activa,
    required Color color,
    VoidCallback? alTocar,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: CustomPaint(
        painter: _PintorEsquina(
          izquierda: izquierda,
          fondo: activa ? color : Colores.tarjeta,
          borde: activa ? null : Colores.linea,
        ),
        child: _contenido(
          izquierda: izquierda,
          abajo: abajo,
          icono: icono,
          texto: texto,
          color: activa ? Colores.tarjeta : Colores.textoSecundario,
          negrita: activa,
        ),
      ),
    );
  }

  /// Esquina del apoderado vista desde el mundo niño: hay que mantenerla
  /// presionada; se llena como un reloj.
  Widget _puertaParental(double abajo) {
    final lado = radioEsquinaMundos + abajo; // la esquina es un cuadrado de este lado
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _presionando = true;
        _puerta.forward();
      },
      // Mientras el dedo siga dentro del cuarto de círculo, el reloj sigue.
      onPointerMove: (e) {
        if (!_presionando) return;
        final dx = lado - e.localPosition.dx; // distancia a la esquina de abajo a la derecha
        final dy = lado - e.localPosition.dy;
        final dentro = dx >= 0 && dy >= 0 && dx * dx + dy * dy <= lado * lado;
        if (!dentro) _levantar();
      },
      onPointerUp: (_) => _levantar(),
      onPointerCancel: (_) => _levantar(),
      child: AnimatedBuilder(
        animation: _puerta,
        builder: (context, _) {
          return CustomPaint(
            painter: _PintorEsquina(
              izquierda: false,
              fondo: Colores.tarjeta,
              borde: Colores.linea,
              avance: _puerta.value,
              colorAvance: Colores.azul,
              mostrarPista: true,
            ),
            child: _contenido(
              izquierda: false,
              abajo: abajo,
              icono: Icons.lock_rounded,
              texto: 'Apoderado',
              color: Colores.textoSecundario,
              negrita: false,
            ),
          );
        },
      ),
    );
  }

  /// Ícono y etiqueta, cerca del centro del cuarto de círculo.
  Widget _contenido({
    required bool izquierda,
    required double abajo,
    required IconData icono,
    required String texto,
    required Color color,
    required bool negrita,
  }) {
    return SizedBox(
      // Cuadrado: el cuarto de círculo crece con la barra de gestos.
      width: radioEsquinaMundos + abajo,
      height: radioEsquinaMundos + abajo,
      child: Padding(
        padding: EdgeInsets.only(
          left: izquierda ? 18 : 40,
          right: izquierda ? 40 : 18,
          top: 40,
          bottom: abajo + 14,
        ),
        child: Align(
          alignment: izquierda ? Alignment.bottomLeft : Alignment.bottomRight,
          // Si el texto del teléfono es grande, se achica en vez de cortarse.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: izquierda ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: izquierda ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: negrita ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja un cuarto de círculo con centro en la esquina de abajo
/// (izquierda o derecha) y, si hay `avance`, el reloj en el contorno:
/// un arco grueso sobre el borde curvo, desde abajo hasta el lado.
class _PintorEsquina extends CustomPainter {
  final bool izquierda;
  final Color fondo;
  final Color? borde;
  final double avance; // 0..1
  final Color colorAvance;
  final bool mostrarPista; // arco tenue con el recorrido del reloj

  _PintorEsquina({
    required this.izquierda,
    required this.fondo,
    this.borde,
    this.avance = 0,
    this.colorAvance = Colores.azul,
    this.mostrarPista = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Centro del círculo: la esquina de abajo. El radio cubre el alto
    // completo (incluida la barra de gestos del teléfono).
    final centro = Offset(izquierda ? 0 : size.width, size.height);
    final radio = size.height;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    // Ángulos de Flutter: 0 = derecha, −π/2 = arriba, π = izquierda.
    // Esquina izquierda: de −π/2 (arriba) a 0 (derecha).
    // Esquina derecha:   de π (izquierda) a 3π/2 (arriba).
    final inicio = izquierda ? -math.pi / 2 : math.pi;
    const barrido = math.pi / 2;

    final cuarto = Path()
      ..moveTo(centro.dx, centro.dy)
      ..arcTo(rect, inicio, barrido, false)
      ..close();
    canvas.drawShadow(cuarto, Colors.black, 3, false);
    canvas.drawPath(cuarto, Paint()..color = fondo);
    if (borde != null) {
      canvas.drawArc(
        rect.deflate(0.75),
        inicio,
        barrido,
        false,
        Paint()
          ..color = borde!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Reloj en el CONTORNO (solo la esquina derecha lo usa): un arco
    // grueso sobre el borde curvo que avanza desde abajo (horizontal,
    // hacia la izquierda) hasta el lado (vertical), como las agujas del
    // reloj. Debajo, el mismo arco tenue: el recorrido que falta.
    if (avance > 0 || mostrarPista) {
      final rectArco = rect.deflate(grosorReloj / 2);
      final trazo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosorReloj
        ..strokeCap = StrokeCap.round;
      if (mostrarPista) {
        canvas.drawArc(rectArco, math.pi, barrido, false, trazo..color = colorAvance.withValues(alpha: 0.18));
      }
      final a = avance.clamp(0.0, 1.0).toDouble();
      if (a > 0) {
        canvas.drawArc(rectArco, math.pi, barrido * a, false, trazo..color = colorAvance);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorEsquina old) =>
      old.avance != avance || old.fondo != fondo || old.borde != borde || old.izquierda != izquierda;
}
