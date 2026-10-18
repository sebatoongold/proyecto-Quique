// ============================================================
// registro_juegos_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F2
//
// CAMBIOS v4 respecto a la v3:
//  - Cada juego muestra con qué PARÁMETROS se jugó (la variante), si
//    los tiene (los juegos anteriores a F2 no).
//
// Herramienta del diseñador (Configuración → Datos de prueba): todas
// las métricas crudas de cada juego.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/parametros_juego.dart';
import '../../modelos/registro_juego.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class RegistroJuegosScreen extends StatefulWidget {
  const RegistroJuegosScreen({super.key});

  @override
  State<RegistroJuegosScreen> createState() => _RegistroJuegosScreenState();
}

class _RegistroJuegosScreenState extends State<RegistroJuegosScreen> {
  late Future<List<RegistroJuego>> _registros = AlmacenamientoJuegos.cargarDelActivo();
  // Participante cuyos juegos se muestran (null = sin participante).
  final String? _codigo = ServicioParticipantes.instancia.activo.value?.codigo;

  Future<void> _borrarTodo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_codigo == null
            ? '¿Borrar los juegos sin participante?'
            : '¿Borrar los juegos de $_codigo?'),
        content: const Text('Esto no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmar != true) return;
    await AlmacenamientoJuegos.borrarDe(_codigo);
    setState(() => _registros = AlmacenamientoJuegos.cargarDelActivo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Juegos · ${_codigo ?? 'sin participante'}'),
        actions: [
          IconButton(
            tooltip: 'Borrar estos juegos',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _borrarTodo,
          ),
        ],
      ),
      body: FutureBuilder<List<RegistroJuego>>(
        future: _registros,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snap.data!.reversed.toList(); // más reciente primero
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay juegos. Juega una vez en el mundo del niño y vuelve aquí.',
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
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _tarjeta(lista[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjeta(RegistroJuego r) {
    final estado = r.completado
        ? 'Completado'
        : (r.interrumpido ? 'Interrumpido' : 'Intentado');
    final colorEstado = r.completado ? Colores.comodo : Colores.ambar;
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
              Expanded(child: Text(_fechaHora(r.inicio), style: Textos.cuerpoDestacado)),
              Text(estado, style: TextStyle(fontWeight: FontWeight.w700, color: colorEstado)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Duración: ${_seg(r.duracion.inMilliseconds / 1000)} · '
            'Poses completadas: ${r.posesCompletadas} de ${r.poses.length} · '
            'Postura cero: adelante ${r.ceroAdelante.toStringAsFixed(0)}, lado ${r.ceroLateral.toStringAsFixed(0)}',
            style: Textos.secundario,
          ),
          if (r.parametros != null) ...[
            const SizedBox(height: 4),
            Text(_variante(ParametrosJuego.desdeJson(r.parametros!)),
                style: Textos.secundario.copyWith(color: Colores.bosque)),
          ],
          const Divider(height: 20, color: Colores.linea),
          for (final p in r.poses) ...[
            Text('${p.indice + 1}. ${p.instruccion} — ${p.resultado}', style: Textos.cuerpoDestacado),
            Text(
              'Entró a la zona: ${p.segundosHastaEntrar == null ? 'nunca' : _seg(p.segundosHastaEntrar!)} · '
              'Completó en: ${p.segundosHastaCompletar == null ? '—' : _seg(p.segundosHastaCompletar!)} · '
              'Salidas: ${p.salidasDeZona} · Pistas: ${p.pistasUsadas} · Ayudas: ${p.ayudasOfrecidas}',
              style: Textos.secundario,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Resumen de la variante, ej.: "Variante: ángulo 18 · margen ±9 · …".
  static String _variante(ParametrosJuego p) =>
      'Variante: ángulo ${p.anguloLateral.round()} · margen ±${p.margenLateral.round()} · '
      'adelante ±${p.margenAdelante.round()}/±${p.margenAdelanteCentro.round()} · '
      'mantener ${p.segundosMantener.round()} s · pista ${p.segundosPista.round()} s · '
      'ayuda ${p.segundosAyuda.round()} s · espejo ${p.espejo ? 'sí' : 'no'} · '
      '×${p.amplificacion.toStringAsFixed(1)}';

  static String _seg(double s) => '${s.toStringAsFixed(1).replaceAll('.', ',')} s';

  static String _fechaHora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)}-${d.year}  ${dos(d.hour)}:${dos(d.minute)}';
  }
}
