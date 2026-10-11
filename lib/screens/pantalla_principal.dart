// ============================================================
// pantalla_principal.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso C3 (contenedor de los dos mundos)
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

  void _cambiar(Mundo nuevo) => setState(() => _mundo = nuevo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _mundo == Mundo.apoderado ? 0 : 1,
        children: [
          // Cruce entre mundos: la actividad sugerida pasa al mundo niño
          // directamente (va del adulto al niño, no necesita puerta).
          InicioApoderado(alIrAlMundoNino: () => _cambiar(Mundo.nino)),
          const InicioNino(),
        ],
      ),
      bottomNavigationBar: BarraMundos(actual: _mundo, alCambiar: _cambiar),
    );
  }
}
