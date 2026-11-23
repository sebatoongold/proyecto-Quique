// ============================================================
// historia_screen.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// HISTORIA: el viaje de Sóma como un camino de norte a sur. Cada
// capítulo muestra su estado:
//   visto      ✓ (se puede volver a ver)
//   nuevo      abierto pero sin ver: borde ámbar y "¡Nuevo!"
//   bloqueado  candado y cuánta experiencia necesita
//   próximamente  visible, sin abrir (despierta curiosidad)
// Arriba, la barra de experiencia hasta el próximo capítulo.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/historia.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_progreso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/barra_experiencia.dart';
import '../../widgets/icono_animal.dart';
import 'capitulo_screen.dart';

class HistoriaScreen extends StatelessWidget {
  const HistoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.arena,
      appBar: AppBar(backgroundColor: Colores.arena, title: const Text('El viaje de Sóma')),
      body: ValueListenableBuilder<int>(
        valueListenable: ServicioProgreso.instancia.cambios,
        builder: (context, _, __) {
          final progreso = ServicioProgreso.instancia.actual;
          final par = ServicioParametros.instancia.actual.value;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  const BarraExperiencia(),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Norte', style: Textos.secundario),
                  ),
                  for (final c in capitulosHistoria)
                    _filaCapitulo(
                      context,
                      c,
                      abierto: !c.proximamente && progreso.xp >= c.xpNecesaria(par),
                      visto: progreso.capitulosVistos.contains(c.id),
                      xpNecesaria: c.xpNecesaria(par),
                    ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Sur', style: Textos.secundario),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaCapitulo(
    BuildContext context,
    Capitulo c, {
    required bool abierto,
    required bool visto,
    required int xpNecesaria,
  }) {
    final nuevo = abierto && !visto;
    final colorTexto = abierto ? Colores.azul : Colores.neutro;
    final String detalle;
    if (c.proximamente) {
      detalle = c.lugar.nombre;
    } else if (abierto) {
      detalle = c.lugar.nombre;
    } else {
      detalle = '${c.lugar.nombre} · $xpNecesaria XP';
    }

    // Círculo del camino: animal (abierto), ✓ prólogo, candado o "?".
    Widget circulo;
    if (abierto && c.animal != null) {
      circulo = IconoAnimal(animal: c.animal!, tamano: 46);
    } else {
      circulo = CircleAvatar(
        radius: 23,
        backgroundColor: abierto ? Colores.tarjeta : Colores.fondo,
        child: Icon(
          c.proximamente
              ? Icons.question_mark_rounded
              : abierto
                  ? Icons.home_rounded
                  : Icons.lock_rounded,
          color: abierto ? Colores.bosqueClaro : Colores.neutro,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El camino: una línea punteada con el círculo encima.
          SizedBox(
            width: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 4, color: Colores.base),
                circulo,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Opacity(
                opacity: abierto ? 1 : 0.6,
                child: Material(
                  color: abierto ? Colores.tarjeta : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: abierto
                        ? () {
                            RegistroUso.anotar('historia', dato: c.id);
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CapituloScreen(capitulo: c)));
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: nuevo ? Colores.ambar : Colores.linea, width: nuevo ? 2.5 : 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.etiqueta.toUpperCase(),
                                    style: Textos.secundario.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                                Text(c.titulo,
                                    style: TextStyle(
                                        fontFamily: fuenteTitulos,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: colorTexto)),
                                Text(detalle, style: Textos.secundario.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (visto) const Icon(Icons.check_circle_rounded, color: Colores.comodo),
                          if (nuevo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: Colores.ambar, borderRadius: BorderRadius.circular(10)),
                              child: const Text('¡Nuevo!',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colores.azul)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
