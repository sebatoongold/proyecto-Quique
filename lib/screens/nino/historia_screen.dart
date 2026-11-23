// ============================================================
// historia_screen.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v2 — paso G5
//
// CAMBIOS v2 respecto a la v1:
//  - Los tres estados se distinguen por COLOR DE FONDO, con la paleta
//    ajustada (ya no con transparencia):
//      abierto        tarjeta Crema banda
//      bloqueado      bloque Arena, candado y textos en Gris pizarra
//      próximamente   sin relleno, solo borde Arena
//  - "Nuevo" pasa de ámbar a BOSQUE (borde y etiqueta): el ámbar queda
//    solo para el estado de Sóma. El ✓ de "visto" también en Bosque.
//
// HISTORIA: el viaje de Sóma como un camino de norte a sur. Cada
// capítulo muestra su estado:
//   visto      ✓ (se puede volver a ver)
//   nuevo      abierto pero sin ver: borde Bosque y "¡Nuevo!"
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
    final bloqueado = !abierto && !c.proximamente;
    final colorTexto = abierto ? Colores.azul : Colores.textoSecundario;
    // Fondo de la tarjeta según el estado (ver encabezado).
    final Color fondoTarjeta = abierto
        ? Colores.cremaBanda
        : bloqueado
            ? Colores.arenaPaleta
            : Colors.transparent;
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
        backgroundColor: abierto ? Colores.cremaBanda : (bloqueado ? Colores.arenaPaleta : Colores.fondo),
        child: Icon(
          c.proximamente
              ? Icons.question_mark_rounded
              : abierto
                  ? Icons.home_rounded
                  : Icons.lock_rounded,
          color: abierto ? Colores.bosque : Colores.textoSecundario,
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
                opacity: 1,
                child: Material(
                  color: fondoTarjeta,
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
                        border: Border.all(
                            color: nuevo ? Colores.bosque : Colores.arenaPaleta, width: nuevo ? 2.5 : 1.5),
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
                                if (bloqueado)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(children: const [
                                      Icon(Icons.lock_rounded, size: 13, color: Colores.textoSecundario),
                                      SizedBox(width: 4),
                                      Text('Se abre con más experiencia', style: Textos.pequeno),
                                    ]),
                                  ),
                              ],
                            ),
                          ),
                          if (visto) const Icon(Icons.check_circle_rounded, color: Colores.bosque),
                          if (nuevo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: Colores.bosque, borderRadius: BorderRadius.circular(10)),
                              child: const Text('¡Nuevo!',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colores.cremaBanda)),
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
