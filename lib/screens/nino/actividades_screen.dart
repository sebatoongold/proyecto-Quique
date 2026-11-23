// ============================================================
// actividades_screen.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// ACTIVIDADES del mundo niño: los dos juegos de siempre, ahora un nivel
// más adentro (desde la tarjeta "Actividades" del inicio). Cada tarjeta
// muestra la figura del juego, su nombre, los animales que aparecen y
// la experiencia que da al terminarlo.
//
// Desde aquí los juegos NO dan fotos de animales: las fotos se ganan
// ayudando a Sóma desde un capítulo de la historia.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/animal_postura.dart';
import '../../modelos/juego.dart';
import '../../modelos/pose.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_progreso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/figura_tu.dart';
import '../../widgets/icono_animal.dart';
import 'ejecucion_screen.dart';

class ActividadesScreen extends StatelessWidget {
  const ActividadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.arena,
      appBar: AppBar(
        backgroundColor: Colores.arena,
        title: const Text('Actividades'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Elige con qué ayudar a Sóma', style: Textos.secundario),
              ),
              for (final j in juegosDisponibles) ...[
                _tarjetaJuego(context, j),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de un juego: figura + nombre + descripción + animales + XP.
  Widget _tarjetaJuego(BuildContext context, Juego j) {
    final frontal = j.esFrontal;
    final p = ServicioParametros.instancia.actual.value;
    // Los animales del juego, sin repetir, en el orden en que aparecen.
    final animales = <AnimalPostura>[];
    for (final pose in j.poses(p)) {
      if (!animales.contains(pose.animal)) animales.add(pose.animal);
    }
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          RegistroUso.anotar('juego_desde', dato: 'boton_jugar');
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => EjecucionScreen(juego: j)));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colores.fondo, shape: BoxShape.circle),
                    child: FiguraTu(
                      adelante: frontal ? 30 : 0,
                      lateral: frontal ? 0 : -14,
                      siluetaAdelante: 0,
                      siluetaLateral: 0,
                      color: Colores.bosque,
                      mostrarSilueta: false,
                      mostrarSensores: false,
                      mostrarSilla: false,
                      vista: j.vista,
                      brazos: frontal ? ModoBrazos.abrazo : ModoBrazos.apoyados,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(j.nombreSinViuda,
                            style: const TextStyle(
                                fontFamily: fuenteTitulos,
                                fontSize: 18,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: Colores.azul)),
                        const SizedBox(height: 4),
                        Text(j.descripcionSinViuda, style: Textos.secundario),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill_rounded, color: Colores.bosque, size: 36),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final a in animales) ...[
                    IconoAnimal(animal: a, tamano: 28),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colores.ambar.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('+$xpActividad XP',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colores.azul)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
