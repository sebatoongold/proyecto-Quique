// ============================================================
// tarjeta_resumen_hoy.dart
// Fecha: 29-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v5 — paso G1 (rediseño del Inicio del apoderado)
//
// CAMBIOS v5 respecto a la v4:
//  - Pasa a llamarse "ALERTAS DE HOY" (el nombre de la clase y del
//    archivo no cambian, para no tocar otras pantallas).
//  - ALTO FIJO (`altoTarjetaAlertas`): mide lo mismo con alertas y sin
//    alertas, así el Inicio no "salta" cuando llega la primera.
//  - CON ALERTAS, en dos columnas:
//      izquierda: el NÚMERO grande (`tamanoNumeroAlertas`) y "veces que
//                 se encorvó o se inclinó";
//      derecha:   la alerta MÁS RECIENTE con una figura que muestra
//                 hacia dónde fue (adelante = de costado; al lado o
//                 ambos = de frente) y, abajo, el TIEMPO TOTAL de hoy.
//  - SIN ALERTAS: un ✓ y "No se han registrado alertas el día de hoy".
//  - La flecha (se puede tocar) va arriba a la derecha.
//  - Se quitó la línea "Actualizado a las…": la hora de la última
//    actualización aparece en el aviso del Inicio solo si el cinturón
//    no está conectado (inicio_apoderado.dart).
//
// Al tocarla abre el Historial en Postura (para el registro de uso,
// sigue anotando el origen 'resumen_hoy').
//
// Cuenta los episodios de más de 3 s FUERA de los juegos, desde la
// cola del cinturón (analisis_postura.dart).
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/pose.dart';
import '../modelos/registro_juego.dart';
import '../screens/apoderado/historial_screen.dart';
import '../servicios/almacenamiento_juegos.dart';
import '../servicios/analisis_postura.dart';
import '../servicios/servicio_cinturon.dart';
import '../servicios/servicio_participantes.dart';
import '../tema/colores.dart';
import '../tema/tema_app.dart';
import 'figura_tu.dart';
import 'linea_tiempo_postura.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Alto de la tarjeta (igual con y sin alertas).
const double altoTarjetaAlertas = 190;
// Tamaño del número de alertas.
const double tamanoNumeroAlertas = 72;
// Cuánto se inclina la figura de "la más reciente" (unidades del
// sensor; solo dibujo: muestra la dirección, no el ángulo real).
const double inclinacionFiguraAlerta = 30;
// Tamaño de la figura de "la más reciente".
const double anchoFiguraAlerta = 56;
const double altoFiguraAlerta = 70;

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
    ServicioParticipantes.instancia.activo.addListener(_cargarJuegos);
    _cargarJuegos();
  }

  @override
  void dispose() {
    _cinturon.episodios.removeListener(_refrescar);
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
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const HistorialScreen(inicial: SeccionHistorial.postura, origen: 'resumen_hoy')),
        ),
        child: SizedBox(
          height: altoTarjetaAlertas,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Alertas de hoy',
                          style: Textos.secundario.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colores.azul, size: 28),
                  ],
                ),
                Expanded(child: hoy.veces == 0 ? _sinAlertas() : _conAlertas(hoy)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sinAlertas() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: Colores.comodo.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colores.comodo, size: 40),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text('No se han registrado alertas el día de hoy',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colores.azul)),
        ),
      ],
    );
  }

  Widget _conAlertas(PosturaDelDia hoy) {
    final veces = hoy.veces;
    final reciente = hoy.queCuentan.first; // la lista va de la más reciente a la más antigua
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Izquierda: el número ---
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('$veces',
                    style: const TextStyle(
                        fontSize: tamanoNumeroAlertas, height: 1, fontWeight: FontWeight.w700, color: Colores.azul)),
              ),
              const SizedBox(height: 6),
              Text(veces == 1 ? 'vez que se encorvó o se inclinó' : 'veces que se encorvó o se inclinó',
                  style: Textos.secundario.copyWith(fontSize: 13)),
            ],
          ),
        ),
        Container(width: 1.5, margin: const EdgeInsets.symmetric(horizontal: 12), color: Colores.linea),
        // --- Derecha: la más reciente y el tiempo total ---
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('La más reciente', style: Textos.secundario.copyWith(fontSize: 12.5)),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: anchoFiguraAlerta,
                      height: altoFiguraAlerta,
                      child: _figuraDireccion(reciente.direccion),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(textoDireccion(reciente.direccion),
                          style: Textos.cuerpoDestacado.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: Colores.azul),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text('${textoTiempo(hoy.msTotal)} en total',
                        style: Textos.cuerpoDestacado.copyWith(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Figura que muestra hacia dónde fue la alerta: adelante = de
  /// costado curvándose; al lado o ambos = de frente inclinándose.
  Widget _figuraDireccion(String direccion) {
    final adelante = direccion == 'adelante';
    return FiguraTu(
      adelante: adelante ? inclinacionFiguraAlerta : 0,
      lateral: adelante ? 0 : inclinacionFiguraAlerta,
      siluetaAdelante: 0,
      siluetaLateral: 0,
      color: Colores.azul,
      mostrarSilueta: false,
      mostrarSensores: false,
      mostrarSilla: adelante,
      vista: adelante ? VistaFigura.costado : VistaFigura.frente,
    );
  }
}
