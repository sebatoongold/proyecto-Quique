// ============================================================
// inicio_nino.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso C3 (inicio provisorio del mundo niño)
//
// Esqueleto: Quique (marcador provisorio) saluda y hay un botón grande
// para jugar. El juego llega en el paso C4; el mundo de Quique, los
// juegos de hoy y "Mi río" llegan en el paso C6.
// ============================================================

import 'package:flutter/material.dart';

import '../../datos_ejemplo.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class InicioNino extends StatelessWidget {
  const InicioNino({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colores.arena,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Marcador provisorio de Quique (se reemplaza por su ilustración).
                  const CircleAvatar(
                    radius: 56,
                    backgroundColor: Colores.quique,
                    child: Icon(Icons.sentiment_very_satisfied_rounded,
                        size: 64, color: Colores.quiqueClaro),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Hola, $nombreNinoEjemplo!',
                    textAlign: TextAlign.center,
                    style: Textos.titulo,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '¿Jugamos un ratito?',
                    textAlign: TextAlign.center,
                    style: Textos.cuerpo,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(64, 64)),
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: const Text('Jugar'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El juego llega en el paso C4.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
