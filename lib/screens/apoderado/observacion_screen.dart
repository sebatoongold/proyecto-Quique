// ============================================================
// observacion_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F7.3 (el monitoreo pasa a ser del investigador)
//
// Herramienta del INVESTIGADOR (Configuración → Periodo de observación).
// Es lo que antes estaba en el Resumen de hoy (F5), sacado del mundo
// del apoderado: el apoderado ya no inicia ni termina nada.
//
// Para qué sirve en el testeo:
//  - Delimita los 20–30 minutos en que el niño sigue con lo suyo.
//  - Graba CADA lectura del cinturón en ese rato, para calcular después
//    los dos criterios (fijo y calibrado) y validar al cinturón.
//  - Al terminar, hace la pregunta al apoderado ("¿cuántas veces crees
//    que…?") ANTES de que vea el resultado, y la guarda con la sesión.
//
// Mientras corre NO muestra cuántas veces van (no contaminar la
// estimación). Los resultados se ven en Datos de prueba: monitoreo.
//
// IMPORTANTE: dejar el teléfono con la pantalla encendida durante el
// periodo (ver servicio_monitoreo.dart).
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../modelos/sesion_monitoreo.dart';
import '../../servicios/servicio_ble.dart';
import '../../servicios/servicio_cinturon.dart';
import '../../servicios/servicio_monitoreo.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import 'monitoreo_datos_screen.dart';

class ObservacionScreen extends StatefulWidget {
  const ObservacionScreen({super.key});

  @override
  State<ObservacionScreen> createState() => _ObservacionScreenState();
}

class _ObservacionScreenState extends State<ObservacionScreen> {
  final _monitoreo = ServicioMonitoreo.instancia;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    ServicioBle.instancia.iniciar();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _monitoreo.grabando) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _empezar() async {
    await _monitoreo.empezar();
    if (mounted) setState(() {});
  }

  Future<void> _terminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar el periodo de observación?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Terminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    final sesion = await _monitoreo.terminar();
    if (sesion == null || !mounted) return;
    // Lo que el cinturón registró en los cortes entra a los resultados.
    ServicioCinturon.instancia.sincronizar();
    setState(() {});
    final estimacion = await _preguntarEstimacion(sesion);
    await _monitoreo.guardarEstimacion(sesion, estimacion);
    if (mounted) setState(() {});
  }

  /// La pregunta al apoderado, ANTES de que vea el resultado.
  Future<String?> _preguntarEstimacion(SesionMonitoreo s) {
    final nombre = ServicioParticipantes.instancia.activo.value?.nombreVisible;
    final minutos = s.duracion.inMinutes;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pregunta para el apoderado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En estos $minutos minutos, ¿cuántas veces crees que '
              '${nombre ?? 'el niño'} se encorvó o se inclinó por más de unos segundos?',
              style: Textos.cuerpo,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in opcionesEstimacion)
                  ActionChip(
                    label: Text(o, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => Navigator.of(context).pop(o),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Omitir')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCurso = _monitoreo.enCurso.value;
    final activo = ServicioParticipantes.instancia.activo.value;
    final ultima = _monitoreo.de(activo?.codigo).lastOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Periodo de observación')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(22)),
                child: enCurso != null ? _grabando(enCurso) : _detenido(activo?.codigo),
              ),
              if (enCurso == null && ultima != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(18)),
                  child: Text(
                    'Último periodo de ${activo?.codigo ?? 'sin participante'}: '
                    '${ultima.duracion.inMinutes} min · estimación: ${ultima.estimacionApoderado ?? 'no se preguntó'}',
                    style: Textos.secundario,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  shape: const StadiumBorder(),
                  foregroundColor: Colores.azul,
                ),
                icon: const Icon(Icons.timeline_rounded),
                label: const Text('Ver resultados (Datos de prueba: monitoreo)'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MonitoreoDatosScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detenido(String? codigo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sin periodo en curso', style: Textos.tituloTarjeta),
          const SizedBox(height: 8),
          Text(
            'Participante: ${codigo ?? 'ninguno'}. Con el cinturón puesto, inicia el periodo y '
            'deja que el niño siga con lo suyo. Mantén la pantalla encendida.',
            style: Textos.secundario,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar periodo'),
            onPressed: _empezar,
          ),
        ],
      );

  Widget _grabando(SesionMonitoreo s) {
    final d = s.duracion;
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fiber_manual_record_rounded, color: Colores.comodo, size: 16),
            const SizedBox(width: 6),
            const Expanded(child: Text('Observando', style: Textos.tituloTarjeta)),
            Text('$mm:$ss', style: Textos.tituloTarjeta),
          ],
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<EstadoConexion>(
          valueListenable: ServicioBle.instancia.estado,
          builder: (context, estado, _) => Text(
            estado == EstadoConexion.conectado
                ? 'Grabando lecturas. El resultado se ve al terminar.'
                : 'Sin conexión: este rato lo cubrirá la cola del cinturón.',
            style: Textos.secundario.copyWith(
              color: estado == EstadoConexion.conectado ? Colores.textoSecundario : Colores.ambar,
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            shape: const StadiumBorder(),
            foregroundColor: Colores.azul,
          ),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Terminar periodo'),
          onPressed: _terminar,
        ),
      ],
    );
  }
}
