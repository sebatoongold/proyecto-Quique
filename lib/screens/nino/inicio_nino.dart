// ============================================================
// inicio_nino.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F4
//
// CAMBIOS v4 respecto a la v3:
//  - Anota en el registro de uso que el juego lo abrió el niño con
//    "Jugar".
//
// Inicio provisorio del niño: Quique (marcador) y el botón "Jugar".
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/participante.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import 'ejecucion_screen.dart';

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
                  ValueListenableBuilder<Participante?>(
                    valueListenable: ServicioParticipantes.instancia.activo,
                    builder: (context, activo, _) => Text(
                      activo == null ? '¡Hola!' : '¡Hola, ${activo.nombreVisible}!',
                      textAlign: TextAlign.center,
                      style: Textos.titulo,
                    ),
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
                    // El juego se abre a pantalla completa, sin la barra de mundos.
                    onPressed: () {
                      RegistroUso.anotar('juego_desde', dato: 'boton_jugar');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EjecucionScreen()),
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
