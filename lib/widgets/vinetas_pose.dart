// ============================================================
// vinetas_pose.dart
// Fecha: 12-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso E (lenguaje de cómic)
//
// CAMBIOS v2 respecto a la v1:
//  - Viñeta 2: figura fantasma de la posición de partida + flecha curva
//    hacia donde hay que moverse (de dónde viene y hacia dónde va).
//  - Viñeta 3: marcas de "quieto" junto a la cabeza (mantener la pose).
//  - Sin los puntos de los sensores: las viñetas son el ejemplo, no el niño.
//
// Tres viñetas que muestran cómo llegar a la pose: cómo empezar, el
// movimiento a medio camino, y la pose final. Sin animación (decisión
// del flujo: se pueden volver a mirar y son rápidas de producir).
//
// PROVISORIO: las viñetas usan la misma figura dibujada en código que
// la figura «Tú». Cuando existan las ilustraciones de Quique, se
// reemplaza el contenido de cada viñeta por su dibujo.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/pose.dart';
import '../tema/colores.dart';
import 'figura_tu.dart';

// Textos bajo cada viñeta (cortos, para el niño).
const List<String> textosVinetas = ['Empieza así', 'Muévete despacito', '¡Quédate así!'];

class VinetasPose extends StatelessWidget {
  final Pose pose;
  final double lateralInicio; // de dónde parte (la pose anterior, o 0)
  final double adelanteInicio;

  const VinetasPose({
    super.key,
    required this.pose,
    this.lateralInicio = 0,
    this.adelanteInicio = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _vineta(i)),
        ],
      ],
    );
  }

  Widget _vineta(int i) {
    // 0 = inicio, 0.5 = a medio camino, 1 = pose final.
    final t = i / 2;
    final lateral = lateralInicio + (pose.lateral - lateralInicio) * t;
    final adelante = adelanteInicio + (pose.adelante - adelanteInicio) * t;
    final esFinal = i == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colores.azul, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${i + 1}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colores.ambar),
          ),
          Expanded(
            child: FiguraTu(
              adelante: adelante,
              lateral: lateral,
              siluetaAdelante: 0,
              siluetaLateral: 0,
              color: esFinal ? Colores.comodo : Colores.azul,
              mostrarSilueta: false,
              mostrarSensores: false,
              // Viñeta 2: de dónde viene (fantasma) y hacia dónde va (flecha).
              fantasmaLateral: i == 1 ? lateralInicio : null,
              flechaDesde: i == 1 ? lateralInicio : null,
              flechaHasta: i == 1 ? pose.lateral : null,
              // Viñeta 3: "¡quédate así!".
              marcasQuieto: esFinal,
            ),
          ),
          Text(
            textosVinetas[i],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colores.azul),
          ),
        ],
      ),
    );
  }
}
