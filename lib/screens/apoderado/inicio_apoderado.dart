// ============================================================
// inicio_apoderado.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v9 — paso G2b
//
// CAMBIOS v9 respecto a la v8:
//  - Actividad sugerida: título de 21 → 19 y título y descripción sin
//    "viudas" (la última línea nunca queda con una sola palabra).
//
// Inicio del apoderado: encabezado, avisos (solo si hay problema),
// alertas de hoy, actividad sugerida e Historial.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/juego.dart';
import '../../modelos/participante.dart';
import '../../modelos/pose.dart';
import '../../servicios/servicio_ble.dart';
import '../../servicios/servicio_cinturon.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/barra_mundos.dart';
import '../../widgets/figura_tu.dart';
import '../../widgets/tarjeta_resumen_hoy.dart';
import 'configuracion_screen.dart';
import 'historial_screen.dart';
import 'participantes_screen.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Diámetro del círculo con el ícono del juego en la actividad sugerida.
const double tamanoIconoActividad = 72;
// Juego que se sugiere (por ahora fijo; más adelante, según el día).
const Juego juegoSugerido = juegoImitaAQuique;
// Cuánto se inclina la figura del ícono (unidades; solo dibujo).
const double inclinacionIconoActividad = 22;

class InicioApoderado extends StatelessWidget {
  final VoidCallback alIrAlMundoNino;

  const InicioApoderado({super.key, required this.alIrAlMundoNino});

  @override
  Widget build(BuildContext context) {
    // Toda la pantalla se redibuja si cambia el participante activo.
    return ValueListenableBuilder<Participante?>(
      valueListenable: ServicioParticipantes.instancia.activo,
      builder: (context, activo, _) => _contenido(context, activo),
    );
  }

  Widget _contenido(BuildContext context, Participante? activo) {
    final nombre = activo?.nombreVisible;

    return Container(
      color: Colores.fondo,
      child: SafeArea(
        bottom: false,
        child: Center(
          // Responsive: en tablet el contenido queda centrado y legible.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24 + espacioBajoEsquinas),
              children: [
                // --- Encabezado ---
                Row(
                  children: [
                    Expanded(
                      child: Text(nombre == null ? 'Hoy' : 'Hoy con $nombre', style: Textos.titulo),
                    ),
                    IconButton(
                      tooltip: 'Configuración',
                      icon: const Icon(Icons.settings_rounded, color: Colores.azul),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
                      ),
                    ),
                  ],
                ),
                // --- Avisos: solo si hay un problema ---
                if (activo == null)
                  _aviso(
                    icono: Icons.badge_rounded,
                    texto: 'Sin participante elegido: toca para elegirlo',
                    alTocar: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParticipantesScreen()),
                    ),
                  ),
                _avisoConexion(),
                const SizedBox(height: 14),
                // --- Alertas de hoy (alto fijo) ---
                const TarjetaResumenHoy(),
                const SizedBox(height: 14),
                _actividadSugerida(),
                const SizedBox(height: 14),
                _historial(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Aviso de conexión: solo aparece si el cinturón NO está conectado.
  Widget _avisoConexion() {
    final ble = ServicioBle.instancia;
    return ValueListenableBuilder<EstadoConexion>(
      valueListenable: ble.estado,
      builder: (context, estado, _) {
        if (estado == EstadoConexion.conectado) return const SizedBox.shrink();
        return ValueListenableBuilder<DateTime?>(
          valueListenable: ServicioCinturon.instancia.ultimaSincronizacion,
          builder: (context, ultima, _) => _aviso(
            icono: Icons.bluetooth_disabled_rounded,
            texto: ultima == null
                ? 'Cinturón sin conexión'
                : 'Cinturón sin conexión · actualizado a las ${_hora(ultima)}',
          ),
        );
      },
    );
  }

  static Widget _aviso({required IconData icono, required String texto, VoidCallback? alTocar}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colores.ambar.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icono, size: 18, color: Colores.azul),
                const SizedBox(width: 8),
                Expanded(child: Text(texto, style: Textos.secundario.copyWith(color: Colores.azul))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Actividad sugerida: el único bloque en verde bosque. Toda la
  /// tarjeta se toca (sin botón); la flecha lo indica.
  Widget _actividadSugerida() {
    final juego = juegoSugerido;
    final costado = juego.vista == VistaFigura.costado;
    return Material(
      color: Colores.bosque,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: alIrAlMundoNino,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              // Ícono del juego: la figura haciendo el movimiento, con su flecha.
              Container(
                width: tamanoIconoActividad,
                height: tamanoIconoActividad,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colores.tarjeta, shape: BoxShape.circle),
                child: FiguraTu(
                  adelante: costado ? inclinacionIconoActividad : 0,
                  lateral: costado ? 0 : -inclinacionIconoActividad,
                  siluetaAdelante: 0,
                  siluetaLateral: 0,
                  color: Colores.bosque,
                  mostrarSilueta: false,
                  mostrarSensores: false,
                  mostrarSilla: false,
                  vista: juego.vista,
                  flechaDesde: 0,
                  flechaHasta: costado ? inclinacionIconoActividad : -inclinacionIconoActividad,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividad sugerida', style: TextStyle(fontSize: 13, color: Colores.base)),
                    const SizedBox(height: 2),
                    Text(
                      juego.nombreSinViuda,
                      style: const TextStyle(
                        height: 1.15,
                        fontFamily: fuenteTitulos,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colores.tarjeta,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(juego.descripcionSinViuda, style: const TextStyle(fontSize: 13, color: Colores.base)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colores.tarjeta, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Historial: dice qué se va a encontrar.
  Widget _historial(BuildContext context) {
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistorialScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colores.fondo, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.insights_rounded, color: Colores.azul, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historial', style: Textos.tituloTarjeta),
                    SizedBox(height: 2),
                    Text('Las alertas y los juegos de cada día, hora por hora', style: Textos.secundario),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colores.azul, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
