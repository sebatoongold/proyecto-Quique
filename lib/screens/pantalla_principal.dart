// ============================================================
// pantalla_principal.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F4
//
// CAMBIOS v2 respecto a la v1:
//  - Anota en el registro de uso cada cambio de mundo, y si se pasó al
//    mundo del niño desde la actividad sugerida del apoderado.
//
// Contiene los dos mundos y la barra inferior para cambiar entre ellos.
// DECISIONES:
//  - La app siempre abre en el mundo APODERADO (él desbloquea el
//    teléfono y se lo entrega al niño).
//  - IndexedStack mantiene ambos mundos "vivos": al volver a uno,
//    queda como estaba (scroll, etc.).
//  - El Bluetooth se inicia aquí, una sola vez para toda la app.
// ============================================================

import 'package:flutter/material.dart';

import '../servicios/registro_uso.dart';
import '../servicios/servicio_ble.dart';
import '../widgets/barra_mundos.dart';
import 'apoderado/inicio_apoderado.dart';
import 'nino/inicio_nino.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  Mundo _mundo = Mundo.apoderado;

  @override
  void initState() {
    super.initState();
    ServicioBle.instancia.iniciar();
  }

  void _cambiar(Mundo nuevo, {String? motivo}) {
    if (nuevo != _mundo) RegistroUso.anotar('mundo', dato: motivo ?? nuevo.name);
    setState(() => _mundo = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _mundo == Mundo.apoderado ? 0 : 1,
        children: [
          // Cruce entre mundos: la actividad sugerida pasa al mundo niño
          // directamente (va del adulto al niño, no necesita puerta).
          InicioApoderado(
            alIrAlMundoNino: () => _cambiar(Mundo.nino, motivo: 'nino_por_actividad_sugerida'),
          ),
          const InicioNino(),
        ],
      ),
      bottomNavigationBar: BarraMundos(actual: _mundo, alCambiar: (m) => _cambiar(m)),
    );
  }
}
