// ============================================================
// inicio_apoderado.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso C3 (inicio provisorio del mundo apoderado)
//
// Esqueleto del dashboard: encabezado, estado de conexión real y la
// actividad sugerida. El resumen de hoy, la comparación y el progreso
// del niño llegan en el paso C5 (con datos de ejemplo).
// El engranaje abre, por ahora, "Datos del sensor" (pantalla de prueba);
// más adelante abrirá Configuración.
// ============================================================

import 'package:flutter/material.dart';

import '../../datos_ejemplo.dart';
import '../../servicios/servicio_ble.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../postura_screen.dart';

class InicioApoderado extends StatelessWidget {
  final VoidCallback alIrAlMundoNino;

  const InicioApoderado({super.key, required this.alIrAlMundoNino});

  @override
  Widget build(BuildContext context) {
    final ble = ServicioBle.instancia;

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
                    const Expanded(
                      child: Text('Hoy con $nombreNinoEjemplo', style: Textos.titulo),
                    ),
                    IconButton(
                      tooltip: 'Datos del sensor',
                      icon: const Icon(Icons.settings_rounded, color: Colores.azul),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PosturaScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                _tarjeta(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen de hoy', style: Textos.tituloTarjeta),
                      SizedBox(height: 8),
                      Text(
                        'Aquí irá el resumen del día (paso C5).',
                        style: Textos.secundario,
                      ),
                    ],
                  ),
                ),
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
                        child: const Text('Empezar con $nombreNinoEjemplo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _tarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
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
