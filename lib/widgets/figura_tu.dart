// ============================================================
// figura_tu.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v7 — paso F6.2
//
// CAMBIOS v7 respecto a la v6:
//  - La SILLA se dibuja solo en la vista de COSTADO: de frente se veía
//    como una línea gris detrás de las piernas que no se entendía.
//  - Los tipos VistaFigura y ModoBrazos pasaron a modelos/pose.dart (las
//    poses los necesitan); este archivo los usa desde ahí.
//
// Qué dibuja: un niño SENTADO, de frente o de costado (con silla).
//  - Espalda como curva continua; proporciones medidas en "cabezas" (h).
//  - Vista de frente (`VistaFigura.frente`): se inclina hacia los lados
//    según `lateral` (con el modo espejo del panel).
//  - Vista de costado (`VistaFigura.costado`): se curva hacia adelante o
//    atrás según `adelante` (el espejo no aplica).
//  - Brazos según la pose (`brazos`): apoyados, abrazando las rodillas
//    o arriba, con un borde claro para distinguirlos del tronco.
//  - Zona de la pose: `zonaDesde`/`zonaHasta` (permite un solo lado), o
//    silueta ± `margenLateral` si no se dan.
//  - Silueta, figura fantasma, flecha ámbar y marcas de "quieto"; los
//    valores de fantasma y flecha van en el eje de la vista.
//
// Cómo se arma (coherente con lo que miden los sensores):
//  - La CADERA queda fija (sensor de cadera = referencia).
//  - La espalda sube desde la cadera; su inclinación total θ sale de la
//    diferencia cuello − cadera, y se reparte por la espalda:
//      ángulo en el punto s = θ · (s / L)^curvaEspalda
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelos/pose.dart';
import '../servicios/servicio_parametros.dart';
import '../tema/colores.dart';

// ---------- PARÁMETROS AJUSTABLES DEL DIBUJO ----------
// EXAGERACIÓN y ESPEJO: en el panel de parámetros.
//
// Proporciones, en "cabezas" (h = alto de la cabeza):
const double largoEspalda = 2.25; // cadera -> base del cuello
const double largoCuello = 0.32;
const double largoMuslo = 1.55;
const double largoPierna = 1.55;
const double largoPie = 0.45;
const double anchoTroncoCadera = 1.05; // de frente
const double anchoTroncoHombros = 1.25; // de frente
const double fondoTroncoCadera = 0.75; // de costado
const double fondoTroncoHombros = 0.6; // de costado
const double grosorPierna = 0.42;
const double grosorBrazo = 0.26;
// Cuánto se concentra la curva hacia arriba (1 = arco parejo; más alto =
// la curva se junta en la parte alta de la espalda).
const double curvaEspalda = 1.1;
// La cabeza sigue la curva de la espalda un poco más (1 = igual).
const double seguimientoCabeza = 1.15;
// Alto de la figura, en cabezas: arriba de la cadera (espalda, cuello y
// cabeza), abajo de la cadera (asiento, pierna, pie y aire) y el espacio
// que se reserva sobre la cabeza para la zona y la flecha.
const double cabezasSobreCadera = 3.6;
const double cabezasBajoCadera = 2.15;
const double cabezasEspacioArriba = 1.3;
// Ancho que necesita la figura, en cabezas, en cada vista.
const double cabezasDeAnchoFrente = 4.2;
const double cabezasDeAnchoCostado = 5.0;
// Tamaño de la figura respecto del máximo que cabe en su espacio
// (1 = lo más grande posible; 0,85 = un poco más chica, con aire).
const double escalaFigura = 0.85;

// Silueta, zona y recursos de cómic:
const double grosorExtraSilueta = 1.15; // la silueta es algo más gruesa
const double opacidadZona = 0.45;
const double opacidadFantasma = 0.22;
const double grosorFlecha = 0.13; // en cabezas
const double barridoMinimoFlecha = 0.5; // radianes: la flecha nunca es tan corta que no se vea

/// Convierte las "unidades" del sensor (escala 0–180) a grados
/// aproximados: unidades ≈ 90 × seno(ángulo).
double unidadesAGrados(double unidades) =>
    math.asin((unidades / 90).clamp(-1.0, 1.0)) * 180 / math.pi;

class FiguraTu extends StatelessWidget {
  final double adelante; // unidades, relativas a la postura cero (+ adelante)
  final double lateral; // unidades (+ derecha)
  final double siluetaAdelante; // pose objetivo
  final double siluetaLateral;
  final Color color;
  final bool mostrarSilueta;
  final double? margenLateral; // zona = silueta ± margen (vista de frente)
  // Zona con límites propios, en el eje de la vista (unidades). Si se
  // dan, mandan sobre margenLateral. Sirve para zonas de un solo lado.
  final double? zonaDesde;
  final double? zonaHasta;
  // Recursos de cómic (opcionales). Valores en el eje de la vista.
  final double? fantasmaLateral; // posición de partida, tenue
  final double? flechaDesde;
  final double? flechaHasta;
  final bool marcasQuieto;
  final bool mostrarSensores;
  // Nuevos en v5:
  final VistaFigura vista;
  final ModoBrazos brazos; // de la figura «Tú»
  final ModoBrazos brazosSilueta; // de la silueta (la pose)
  final bool mostrarSilla;

  const FiguraTu({
    super.key,
    required this.adelante,
    required this.lateral,
    required this.siluetaAdelante,
    required this.siluetaLateral,
    required this.color,
    this.mostrarSilueta = true,
    this.margenLateral,
    this.zonaDesde,
    this.zonaHasta,
    this.fantasmaLateral,
    this.flechaDesde,
    this.flechaHasta,
    this.marcasQuieto = false,
    this.mostrarSensores = true,
    this.vista = VistaFigura.frente,
    this.brazos = ModoBrazos.apoyados,
    this.brazosSilueta = ModoBrazos.apoyados,
    this.mostrarSilla = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = ServicioParametros.instancia.actual.value;
    return CustomPaint(
      size: Size.infinite,
      painter: _PintorFigura(
        espejo: p.espejo,
        amplificacion: p.amplificacion,
        f: this,
      ),
    );
  }
}

/// Puntos clave de un cuerpo ya calculado.
class _Cuerpo {
  final List<Offset> espalda; // de la cadera a la base del cuello
  final List<double> angulos; // ángulo en cada punto (radianes)
  final Offset cadera, cabeza;
  final double radioCabeza;
  const _Cuerpo(this.espalda, this.angulos, this.cadera, this.cabeza, this.radioCabeza);
  Offset get tope => espalda.last;
}

class _PintorFigura extends CustomPainter {
  final bool espejo;
  final double amplificacion;
  final FiguraTu f;

  _PintorFigura({required this.espejo, required this.amplificacion, required this.f});

  bool get _costado => f.vista == VistaFigura.costado;

  /// Unidades del eje de la vista -> ángulo dibujado (radianes; + = hacia
  /// la derecha de la pantalla).
  double _angulo(double unidades) {
    final signo = _costado ? 1.0 : (espejo ? 1.0 : -1.0);
    return signo * unidadesAGrados(unidades) * amplificacion * math.pi / 180;
  }

  // ---------- Medidas según el espacio disponible ----------
  static const double _altoTotal = cabezasEspacioArriba + cabezasSobreCadera + cabezasBajoCadera;

  double _h(Size s) =>
      escalaFigura *
      math.min(
        s.height / _altoTotal,
        s.width / (_costado ? cabezasDeAnchoCostado : cabezasDeAnchoFrente),
      );

  /// La cadera, con la figura completa (incluido el espacio de arriba)
  /// centrada verticalmente en su espacio.
  Offset _cadera(Size s) {
    final h = _h(s);
    final arriba = (s.height - _altoTotal * h) / 2;
    final y = arriba + (cabezasEspacioArriba + cabezasSobreCadera) * h;
    final x = _costado ? s.width * 0.36 : s.width / 2;
    return Offset(x, y);
  }

  /// Calcula el cuerpo para una inclinación (en unidades del eje).
  _Cuerpo _cuerpo(Size s, double unidades) {
    final h = _h(s);
    final cadera = _cadera(s);
    final theta = _angulo(unidades);
    const n = 24;
    final ds = largoEspalda * h / n;
    final pts = <Offset>[cadera];
    final angs = <double>[0];
    var x = cadera.dx, y = cadera.dy;
    for (var i = 1; i <= n; i++) {
      final medio = theta * math.pow((i - 0.5) / n, curvaEspalda).toDouble();
      x += math.sin(medio) * ds;
      y -= math.cos(medio) * ds;
      pts.add(Offset(x, y));
      angs.add(theta * math.pow(i / n, curvaEspalda).toDouble());
    }
    final aCab = angs.last * seguimientoCabeza;
    final dir = Offset(math.sin(aCab), -math.cos(aCab));
    final r = h * 0.5;
    final cabeza = pts.last + dir * (largoCuello * h + r * 0.95);
    return _Cuerpo(pts, angs, cadera, cabeza, r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ejeTu = _costado ? f.adelante : f.lateral;
    final ejeSilueta = _costado ? f.siluetaAdelante : f.siluetaLateral;

    // Zona de la pose.
    double? desde = f.zonaDesde, hasta = f.zonaHasta;
    if (desde == null || hasta == null) {
      final m = f.margenLateral;
      if (m != null && !_costado) {
        desde = ejeSilueta - m;
        hasta = ejeSilueta + m;
      }
    }
    if (f.mostrarSilueta && desde != null && hasta != null) {
      _dibujarZona(canvas, size, desde, hasta);
    }
    if (f.mostrarSilla && _costado) _dibujarSilla(canvas, size);
    if (f.mostrarSilueta) {
      _dibujarCuerpo(canvas, size, ejeSilueta, Colores.silueta, grosorExtraSilueta, false, f.brazosSilueta);
    }
    final fantasma = f.fantasmaLateral;
    if (fantasma != null) {
      _dibujarCuerpo(canvas, size, fantasma, f.color.withValues(alpha: opacidadFantasma), 1.0, false,
          ModoBrazos.apoyados);
    }
    _dibujarCuerpo(canvas, size, ejeTu, f.color, 1.0, f.mostrarSensores, f.brazos);
    final fd = f.flechaDesde, fh = f.flechaHasta;
    if (fd != null && fh != null) _dibujarFlecha(canvas, size, fd, fh);
    if (f.marcasQuieto) _dibujarMarcasQuieto(canvas, size, ejeTu);
  }

  // ---------- Silla ----------
  void _dibujarSilla(Canvas canvas, Size size) {
    final h = _h(size);
    final c = _cadera(size);
    final p = Paint()
      ..color = Colores.linea
      ..strokeWidth = h * 0.16
      ..strokeCap = StrokeCap.round;
    final asiento = c.dy + 0.15 * h;
    if (_costado) {
      canvas.drawLine(Offset(c.dx - 0.6 * h, asiento), Offset(c.dx + 1.9 * h, asiento), p);
      canvas.drawLine(Offset(c.dx - 0.55 * h, asiento), Offset(c.dx - 0.55 * h, asiento - 1.4 * h), p);
      final pata = p..strokeWidth = h * 0.12;
      canvas.drawLine(Offset(c.dx - 0.5 * h, asiento), Offset(c.dx - 0.5 * h, asiento + 1.9 * h), pata);
      canvas.drawLine(Offset(c.dx + 1.7 * h, asiento), Offset(c.dx + 1.7 * h, asiento + 1.9 * h), pata);
    } else {
      canvas.drawLine(Offset(c.dx - 1.2 * h, asiento + 0.35 * h), Offset(c.dx + 1.2 * h, asiento + 0.35 * h), p);
    }
  }

  // ---------- Cuerpo ----------
  void _dibujarCuerpo(Canvas canvas, Size size, double unidades, Color c, double grosor,
      bool conSensores, ModoBrazos brazos) {
    final h = _h(size);
    final cu = _cuerpo(size, unidades);
    final relleno = Paint()..color = c;
    final trazo = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Piernas.
    trazo.strokeWidth = grosorPierna * h * grosor;
    final cad = cu.cadera;
    if (_costado) {
      final rodilla = cad + Offset(largoMuslo * h, 0.05 * h);
      final tobillo = rodilla + Offset(0.05 * h, largoPierna * h);
      final pie = tobillo + Offset(largoPie * h, 0);
      canvas.drawPath(
        Path()
          ..moveTo(cad.dx, cad.dy)
          ..lineTo(rodilla.dx, rodilla.dy)
          ..lineTo(tobillo.dx, tobillo.dy)
          ..lineTo(pie.dx, pie.dy),
        trazo,
      );
    } else {
      for (final s in [-1.0, 1.0]) {
        final arriba = cad + Offset(s * 0.35 * h, 0);
        final rodilla = cad + Offset(s * 0.42 * h, 0.45 * h);
        final tobillo = rodilla + Offset(s * 0.05 * h, (largoPierna - 0.1) * h);
        canvas.drawPath(
          Path()
            ..moveTo(arriba.dx, arriba.dy)
            ..lineTo(rodilla.dx, rodilla.dy)
            ..lineTo(tobillo.dx, tobillo.dy),
          trazo,
        );
      }
    }

    // Tronco: la espalda desplazada a ambos lados según su normal.
    final anchoBase = (_costado ? fondoTroncoCadera : anchoTroncoCadera) * h;
    final anchoTope = (_costado ? fondoTroncoHombros : anchoTroncoHombros) * h;
    final izq = <Offset>[], der = <Offset>[];
    final n = cu.espalda.length - 1;
    for (var i = 0; i <= n; i++) {
      final a = cu.angulos[i];
      final w = anchoBase + (anchoTope - anchoBase) * (i / n);
      final normal = Offset(math.cos(a), math.sin(a)) * (w / 2);
      izq.add(cu.espalda[i] - normal);
      der.add(cu.espalda[i] + normal);
    }
    final contorno = Path()..moveTo(izq.first.dx, izq.first.dy);
    for (final p in izq.skip(1)) {
      contorno.lineTo(p.dx, p.dy);
    }
    for (final p in der.reversed) {
      contorno.lineTo(p.dx, p.dy);
    }
    contorno.close();
    canvas.drawPath(contorno, relleno);
    // Borde del mismo color: redondea las esquinas (y engrosa la silueta).
    trazo.strokeWidth = 0.22 * h * grosor;
    canvas.drawPath(contorno, trazo);

    // Cuello y cabeza.
    final aCab = cu.angulos.last * seguimientoCabeza;
    final dir = Offset(math.sin(aCab), -math.cos(aCab));
    trazo.strokeWidth = 0.32 * h * grosor;
    canvas.drawLine(cu.tope, cu.tope + dir * (largoCuello * h), trazo);
    canvas.drawCircle(cu.cabeza, cu.radioCabeza * (grosor > 1 ? 1.15 : 1.0), relleno);

    // Brazos (no los miden los sensores: solo guían).
    _dibujarBrazos(canvas, h, cu, c, grosor, brazos);

    // Los dos sensores del cinturón (solo en la figura real).
    if (conSensores) {
      final punto = Paint()..color = Colores.tarjeta;
      final rp = 0.15 * h;
      canvas.drawCircle(cad + Offset(_costado ? -0.05 * h : 0, -0.25 * h), rp, punto);
      canvas.drawCircle(cu.tope + Offset(0, 0.15 * h), rp, punto);
    }
  }

  void _dibujarBrazos(Canvas canvas, double h, _Cuerpo cu, Color c, double grosor, ModoBrazos modo) {
    final paths = <Path>[];
    final cad = cu.cadera;
    if (_costado) {
      final hombro = cu.espalda[(cu.espalda.length * 0.9).floor()];
      final rodilla = cad + Offset(largoMuslo * h, 0.05 * h);
      late Offset codo, mano;
      switch (modo) {
        case ModoBrazos.abrazo:
          mano = rodilla + Offset(0.28 * h, 0.55 * h);
          codo = rodilla + Offset(0.05 * h, -0.15 * h);
        case ModoBrazos.arriba:
          codo = hombro + Offset(0.15 * h, -0.9 * h);
          mano = hombro + Offset(0.25 * h, -1.75 * h);
        case ModoBrazos.apoyados:
          mano = cad + Offset(1.05 * h, -0.12 * h);
          codo = Offset((hombro.dx + mano.dx) / 2 + 0.1 * h, (hombro.dy + mano.dy) / 2 + 0.25 * h);
      }
      paths.add(Path()
        ..moveTo(hombro.dx, hombro.dy)
        ..lineTo(codo.dx, codo.dy)
        ..lineTo(mano.dx, mano.dy));
    } else {
      final a = cu.angulos.last;
      for (final s in [-1.0, 1.0]) {
        final hombro = cu.tope + Offset(math.cos(a), math.sin(a)) * (s * 0.72 * h);
        if (modo == ModoBrazos.arriba) {
          final mano = hombro + Offset(s * 0.35 * h, -1.6 * h);
          paths.add(Path()
            ..moveTo(hombro.dx, hombro.dy)
            ..quadraticBezierTo(hombro.dx + s * 0.4 * h, hombro.dy - 0.8 * h, mano.dx, mano.dy));
        } else {
          final mano = hombro + Offset(s * 0.18 * h, 1.55 * h);
          paths.add(Path()
            ..moveTo(hombro.dx, hombro.dy)
            ..quadraticBezierTo(hombro.dx + s * 0.25 * h, hombro.dy + 0.8 * h, mano.dx, mano.dy));
        }
      }
    }
    // Borde claro (para que el brazo se distinga sobre el tronco) y brazo.
    final borde = Paint()
      ..color = Colores.tarjeta
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = grosorBrazo * h * grosor + h * 0.16;
    final brazo = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = grosorBrazo * h * grosor;
    // La silueta no lleva borde claro (es un contorno de fondo).
    final conBorde = c != Colores.silueta;
    for (final p in paths) {
      if (conBorde) canvas.drawPath(p, borde);
      canvas.drawPath(p, brazo);
    }
  }

  // ---------- Zona ----------
  /// Cuña clara desde la cadera, entre la cabeza en "desde" y la cabeza
  /// en "hasta". Si la cabeza de «Tú» cae dentro, el juego lo cuenta.
  void _dibujarZona(Canvas canvas, Size size, double desde, double hasta) {
    final cad = _cadera(size);
    final a1 = _anguloCabeza(size, desde);
    final a2 = _anguloCabeza(size, hasta);
    final radio = (_cuerpo(size, 0).cabeza - cad).distance + _h(size) * 0.9;
    final inicio = math.min(a1, a2);
    canvas.drawArc(
      Rect.fromCircle(center: cad, radius: radio),
      inicio - math.pi / 2, // en el lienzo, "arriba" es −90°
      (a2 - a1).abs(),
      true,
      Paint()..color = Colores.silueta.withValues(alpha: opacidadZona),
    );
  }

  /// Ángulo (desde la vertical, + derecha) de la cabeza vista desde la cadera.
  double _anguloCabeza(Size size, double unidades) {
    final cu = _cuerpo(size, unidades);
    final d = cu.cabeza - cu.cadera;
    return math.atan2(d.dx, -d.dy);
  }

  // ---------- Flecha ----------
  /// Flecha curva en ámbar, por fuera de la cabeza, desde la pose
  /// "desde" hasta "hasta" (unidades del eje de la vista).
  void _dibujarFlecha(Canvas canvas, Size size, double desdeU, double hastaU) {
    var a = _anguloCabeza(size, desdeU);
    var b = _anguloCabeza(size, hastaU);
    if ((b - a).abs() < 0.001) return;
    if ((b - a).abs() < barridoMinimoFlecha) {
      final centro = (a + b) / 2;
      final sentido = (b - a).sign;
      a = centro - sentido * barridoMinimoFlecha / 2;
      b = centro + sentido * barridoMinimoFlecha / 2;
    }
    final h = _h(size);
    final cad = _cadera(size);
    final radio = (_cuerpo(size, 0).cabeza - cad).distance + h * 1.3;
    final pincel = Paint()
      ..color = Colores.ambar
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = grosorFlecha * h;
    final sentido = (b - a).sign;
    final finArco = b - sentido * 0.08;
    canvas.drawPath(
      Path()..addArc(Rect.fromCircle(center: cad, radius: radio), a - math.pi / 2, finArco - a),
      pincel,
    );
    final punta = cad + Offset(math.sin(b), -math.cos(b)) * radio;
    final tangente = Offset(math.cos(b), math.sin(b)) * sentido;
    final normal = Offset(-tangente.dy, tangente.dx);
    final largo = h * 0.45;
    final base = punta - tangente * largo;
    canvas.drawPath(
      Path()
        ..moveTo(punta.dx, punta.dy)
        ..lineTo((base + normal * (largo * 0.6)).dx, (base + normal * (largo * 0.6)).dy)
        ..lineTo((base - normal * (largo * 0.6)).dx, (base - normal * (largo * 0.6)).dy)
        ..close(),
      Paint()..color = Colores.ambar,
    );
  }

  // ---------- Marcas de "quieto" ----------
  void _dibujarMarcasQuieto(Canvas canvas, Size size, double unidades) {
    final h = _h(size);
    final cu = _cuerpo(size, unidades);
    final r = cu.radioCabeza;
    final pincel = Paint()
      ..color = Colores.ambar
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.1;
    for (final lado in [-1.0, 1.0]) {
      for (final grados in [-35.0, 0.0, 35.0]) {
        final t = grados * math.pi / 180;
        final dir = Offset(lado * math.cos(t), math.sin(t));
        canvas.drawLine(cu.cabeza + dir * (r * 1.6), cu.cabeza + dir * (r * 2.3), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorFigura old) {
    final a = old.f, b = f;
    return old.espejo != espejo ||
        old.amplificacion != amplificacion ||
        a.adelante != b.adelante ||
        a.lateral != b.lateral ||
        a.siluetaAdelante != b.siluetaAdelante ||
        a.siluetaLateral != b.siluetaLateral ||
        a.color != b.color ||
        a.mostrarSilueta != b.mostrarSilueta ||
        a.margenLateral != b.margenLateral ||
        a.zonaDesde != b.zonaDesde ||
        a.zonaHasta != b.zonaHasta ||
        a.fantasmaLateral != b.fantasmaLateral ||
        a.flechaDesde != b.flechaDesde ||
        a.flechaHasta != b.flechaHasta ||
        a.marcasQuieto != b.marcasQuieto ||
        a.mostrarSensores != b.mostrarSensores ||
        a.vista != b.vista ||
        a.brazos != b.brazos ||
        a.brazosSilueta != b.brazosSilueta ||
        a.mostrarSilla != b.mostrarSilla;
  }
}
