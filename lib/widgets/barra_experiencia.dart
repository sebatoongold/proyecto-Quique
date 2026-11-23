// ============================================================
// barra_experiencia.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v2 — paso G5
//
// CAMBIOS v2 respecto a la v1:
//  - La barra va dentro de una TARJETA Crema banda (con borde Arena), así
//    se separa del fondo Tierra seca.
//  - El relleno pasa de ámbar a BOSQUE: el ámbar es un estado de Sóma
//    ("un poco incómodo") y no debe confundirse con la experiencia.
//  - Textos con los estilos de Textos (etiqueta / pequeño).
//
// "Explorador · 120 XP" y una barra hasta el PRÓXIMO capítulo de la
// historia ("faltan 30 para el Desierto de Atacama"). Se usa en el
// inicio del niño y en la pantalla Historia.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/historia.dart';
import '../servicios/servicio_parametros.dart';
import '../servicios/servicio_participantes.dart';
import '../servicios/servicio_progreso.dart';
import '../tema/colores.dart';
import '../tema/tema_app.dart';

/// El próximo capítulo que se abrirá con más experiencia (o null si ya
/// están todos abiertos).
Capitulo? proximoCapitulo(int xp) {
  final p = ServicioParametros.instancia.actual.value;
  for (final c in capitulosHistoria) {
    if (!c.proximamente && xp < c.xpNecesaria(p)) return c;
  }
  return null;
}

// ---------- PARÁMETROS AJUSTABLES ----------
// Alto de la barra de avance y redondeo de su tarjeta.
const double altoBarraExperiencia = 10;
const double radioTarjetaExperiencia = 14;

class BarraExperiencia extends StatelessWidget {
  const BarraExperiencia({super.key});

  @override
  Widget build(BuildContext context) {
    // Se escucha a sí misma: así se actualiza aunque se use como `const`.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ServicioProgreso.instancia.cambios,
        ServicioParametros.instancia.actual,
        ServicioParticipantes.instancia.activo,
      ]),
      builder: (context, _) => _barra(),
    );
  }

  Widget _barra() {
    final xp = ServicioProgreso.instancia.actual.xp;
    final p = ServicioParametros.instancia.actual.value;
    final proximo = proximoCapitulo(xp);
    // Avance desde el capítulo anterior hasta el próximo.
    double avance = 1;
    String falta = '¡Abriste todo el viaje!';
    if (proximo != null) {
      final anterior = capitulosHistoria
          .where((c) => !c.proximamente && c.numero < proximo.numero)
          .map((c) => c.xpNecesaria(p))
          .fold<int>(0, (a, b) => b > a ? b : a);
      final meta = proximo.xpNecesaria(p);
      avance = meta <= anterior ? 1 : ((xp - anterior) / (meta - anterior)).clamp(0.0, 1.0).toDouble();
      falta = 'faltan ${meta - xp} para ${proximo.lugar.nombre}';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colores.cremaBanda,
        borderRadius: BorderRadius.circular(radioTarjetaExperiencia),
        border: Border.all(color: Colores.arenaPaleta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Explorador · $xp XP',
                  style: Textos.cuerpoDestacado.copyWith(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(falta,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Textos.pequeno),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: avance,
              minHeight: altoBarraExperiencia,
              color: Colores.bosque,
              backgroundColor: Colores.arenaPaleta,
            ),
          ),
        ],
      ),
    );
  }
}
