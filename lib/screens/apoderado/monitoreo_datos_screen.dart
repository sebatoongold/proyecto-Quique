// ============================================================
// monitoreo_datos_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F7.2
//
// CAMBIOS v2 respecto a la v1:
//  - Cada criterio dice cuántos episodios se RECUPERARON del cinturón
//    (cortes de conexión).
//  - VALIDACIÓN: con el criterio que usó el cinturón, cuántos episodios
//    registró él con conexión vs. cuántos calculó la app.
//
// Herramienta del INVESTIGADOR (Configuración → Datos de prueba:
// monitoreo). Para cada sesión del participante activo muestra, lado a
// lado, los DOS criterios:
//  - Fijo: el umbral del cinturón, igual para todos.
//  - Calibrado: desde la postura neutral del niño (si tenía calibración).
// Además: la estimación del apoderado, el tiempo sin conexión, el
// tiempo jugando (descontado) y si la sesión quedó interrumpida.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/registro_juego.dart';
import '../../modelos/sesion_monitoreo.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/analisis_monitoreo.dart';
import '../../servicios/servicio_cinturon.dart';
import '../../servicios/servicio_monitoreo.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class MonitoreoDatosScreen extends StatefulWidget {
  const MonitoreoDatosScreen({super.key});

  @override
  State<MonitoreoDatosScreen> createState() => _MonitoreoDatosScreenState();
}

class _MonitoreoDatosScreenState extends State<MonitoreoDatosScreen> {
  final String? _codigo = ServicioParticipantes.instancia.activo.value?.codigo;
  late Future<List<RegistroJuego>> _juegos = AlmacenamientoJuegos.cargarDelActivo();

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar las sesiones de ${_codigo ?? 'sin participante'}?'),
        content: const Text('Esto no se puede deshacer. Si las necesitas, exporta antes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true) return;
    await ServicioMonitoreo.instancia.borrarDe(_codigo);
    setState(() => _juegos = AlmacenamientoJuegos.cargarDelActivo());
  }

  @override
  Widget build(BuildContext context) {
    final sesiones = ServicioMonitoreo.instancia.de(_codigo).reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoreo · ${_codigo ?? 'sin participante'}'),
        actions: [
          IconButton(
            tooltip: 'Borrar estas sesiones',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _borrar,
          ),
        ],
      ),
      body: FutureBuilder<List<RegistroJuego>>(
        future: _juegos,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (sesiones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay sesiones de monitoreo. Inícialas desde el Resumen de hoy.',
                  textAlign: TextAlign.center,
                  style: Textos.secundario,
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sesiones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _tarjeta(sesiones[i], snap.data!),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjeta(SesionMonitoreo s, List<RegistroJuego> juegos) {
    final delCinturon = ServicioCinturon.instancia.episodios.value;
    final fijo = AnalisisMonitoreo.calcular(s, Criterio.fijo,
        juegos: juegos, episodiosCinturon: delCinturon)!;
    final cal = AnalisisMonitoreo.calcular(s, Criterio.calibrado,
        juegos: juegos, episodiosCinturon: delCinturon);
    final validacion =
        AnalisisMonitoreo.comparar(s, juegos: juegos, episodiosCinturon: delCinturon);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colores.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_fechaHora(s.inicio), style: Textos.cuerpoDestacado)),
              if (s.interrumpida)
                const Text('Interrumpida',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colores.ambar)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Duración ${_t(s.duracion.inMilliseconds)} · ${s.lecturas} lecturas · '
            'con datos ${_t(fijo.msMonitoreado)} · sin conexión ${_t(fijo.msSinConexion)} · '
            'jugando ${_t(fijo.msJugando)} (descontado)',
            style: Textos.secundario,
          ),
          const SizedBox(height: 4),
          Text(
            'Estimación del apoderado: ${s.estimacionApoderado ?? 'no se preguntó'}',
            style: Textos.secundario.copyWith(color: Colores.bosque),
          ),
          const Divider(height: 20, color: Colores.linea),
          _criterio('Fijo (umbral del cinturón)', fijo),
          const SizedBox(height: 10),
          if (cal == null)
            const Text('Calibrado: el participante no tenía calibración en esta sesión.',
                style: Textos.secundario)
          else
            _criterio('Calibrado (desde su postura neutral)', cal),
          const Divider(height: 20, color: Colores.linea),
          Text(
            validacion == null
                ? 'Validación: el cinturón no registró episodios en esta sesión '
                    '(o aún no se sincroniza su cola).'
                : 'Validación (${validacion.criterio == Criterio.fijo ? 'fijo' : 'calibrado'}, con conexión): '
                    'el cinturón registró ${validacion.cinturon} · la app calculó ${validacion.app}'
                    '${validacion.cinturon == validacion.app ? ' ✓' : ''}',
            style: Textos.secundario.copyWith(color: Colores.azul),
          ),
        ],
      ),
    );
  }

  Widget _criterio(String nombre, ResumenMonitoreo r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, style: Textos.cuerpoDestacado),
        Text(
          '${r.veces} veces${r.vecesDelCinturon > 0 ? ' (${r.vecesDelCinturon} del cinturón, en cortes)' : ''} · en mala postura ${_t(r.msMalaPostura)} · la más larga ${_t(r.msMasLargo)}\n'
          'adelante ${_t(r.msAdelante)} · lateral ${_t(r.msLateral)} · ambos ${_t(r.msAmbos)}',
          style: Textos.secundario,
        ),
      ],
    );
  }

  static String _t(int ms) {
    final s = (ms / 1000).round();
    if (s < 60) return '$s s';
    return '${s ~/ 60} min ${s % 60} s';
  }

  static String _fechaHora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)}-${d.year}  ${dos(d.hour)}:${dos(d.minute)}';
  }
}
