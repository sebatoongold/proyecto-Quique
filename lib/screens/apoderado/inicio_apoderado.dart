// ============================================================
// inicio_apoderado.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v6 — paso F5
//
// CAMBIOS v6 respecto a la v5:
//  - La tarjeta "Resumen de hoy" ya no es provisoria: es la tarjeta
//    real del monitoreo (widgets/tarjeta_resumen_hoy.dart), con el
//    botón para iniciar y terminar el monitoreo. Era el pendiente del
//    antiguo paso C5.
//
// Esqueleto del dashboard del apoderado: encabezado, participante,
// estado de conexión real, actividad sugerida e Historial.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/participante.dart';
import '../../servicios/servicio_ble.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/tarjeta_resumen_hoy.dart';
import 'configuracion_screen.dart';
import 'historial_screen.dart';
import 'participantes_screen.dart';

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
    final ble = ServicioBle.instancia;
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(_fechaDeHoy(), style: Textos.secundario),
                const SizedBox(height: 4),
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
                const SizedBox(height: 6),
                _lineaParticipante(context, activo),
                const SizedBox(height: 4),
                // Estado de conexión real, se actualiza solo.
                ValueListenableBuilder<EstadoConexion>(
                  valueListenable: ble.estado,
                  builder: (context, estado, _) {
                    final conectado = estado == EstadoConexion.conectado;
                    return Row(
                      children: [
                        Icon(Icons.circle,
                            size: 9,
                            color: conectado ? Colores.comodo : Colores.ambar),
                        const SizedBox(width: 6),
                        Text(
                          conectado ? 'Wearable conectado' : 'Buscando el wearable…',
                          style: Textos.secundario,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Resumen de hoy: monitoreo real del participante activo.
                const TarjetaResumenHoy(),
                const SizedBox(height: 14),
                // Actividad sugerida: el único bloque en verde bosque.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colores.bosque,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actividad sugerida',
                        style: TextStyle(fontSize: 13, color: Colores.base),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Imita a Quique',
                        style: TextStyle(
                          fontFamily: fuenteTitulos,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colores.tarjeta,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colores.tarjeta,
                          foregroundColor: Colores.bosque,
                        ),
                        onPressed: alIrAlMundoNino,
                        child: Text(nombre == null ? 'Empezar' : 'Empezar con $nombre'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colores.tarjeta,
                  borderRadius: BorderRadius.circular(22),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    leading: const Icon(Icons.insights_rounded, color: Colores.azul),
                    title: const Text('Historial', style: Textos.cuerpoDestacado),
                    subtitle: const Text('Postura y juegos, semana a semana', style: Textos.secundario),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colores.azul),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistorialScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Participante activo (o aviso si no hay). Toca para cambiarlo.
  static Widget _lineaParticipante(BuildContext context, Participante? activo) {
    final hay = activo != null;
    final texto = activo != null
        ? 'Participante ${activo.codigo} · ${activo.edadTexto}'
        : 'Sin participante: los juegos no quedarán a nombre de nadie';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParticipantesScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              hay ? Icons.badge_rounded : Icons.warning_amber_rounded,
              size: 16,
              color: hay ? Colores.neutro : Colores.ambar,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(texto, style: Textos.secundario),
            ),
          ],
        ),
      ),
    );
  }

  /// Ej.: "Domingo 11 de octubre"
  static String _fechaDeHoy() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final hoy = DateTime.now();
    return '${dias[hoy.weekday - 1]} ${hoy.day} de ${meses[hoy.month - 1]}';
  }
}
