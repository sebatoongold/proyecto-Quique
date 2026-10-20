// ============================================================
// configuracion_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v10 — paso F9.2
//
// CAMBIOS v10 respecto a la v9:
//  - Testeo → QUIZ: dos botones, "Antes de jugar" y "Después de jugar",
//    con ✓ cuando el participante activo ya lo completó (si se toca uno
//    hecho, pregunta antes de repetirlo). Abre la pantalla del quiz en
//    el mundo del niño.
//  - Nueva herramienta "Datos de prueba: quiz".
//
// Sección "Testeo": participante activo (crear, elegir, exportar).
//
// Se abre desde el engranaje del inicio del apoderado. Reúne las
// herramientas de prueba:
//  - Datos del sensor: los valores en vivo del cinturón (calibrar).
//  - Datos de prueba: juegos (métricas crudas, para el diseñador y el
//    análisis del testeo; el apoderado ve el Historial).
// Más adelante: vinculación, recalibrar, editar perfil y ayuda.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/parametros_juego.dart';
import '../../modelos/participante.dart';
import '../../modelos/quiz.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../servicios/servicio_quiz.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../postura_screen.dart';
import '../../servicios/servicio_cinturon.dart';
import 'calibracion_screen.dart';
import 'cinturon_screen.dart';
import 'monitoreo_datos_screen.dart';
import 'observacion_screen.dart';
import 'uso_datos_screen.dart';
import 'parametros_screen.dart';
import 'participantes_screen.dart';
import 'quiz_datos_screen.dart';
import '../nino/quiz_screen.dart';
import 'registro_juegos_screen.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Testeo', style: Textos.secundario),
              ),
              // Participante activo: se actualiza solo al cambiarlo.
              ValueListenableBuilder<Participante?>(
                valueListenable: ServicioParticipantes.instancia.activo,
                builder: (context, activo, _) => _opcion(
                  context,
                  icono: Icons.badge_rounded,
                  titulo: activo == null ? 'Sin participante' : 'Participante ${activo.codigo}',
                  subtitulo: activo == null
                      ? 'Elige o crea uno antes de que juegue'
                      : '${activo.nombreVisible} · ${activo.edadTexto} · cambiar o exportar',
                  destino: const ParticipantesScreen(),
                ),
              ),
              const SizedBox(height: 10),
              // Calibración del participante activo.
              ValueListenableBuilder<Participante?>(
                valueListenable: ServicioParticipantes.instancia.activo,
                builder: (context, activo, _) {
                  final cal = activo?.calibracion;
                  return _opcion(
                    context,
                    icono: Icons.accessibility_new_rounded,
                    titulo: 'Calibrar postura',
                    subtitulo: activo == null
                        ? 'Primero elige un participante'
                        : (cal == null
                            ? '${activo.codigo}: todavía sin calibrar'
                            : '${activo.codigo}: calibrado con «${cal.instruccion}» · repetir'),
                    destino: activo == null
                        ? const ParticipantesScreen()
                        : CalibracionScreen(participante: activo),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Periodo de observación (antes, el monitoreo del Resumen de hoy).
              _opcion(
                context,
                icono: Icons.visibility_rounded,
                titulo: 'Periodo de observación',
                subtitulo: 'Delimitar los minutos observados y preguntar la estimación',
                destino: const ObservacionScreen(),
              ),
              const SizedBox(height: 10),
              // Quiz antes y después de jugar (F9.2).
              ListenableBuilder(
                listenable: Listenable.merge(
                    [ServicioParticipantes.instancia.activo, ServicioQuiz.instancia.sesiones]),
                builder: (context, _) => _quiz(context),
              ),
              const SizedBox(height: 10),
              // Cinturón: asignación y cola.
              ValueListenableBuilder<String>(
                valueListenable: ServicioCinturon.instancia.estado,
                builder: (context, estado, _) => _opcion(
                  context,
                  icono: Icons.sync_rounded,
                  titulo: 'Cinturón',
                  subtitulo: estado,
                  destino: const CinturonScreen(),
                ),
              ),
              const SizedBox(height: 10),
              // Parámetros del juego: avisa si hay una variante modificada.
              ValueListenableBuilder<ParametrosJuego>(
                valueListenable: ServicioParametros.instancia.actual,
                builder: (context, p, _) => _opcion(
                  context,
                  icono: Icons.tune_rounded,
                  titulo: 'Parámetros del juego',
                  subtitulo: p.esPorDefecto
                      ? 'Valores por defecto'
                      : 'Variante modificada · ángulo ${p.anguloLateral.round()}, '
                          'margen ${p.margenLateral.round()}, ${p.segundosMantener.round()} s'
                          '${p.espejo ? '' : ', sin espejo'}'
                          '${p.ceroCalibrado ? ', cero calibrado' : ''}',
                  destino: const ParametrosScreen(),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Herramientas de prueba', style: Textos.secundario),
              ),
              _opcion(
                context,
                icono: Icons.sensors_rounded,
                titulo: 'Datos del sensor',
                subtitulo: 'Valores en vivo del cinturón',
                destino: const PosturaScreen(),
              ),
              const SizedBox(height: 10),
              _opcion(
                context,
                icono: Icons.list_alt_rounded,
                titulo: 'Datos de prueba: juegos',
                subtitulo: 'Métricas crudas del participante activo',
                destino: const RegistroJuegosScreen(),
              ),
              const SizedBox(height: 10),
              _opcion(
                context,
                icono: Icons.timeline_rounded,
                titulo: 'Datos de prueba: monitoreo',
                subtitulo: 'Sesiones con los dos criterios (fijo y calibrado)',
                destino: const MonitoreoDatosScreen(),
              ),
              const SizedBox(height: 10),
              _opcion(
                context,
                icono: Icons.quiz_rounded,
                titulo: 'Datos de prueba: quiz',
                subtitulo: 'Respuestas antes y después de jugar',
                destino: const QuizDatosScreen(),
              ),
              const SizedBox(height: 10),
              _opcion(
                context,
                icono: Icons.touch_app_rounded,
                titulo: 'Datos de prueba: uso de la app',
                subtitulo: 'Mundos, puerta parental, Historial y línea de tiempo',
                destino: const UsoDatosScreen(),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Próximamente: vinculación del cinturón, recalibrar, editar perfil y ayuda.',
                  style: Textos.secundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// F9.2: tarjeta del quiz con sus dos botones.
  Widget _quiz(BuildContext context) {
    final activo = ServicioParticipantes.instancia.activo.value;
    Widget boton(MomentoQuiz m) {
      final hecho = activo != null && ServicioQuiz.instancia.hecho(activo.codigo, m);
      return Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            foregroundColor: Colores.azul,
            side: BorderSide(color: hecho ? Colores.comodo : Colores.neutro, width: hecho ? 2 : 1),
          ),
          icon: Icon(hecho ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
              color: hecho ? Colores.comodo : Colores.azul),
          label: Text(m.titulo, textAlign: TextAlign.center),
          onPressed: activo == null ? null : () => _abrirQuiz(context, m, hecho),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_rounded, color: Colores.azul),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quiz', style: Textos.cuerpoDestacado),
                    Text(
                      activo == null
                          ? 'Primero elige un participante'
                          : '${activo.codigo}: léelo en voz alta; el niño responde tocando',
                      style: Textos.secundario,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              boton(MomentoQuiz.antes),
              const SizedBox(width: 10),
              boton(MomentoQuiz.despues),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirQuiz(BuildContext context, MomentoQuiz m, bool hecho) async {
    if (hecho) {
      final repetir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Repetir el quiz "${m.titulo}"?'),
          content: const Text('Ya está hecho. Se guarda uno nuevo y Datos de prueba muestra el último; '
              'el anterior queda en la exportación.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Repetir')),
          ],
        ),
      );
      if (repetir != true || !context.mounted) return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(momento: m)));
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icono, color: Colores.azul),
        title: Text(titulo, style: Textos.cuerpoDestacado),
        subtitle: Text(subtitulo, style: Textos.secundario),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colores.azul),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino)),
      ),
    );
  }
}
