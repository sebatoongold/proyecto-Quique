// ============================================================
// registro_juegos_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v6 — paso F4
//
// CAMBIOS v6 respecto a la v5:
//  - Cada pose muestra el ANÁLISIS DE SU RECORRIDO (primer movimiento,
//    si se pasó de largo, si llegó cerca sin entrar, si las pistas
//    sirvieron, tiempo en las viñetas) y un GRÁFICO del recorrido con
//    la zona de la pose y las pistas. Usa los umbrales de Parámetros →
//    Análisis de recorridos.
//  - Si el juego quedó interrumpido, dice dónde abandonó.
//  - Botón "Eventos" en cada juego: la línea de eventos con sus horas.
//
// Herramienta del diseñador (Configuración → Datos de prueba): todas
// las métricas crudas de cada juego.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/parametros_juego.dart';
import '../../modelos/registro_juego.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/analisis_recorrido.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/grafico_recorrido.dart';

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
            'Postura cero${_tipoCero(r.tipoCero)}: adelante ${r.ceroAdelante.toStringAsFixed(0)}, lado ${r.ceroLateral.toStringAsFixed(0)}',
            style: Textos.secundario,
          ),
          if (AnalisisRecorrido.dondeAbandono(r) != null)
            Text('Abandonó en: ${AnalisisRecorrido.dondeAbandono(r)}',
                style: Textos.secundario.copyWith(color: Colores.ambar)),
          if (r.eventos.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.list_rounded, size: 18),
                label: Text('Eventos (${r.eventos.length})'),
                onPressed: () => _verEventos(r),
              ),
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
            ..._analisis(r, p),
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

  static String _tipoCero(String? t) => switch (t) {
        'calibrado' => ' (calibrada)',
        'automatico' => ' (automática)',
        'automatico_sin_calibracion' => ' (automática: no tenía calibración)',
        _ => '',
      };

  /// Análisis y gráfico del recorrido de una pose (si lo tiene).
  List<Widget> _analisis(RegistroJuego r, MetricaPose p) {
    final a = AnalisisRecorrido.pose(r, p, ServicioParametros.instancia.actual.value);
    if (a == null) return const [];
    final primer = switch (a.primerMovimiento) {
      'correcto' => 'hacia la pose',
      'contrario' => 'AL REVÉS',
      'sin_movimiento' => 'no se movió',
      _ => '—',
    };
    // Pistas en ms desde "¡Vamos!" (para marcarlas en el gráfico).
    int? msVamos;
    for (final e in r.eventos) {
      if (e.tipo == 'vamos' && e.pose == p.indice) msVamos = e.ms;
    }
    final pistas = [
      if (msVamos != null)
        for (final e in r.eventos)
          if (e.tipo == 'pista' && e.pose == p.indice) e.ms - msVamos,
    ];
    return [
      const SizedBox(height: 4),
      Text(
        'Primer movimiento: $primer'
        '${a.segundosPrimerMovimiento == null ? '' : ' (a los ${_seg(a.segundosPrimerMovimiento!)})'} · '
        'Se pasó de largo: ${a.sePasoDeLargo ? 'sí' : 'no'} · '
        'Llegó cerca sin entrar: ${a.llegoCercaSinEntrar ? 'sí' : 'no'}'
        '${a.pistas == 0 ? '' : ' · Pistas que sirvieron: ${a.pistasQueSirvieron} de ${a.pistas}'}'
        '${a.segundosEnVineta == null ? '' : ' · En las viñetas: ${_seg(a.segundosEnVineta!)}'}',
        style: Textos.secundario.copyWith(
          color: a.primerMovimiento == 'contrario' ? Colores.ambar : Colores.azul,
        ),
      ),
      const SizedBox(height: 6),
      GraficoRecorrido(pose: p, ejeLateral: a.ejePrincipal == 'lateral', pistasMs: pistas),
      Text(
        'Eje ${a.ejePrincipal == 'lateral' ? 'lateral' : 'adelante/atrás'} · verde: zona de la pose · '
        'ámbar: pista',
        style: Textos.secundario.copyWith(fontSize: 11),
      ),
    ];
  }

  /// La línea de eventos de un juego, con sus horas.
  Future<void> _verEventos(RegistroJuego r) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eventos del juego'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final e in r.eventos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${_horaExacta(r.inicio.add(Duration(milliseconds: e.ms)))}  '
                      '${e.tipo}${e.pose == null ? '' : ' · pose ${e.pose! + 1}'}'
                      '${e.dato == null ? '' : ' · ${e.dato}'}',
                      style: Textos.cuerpo.copyWith(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        ),
      );

  static String _horaExacta(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.hour)}:${dos(d.minute)}:${dos(d.second)}';
  }

  static String _seg(double s) => '${s.toStringAsFixed(1).replaceAll('.', ',')} s';

  static String _fechaHora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)}-${d.year}  ${dos(d.hour)}:${dos(d.minute)}';
  }
}
