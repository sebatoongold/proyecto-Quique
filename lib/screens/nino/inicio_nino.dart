// ============================================================
// inicio_nino.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v5 — paso F6.2
//
// CAMBIOS v5 respecto a la v4:
//  - En vez de un solo botón "Jugar", una TARJETA POR JUEGO (ver
//    modelos/juego.dart): «Imita a Quique» (hacia los lados, figura de
//    frente) y «De lo alto a lo bajo» (erguido y bolita, de costado).
//    Cada tarjeta muestra la figura en su vista, para que se reconozca
//    sin leer. Se sigue anotando "boton_jugar" en el registro de uso
//    (el juego elegido queda en el registro del juego).
//
// Inicio provisorio del niño: Quique (marcador) y los juegos.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/juego.dart';
import '../../modelos/participante.dart';
import '../../modelos/pose.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/figura_tu.dart';
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
                    radius: 46,
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
                  const SizedBox(height: 24),
                  for (final j in juegosDisponibles) ...[
                    _tarjetaJuego(context, j),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de un juego: la figura en su vista + nombre + "jugar".
  Widget _tarjetaJuego(BuildContext context, Juego j) {
    // Un ejemplo de la pose típica del juego, para reconocerlo sin leer.
    final frontal = j.esFrontal;
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        // El juego se abre a pantalla completa, sin la barra de mundos.
        onTap: () {
          RegistroUso.anotar('juego_desde', dato: 'boton_jugar');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EjecucionScreen(juego: j)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 86,
                child: FiguraTu(
                  adelante: frontal ? 30 : 0,
                  lateral: frontal ? 0 : -14,
                  siluetaAdelante: 0,
                  siluetaLateral: 0,
                  color: Colores.bosque,
                  mostrarSilueta: false,
                  mostrarSensores: false,
                  vista: j.vista,
                  brazos: frontal ? ModoBrazos.abrazo : ModoBrazos.apoyados,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.nombre, style: Textos.cuerpoDestacado.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(j.descripcion, style: Textos.secundario),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colores.bosque, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}
