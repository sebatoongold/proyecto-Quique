// ============================================================
// historial_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F4
//
// CAMBIOS v4 respecto a la v3:
//  - Anota en el registro de uso cuándo se abre el Historial (y desde
//    dónde: `origen`) y cada cambio de pestaña.
//
// Dos pestañas que responden dos preguntas distintas, sobre la misma
// línea de tiempo:
//  - POSTURA (monitoreo pasivo): ¿cómo fue su postura en el día?
//    -> línea de tiempo con los episodios del cinturón.
//  - JUEGOS: ¿está aprendiendo a reconocer y controlar su postura?
//    -> tiempo para lograr una pose, comparado con su primer día.
//
// Las pestañas NO son otro "mundo": cambian qué datos mira el mismo
// apoderado (como el selector de periodo de Apple Health).
// Los cálculos están en servicios/analisis_juegos.dart.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/registro_juego.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/analisis_juegos.dart';
import '../../servicios/registro_uso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/linea_tiempo_postura.dart';

enum SeccionHistorial { postura, juegos }

class HistorialScreen extends StatefulWidget {
  final SeccionHistorial inicial;
  final String origen; // para el registro de uso: desde dónde se abrió

  const HistorialScreen({
    super.key,
    this.inicial = SeccionHistorial.postura,
    this.origen = 'boton_historial',
  });

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late SeccionHistorial _seccion = widget.inicial;

  @override
  void initState() {
    super.initState();
    RegistroUso.anotar('historial', dato: '${widget.inicial.name} (desde ${widget.origen})');
  }
  late final Future<List<RegistroJuego>> _registros = AlmacenamientoJuegos.cargarDelActivo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SegmentedButton<SeccionHistorial>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: SeccionHistorial.postura,
                    label: Text('Postura'),
                    icon: Icon(Icons.accessibility_new_rounded),
                  ),
                  ButtonSegment(
                    value: SeccionHistorial.juegos,
                    label: Text('Juegos'),
                    icon: Icon(Icons.videogame_asset_rounded),
                  ),
                ],
                selected: {_seccion},
                onSelectionChanged: (s) {
                  RegistroUso.anotar('historial', dato: s.first.name);
                  setState(() => _seccion = s.first);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _seccion == SeccionHistorial.postura
                    ? const LineaTiempoPostura()
                    : ListView(children: [_juegos()]),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- JUEGOS ----------------
  Widget _juegos() {
    return FutureBuilder<List<RegistroJuego>>(
      future: _registros,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final r = AnalisisJuegos.calcular(snap.data!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tendencia de la semana (frase + gráfico).
            _tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Esta semana', style: Textos.secundario),
                  const SizedBox(height: 6),
                  Text(r.mensaje, style: Textos.cuerpoDestacado.copyWith(fontSize: 17, height: 1.3)),
                  if (r.lineaBase != null) ...[
                    const SizedBox(height: 20),
                    _GraficoSemana(resumen: r),
                    const SizedBox(height: 10),
                    const Text(
                      'Segundos para lograr una pose · más bajo = le costó menos',
                      style: TextStyle(fontSize: 12, color: Colores.textoSecundario),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Completadas e intentadas.
            if (r.completadas + r.intentadas > 0) ...[
              _tarjeta(child: _completadasIntentadas(r)),
              const SizedBox(height: 14),
            ],

            // 3. Qué puede hacer el apoderado.
            if (r.poseQueMasCuesta != null) ...[
              _tarjeta(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Colores.ambar, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: Textos.cuerpo.copyWith(height: 1.35),
                          children: [
                            const TextSpan(text: 'La que más le cuesta es '),
                            TextSpan(
                              text: '«${r.poseQueMasCuesta}»',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(
                              text: '. Acompáñalo en esa pose: ¿le incomoda algo, '
                                  'o no se entiende la instrucción?',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. Qué muestra esto (alfabetización del apoderado).
            _tarjeta(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Qué muestra esto?', style: Textos.cuerpoDestacado),
                  SizedBox(height: 6),
                  Text(
                    'El tiempo que tarda en lograr y mantener cada pose de los juegos. '
                    'Si baja con los días, está aprendiendo a reconocer y controlar su '
                    'postura. Se compara solo con él mismo, desde su primer día de juego.',
                    style: Textos.secundario,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _completadasIntentadas(ResumenSemanaJuegos r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Poses de esta semana', style: Textos.secundario),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (r.completadas > 0)
                  Expanded(flex: r.completadas, child: Container(color: Colores.comodo)),
                if (r.intentadas > 0)
                  Expanded(flex: r.intentadas, child: Container(color: Colores.ambar)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _leyenda(Colores.comodo, '${r.completadas} completadas'),
            const SizedBox(width: 16),
            _leyenda(Colores.ambar, '${r.intentadas} intentadas'),
          ],
        ),
      ],
    );
  }

  static Widget _leyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Textos.cuerpo.copyWith(fontSize: 14)),
      ],
    );
  }

  static Widget _tarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

/// Barras de los últimos 7 días + línea punteada del primer día.
class _GraficoSemana extends StatelessWidget {
  final ResumenSemanaJuegos resumen;

  const _GraficoSemana({required this.resumen});

  static const double alto = 140;
  static const List<String> letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final base = resumen.lineaBase!;
    var maximo = base;
    for (final d in resumen.dias) {
      final v = d.segundosPromedio;
      if (v != null && v > maximo) maximo = v;
    }
    maximo *= 1.15; // espacio arriba
    final yBase = base / maximo * alto;
    final hoy = resumen.dias.last.dia;

    return Column(
      children: [
        SizedBox(
          height: alto,
          child: Stack(
            children: [
              // Barras
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in resumen.dias)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: d.segundosPromedio == null
                              ? Container(
                                  // Día sin poses logradas: caja vacía
                                  width: 24,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colores.linea, width: 1.5),
                                  ),
                                )
                              : Container(
                                  width: 24,
                                  height: d.segundosPromedio! / maximo * alto,
                                  decoration: BoxDecoration(
                                    color: d.dia == hoy ? Colores.azul : Colores.neutro,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              // Línea del primer día
              Positioned(
                left: 0,
                right: 0,
                bottom: yBase,
                child: const SizedBox(height: 2, child: CustomPaint(painter: _LineaPunteada())),
              ),
              Positioned(
                right: 0,
                bottom: yBase + 4,
                child: Text(
                  'primer día: ${base.round()} s',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colores.bosque),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final d in resumen.dias)
              Expanded(
                child: Text(
                  letras[d.dia.weekday - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: d.dia == hoy ? FontWeight.w700 : FontWeight.w400,
                    color: d.dia == hoy ? Colores.azul : Colores.textoSecundario,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LineaPunteada extends CustomPainter {
  const _LineaPunteada();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = Colores.bosque
      ..strokeWidth = 2;
    const largo = 6.0, espacio = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + largo, size.height / 2), pincel);
      x += largo + espacio;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
