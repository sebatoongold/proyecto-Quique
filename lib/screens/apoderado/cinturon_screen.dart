// ============================================================
// cinturon_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F7.2 (el cinturón y su cola)
//
// Herramienta del INVESTIGADOR (Configuración → Cinturón):
//  - Conexión y a quién está ASIGNADO el cinturón.
//  - VERIFICACIÓN: la calibración que el cinturón dice tener cargada
//    (datos en vivo y cabecera del registro) vs. la que debería tener
//    el participante activo. Si no coinciden, botón para reenviarla.
//  - Su cola: cuántos episodios pendientes tiene y cuántos ha recibido
//    la app; botón para sincronizar ahora.
//  - "Vaciar la cola del cinturón" (BORRAR_TODO): para borrar las
//    pruebas antes del testeo. NO guarda lo pendiente.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/datos_postura.dart';
import '../../modelos/episodio_cinturon.dart';
import '../../servicios/servicio_ble.dart';
import '../../servicios/servicio_cinturon.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class CinturonScreen extends StatefulWidget {
  const CinturonScreen({super.key});

  @override
  State<CinturonScreen> createState() => _CinturonScreenState();
}

class _CinturonScreenState extends State<CinturonScreen> {
  final _cinturon = ServicioCinturon.instancia;
  final _ble = ServicioBle.instancia;
  bool _trabajando = false;

  late final Listenable _todo = Listenable.merge([
    _ble.estado,
    _ble.datos,
    _cinturon.config,
    _cinturon.estado,
    _cinturon.asignadoA,
    _cinturon.asignacionPendiente,
    _cinturon.episodios,
    _cinturon.ultimaSincronizacion,
    ServicioParticipantes.instancia.activo,
  ]);

  @override
  void initState() {
    super.initState();
    _ble.iniciar();
  }

  Future<void> _hacer(Future<Object?> Function() tarea) async {
    setState(() => _trabajando = true);
    await tarea();
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _vaciar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar la cola del cinturón?'),
        content: const Text(
          'Se borran en el cinturón los episodios que todavía no se han leído, '
          'SIN guardarlos. Úsalo para limpiar las pruebas antes del testeo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true) await _hacer(_cinturon.vaciarCinturon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinturón')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedBuilder(
            animation: _todo,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _conexion(),
                const SizedBox(height: 14),
                _asignacion(),
                const SizedBox(height: 14),
                _cola(),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    shape: const StadiumBorder(),
                    foregroundColor: Colores.azul,
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('Vaciar la cola del cinturón'),
                  onPressed: _ble.tieneRegistro && !_trabajando ? _vaciar : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta({required Widget child, Color? borde}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borde ?? Colores.linea, width: borde == null ? 1 : 2),
        ),
        child: child,
      );

  Widget _conexion() {
    final conectado = _ble.conectado;
    final conCola = _ble.tieneRegistro;
    return _tarjeta(
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: conectado ? Colores.comodo : Colores.ambar),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !conectado
                  ? 'Buscando el cinturón…'
                  : (conCola
                      ? 'Conectado · ${_cinturon.estado.value}'
                      : 'Conectado, pero este firmware no tiene cola de episodios'),
              style: Textos.cuerpo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _asignacion() {
    final activo = ServicioParticipantes.instancia.activo.value;
    final esperado = _cinturon.idCalEsperado();
    final DatosPostura? vivo = _ble.datos.value;
    final ConfigCinturon? cfg = _cinturon.config.value;
    final cargado = vivo?.cal ?? cfg?.idCal; // lo que el cinturón dice tener
    final coincide = cargado != null &&
        cargado == esperado &&
        _cinturon.asignadoA.value == activo?.codigo &&
        !_cinturon.asignacionPendiente.value;

    final descripcionEsperada = esperado == 0
        ? 'umbral fijo (sin calibración)'
        : 'calibración de ${activo?.codigo} (cal $esperado)';
    return _tarjeta(
      borde: _ble.conectado ? (coincide ? Colores.comodo : Colores.ambar) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asignación', style: Textos.tituloTarjeta),
          const SizedBox(height: 8),
          Text('Participante activo: ${activo?.codigo ?? 'ninguno'}', style: Textos.cuerpo),
          Text('Debería tener: $descripcionEsperada', style: Textos.cuerpo),
          Text(
            'Tiene cargado: ${cargado == null ? '— (sin leer)' : (cargado == 0 ? 'umbral fijo (cal 0)' : 'cal $cargado')}'
            '${cfg == null ? '' : ' · neutro ${cfg.neutroX.toStringAsFixed(1)} / ${cfg.neutroY.toStringAsFixed(1)}'
                ' · umbrales ${cfg.umbralAdelante.toStringAsFixed(0)} / ${cfg.umbralLateral.toStringAsFixed(0)}'}',
            style: Textos.secundario,
          ),
          const SizedBox(height: 8),
          Text(
            !_ble.conectado
                ? 'Se enviará al conectarse.'
                : (coincide ? '✓ El cinturón está listo para este participante.' : 'No coincide todavía.'),
            style: Textos.cuerpoDestacado.copyWith(color: coincide ? Colores.comodo : Colores.ambar),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: const Text('Enviar al cinturón'),
            onPressed: _ble.tieneRegistro && !_trabajando ? () => _hacer(_cinturon.asignarActivo) : null,
          ),
        ],
      ),
    );
  }

  Widget _cola() {
    final cfg = _cinturon.config.value;
    final activo = ServicioParticipantes.instancia.activo.value;
    final delActivo = _cinturon.de(activo?.codigo).length;
    final ultima = _cinturon.ultimaSincronizacion.value;
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cola de episodios', style: Textos.tituloTarjeta),
          const SizedBox(height: 8),
          Text('Pendientes en el cinturón: ${cfg?.pendientes ?? '—'}', style: Textos.cuerpo),
          Text(
            'Recibidos en la app: ${_cinturon.episodios.value.length} en total · '
            '$delActivo de ${activo?.codigo ?? 'sin participante'}',
            style: Textos.cuerpo,
          ),
          if (ultima != null)
            Text('Última sincronización: ${_hora(ultima)}', style: Textos.secundario),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 46),
              shape: const StadiumBorder(),
              foregroundColor: Colores.azul,
            ),
            icon: _trabajando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            label: const Text('Sincronizar ahora'),
            onPressed: _ble.tieneRegistro && !_trabajando ? () => _hacer(_cinturon.sincronizar) : null,
          ),
        ],
      ),
    );
  }

  static String _hora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.hour)}:${dos(d.minute)}:${dos(d.second)}';
  }
}
