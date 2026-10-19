// ============================================================
// barra_mundos.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F4
//
// CAMBIOS v2 respecto a la v1:
//  - Anota en el registro de uso cada intento de la puerta parental:
//    "corto" (un toque), "soltada" (se soltó antes de tiempo) u "ok".
//
// La barra inferior cambia de MUNDO (no de sección):
//  - De Apoderado a Niño: un toque, cambio directo.
//  - De Niño a Apoderado: hay que MANTENER PRESIONADO el botón
//    (puerta parental). Un anillo se llena mientras se mantiene; si se
//    suelta antes, vuelve a cero. Un toque corto muestra una pista
//    pensada para el adulto.
// ============================================================

import 'package:flutter/material.dart';

import '../servicios/registro_uso.dart';
import '../tema/colores.dart';

// ---------- PARÁMETRO AJUSTABLE ----------
// Cuánto hay que mantener presionado para entrar al mundo apoderado.
// Más largo = más difícil para un niño entrar sin querer.
const Duration duracionPuertaParental = Duration(seconds: 3);

enum Mundo { nino, apoderado }

class BarraMundos extends StatefulWidget {
  final Mundo actual;
  final ValueChanged<Mundo> alCambiar;

  const BarraMundos({super.key, required this.actual, required this.alCambiar});

  @override
  State<BarraMundos> createState() => _BarraMundosState();
}

class _BarraMundosState extends State<BarraMundos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _puerta = AnimationController(
    vsync: this,
    duration: duracionPuertaParental,
  )..addStatusListener((estado) {
      if (estado == AnimationStatus.completed) {
        RegistroUso.anotar('puerta_intento', dato: 'ok');
        _puerta.reset();
        widget.alCambiar(Mundo.apoderado);
      }
    });

  @override
  void dispose() {
    _puerta.dispose();
    super.dispose();
  }

  void _soltar() {
    if (_puerta.isCompleted) return;
    RegistroUso.anotar('puerta_intento', dato: _puerta.value < 0.15 ? 'corto' : 'soltada');
    // Toque corto: probablemente alguien no sabe que hay que mantener.
    if (_puerta.value < 0.15) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Para el apoderado: mantén presionado '
              '${duracionPuertaParental.inSeconds} segundos.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }
    _puerta.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enNino = widget.actual == Mundo.nino;

    return Container(
      decoration: const BoxDecoration(
        color: Colores.tarjeta,
        border: Border(top: BorderSide(color: Colores.linea)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              Expanded(
                child: _item(
                  icono: Icons.child_care_rounded,
                  texto: 'Niño',
                  activo: enNino,
                  colorActivo: Colores.bosque,
                  alTocar: enNino ? null : () => widget.alCambiar(Mundo.nino),
                ),
              ),
              Expanded(
                child: enNino
                    ? _puertaParental()
                    : _item(
                        icono: Icons.person_rounded,
                        texto: 'Apoderado',
                        activo: true,
                        colorActivo: Colores.azul,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icono,
    required String texto,
    required bool activo,
    required Color colorActivo,
    VoidCallback? alTocar,
  }) {
    final color = activo ? colorActivo : Colores.textoSecundario;
    return InkWell(
      onTap: alTocar,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: activo ? colorActivo.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 2),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 12.5,
                  color: color,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón "Apoderado" visto desde el mundo niño: gris, con candado, y
  /// un anillo que se llena mientras se mantiene presionado.
  Widget _puertaParental() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _puerta.forward(),
      onTapUp: (_) => _soltar(),
      onTapCancel: _soltar,
      child: AnimatedBuilder(
        animation: _puerta,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _puerta.value,
                        strokeWidth: 3,
                        color: Colores.azul,
                        backgroundColor: Colors.transparent,
                      ),
                      const Icon(Icons.lock_rounded,
                          color: Colores.incomodo, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Apoderado',
                  style: TextStyle(fontSize: 12.5, color: Colores.incomodo),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
