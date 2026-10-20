// ============================================================
// quiz_datos_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F9.2 (quiz antes y después de jugar)
//
// Herramienta del INVESTIGADOR (Configuración → Datos de prueba: quiz).
// Para el participante activo:
//  - Tabla: cada pregunta con la respuesta de ANTES y de DESPUÉS (el
//    último quiz completo de cada momento) y su lectura (esperada /
//    parcial / otra / no sabe; ver modelos/quiz.dart).
//  - Aviso destacado si marcó el ARMADILLO como el que más cansa y como
//    el más cómodo (la mala postura se siente cómoda).
//  - Detalle de cada quiz: segundos hasta responder, cambios de opción
//    y en qué posición estaba la tarjeta elegida. También los quiz
//    incompletos o repetidos.
// El apoderado no ve esta pantalla.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/quiz.dart';
import '../../servicios/servicio_participantes.dart';
import '../../servicios/servicio_quiz.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class QuizDatosScreen extends StatelessWidget {
  const QuizDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codigo = ServicioParticipantes.instancia.activo.value?.codigo;
    final servicio = ServicioQuiz.instancia;
    final antes = servicio.ultimo(codigo, MomentoQuiz.antes);
    final despues = servicio.ultimo(codigo, MomentoQuiz.despues);
    final todos = servicio.de(codigo).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('Quiz · ${codigo ?? 'sin participante'}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (antes == null && despues == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no hay quiz completos para este participante.',
                      textAlign: TextAlign.center, style: Textos.secundario),
                )
              else ...[
                _tabla(antes, despues),
                for (final s in [antes, despues])
                  if (s != null && s.armadilloCansaYComodo) _avisoArmadillo(s.momento),
              ],
              const SizedBox(height: 18),
              if (todos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('Cada quiz (del más reciente al más antiguo)', style: Textos.tituloTarjeta),
                ),
                for (final s in todos) _detalle(s),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabla(SesionQuiz? antes, SesionQuiz? despues) {
    Widget celda(SesionQuiz? s, String pregunta) {
      if (s == null) return const Text('—', style: Textos.secundario);
      final r = s.respuestaA(pregunta);
      if (r == null) return const Text('—', style: Textos.secundario);
      final lectura = r.lectura;
      final color = switch (lectura) {
        LecturaRespuesta.esperada => Colores.comodo,
        LecturaRespuesta.parcial => Colores.ambar,
        _ => Colores.textoSecundario,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombreRespuesta(r.respuesta), style: Textos.cuerpoDestacado),
          if (lectura != LecturaRespuesta.sinCorrecta)
            Text(lectura.texto, style: Textos.secundario.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(18)),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          const TableRow(children: [
            Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Pregunta', style: Textos.secundario)),
            Text('Antes', style: Textos.secundario),
            Text('Después', style: Textos.secundario),
          ]),
          for (final p in preguntasQuiz)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 8),
                child: Text(p.texto, style: Textos.cuerpo),
              ),
              p.soloDespues ? const Text('(no se pregunta)', style: Textos.secundario) : celda(antes, p.id),
              celda(despues, p.id),
            ]),
        ],
      ),
    );
  }

  Widget _avisoArmadillo(MomentoQuiz m) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colores.ambar.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colores.ambar),
      ),
      child: Text(
        '${m.titulo}: marcó el ARMADILLO como el que más cansa y también como el más cómodo '
        '(la mala postura se siente cómoda).',
        style: Textos.cuerpo,
      ),
    );
  }

  Widget _detalle(SesionQuiz s) {
    String seg(int ms) => '${(ms / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.momento.titulo} · ${_fechaHora(s.inicio)}${s.completo ? '' : ' · INCOMPLETO'}',
              style: Textos.cuerpoDestacado),
          const SizedBox(height: 4),
          for (final r in s.respuestas)
            Text(
              '${r.pregunta}: ${nombreRespuesta(r.respuesta)} · '
              'tocó a los ${r.msPrimerToque == null ? '—' : seg(r.msPrimerToque!)} · '
              'listo a los ${seg(r.msListo)} · cambios ${r.cambios} · '
              'posición ${r.orden.indexOf(r.respuesta) < 0 ? '—' : r.orden.indexOf(r.respuesta) + 1} de 4',
              style: Textos.secundario,
            ),
        ],
      ),
    );
  }

  static String _fechaHora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)} ${dos(d.hour)}:${dos(d.minute)}';
  }
}
