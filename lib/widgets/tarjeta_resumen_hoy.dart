// ============================================================
// tarjeta_resumen_hoy.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso F7.3
//
// CAMBIOS v3 respecto a la v2:
//  - Ya NO hay que iniciar ni terminar nada: el resumen muestra TODO EL
//    DÍA con lo que registró el cinturón (su cola), como hará el
//    producto real. El apoderado no tiene que estar pendiente de cuándo
//    el niño tiene puesto el cinturón.
//  - El "monitoreo" con la pregunta de estimación pasó a ser una
//    herramienta del investigador: Configuración → Periodo de
//    observación (observacion_screen.dart).
//  - Tocar la tarjeta abre el Historial en la pestaña Postura (la línea
//    de tiempo del día).
//  - Debajo dice cuándo se actualizó por última vez (los datos llegan
//    cuando la app lee la cola del cinturón).
//
// Muestra las VECES que se encorvó o inclinó (episodios de más de 3 s
// fuera de los juegos), y en segundo plano el tiempo total, la más
// larga y la dirección.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/registro_juego.dart';
import '../screens/apoderado/historial_screen.dart';
import '../servicios/almacenamiento_juegos.dart';
import '../servicios/analisis_postura.dart';
import '../servicios/servicio_cinturon.dart';
import '../servicios/servicio_participantes.dart';
import '../tema/colores.dart';
import '../tema/tema_app.dart';
import 'linea_tiempo_postura.dart';

class TarjetaResumenHoy extends StatefulWidget {
  const TarjetaResumenHoy({super.key});

  @override
  State<TarjetaResumenHoy> createState() => _TarjetaResumenHoyState();
}

class _TarjetaResumenHoyState extends State<TarjetaResumenHoy> {
  final _cinturon = ServicioCinturon.instancia;
  List<RegistroJuego> _juegos = const [];

  @override
  void initState() {
    super.initState();
    _cinturon.episodios.addListener(_refrescar);
    _cinturon.ultimaSincronizacion.addListener(_refrescar);
    ServicioParticipantes.instancia.activo.addListener(_cargarJuegos);
    _cargarJuegos();
  }

  @override
  void dispose() {
    _cinturon.episodios.removeListener(_refrescar);
    _cinturon.ultimaSincronizacion.removeListener(_refrescar);
    ServicioParticipantes.instancia.activo.removeListener(_cargarJuegos);
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarJuegos() async {
    final j = await AlmacenamientoJuegos.cargarDelActivo();
    if (mounted) setState(() => _juegos = j);
  }

  @override
  Widget build(BuildContext context) {
    final codigo = ServicioParticipantes.instancia.activo.value?.codigo;
    final hoy = AnalisisPostura.delDia(
      DateTime.now(),
      episodios: _cinturon.de(codigo),
      juegos: _juegos,
    );
    final ultima = _cinturon.ultimaSincronizacion.value;
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistorialScreen(inicial: SeccionHistorial.postura)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(child: Text('Resumen de hoy', style: Textos.tituloTarjeta)),
                  Icon(Icons.chevron_right_rounded, color: Colores.azul),
                ],
              ),
              const SizedBox(height: 10),
              if (hoy.episodios.isEmpty)
                const Text(
                  'Todavía no hay registros hoy. Cuando use el cinturón cerca del teléfono, '
                  'aparecerán aquí.',
                  style: Textos.secundario,
                )
              else ..._datos(hoy),
              const SizedBox(height: 10),
              Text(
                ultima == null ? 'Sin actualizar todavía' : 'Actualizado a las ${_hora(ultima)}',
                style: Textos.secundario.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _datos(PosturaDelDia hoy) {
    final veces = hoy.veces;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$veces', style: Textos.dato),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                veces == 1 ? 'vez se encorvó o se inclinó' : 'veces se encorvó o se inclinó',
                style: Textos.cuerpoDestacado,
              ),
            ),
          ),
        ],
      ),
      const Text('más de 3 segundos seguidos, en todo el día', style: Textos.secundario),
      if (veces > 0) ...[
        const SizedBox(height: 12),
        Text(
          'En total ${textoTiempo(hoy.msTotal)} · la más larga, ${textoTiempo(hoy.msMasLargo)}.',
          style: Textos.cuerpo,
        ),
        if (hoy.direccionDominante != null)
          Text('Sobre todo ${textoDireccion(hoy.direccionDominante!)}.', style: Textos.cuerpo),
      ],
    ];
  }

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
