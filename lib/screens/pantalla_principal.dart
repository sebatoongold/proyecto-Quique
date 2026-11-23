// ============================================================
// pantalla_principal.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v5 — paso G5
//
// CAMBIOS v5 respecto a la v4:
//  - La barra de mundos vuelve a ir DEBAJO de las pantallas (una
//    columna), no encima: ya no tapa contenido. Las pantallas no
//    reciben el margen de la barra de gestos (lo maneja la barra).
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

import '../modelos/juego.dart';
import '../servicios/registro_uso.dart';
import '../servicios/servicio_ble.dart';
import '../widgets/barra_mundos.dart';
import 'apoderado/inicio_apoderado.dart';
import 'nino/ejecucion_screen.dart';
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

  /// G4: desde la actividad sugerida: al mundo niño y directo al juego.
  void _abrirSugerida(Juego juego) {
    _cambiar(Mundo.nino, motivo: 'nino_por_actividad_sugerida');
    RegistroUso.anotar('juego_desde', dato: 'actividad_sugerida');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EjecucionScreen(juego: juego)));
  }

  void _cambiar(Mundo nuevo, {String? motivo}) {
    if (nuevo != _mundo) RegistroUso.anotar('mundo', dato: motivo ?? nuevo.name);
    setState(() => _mundo = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // La barra de gestos del teléfono queda bajo la barra de mundos.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: IndexedStack(
                index: _mundo == Mundo.apoderado ? 0 : 1,
                children: [
                  // Cruce entre mundos: la actividad sugerida pasa al mundo niño y
                  // abre ese juego (va del adulto al niño, no necesita puerta).
                  InicioApoderado(alIrAlMundoNino: _abrirSugerida),
                  const InicioNino(),
                ],
              ),
            ),
          ),
          BarraMundos(actual: _mundo, alCambiar: (m) => _cambiar(m)),
        ],
      ),
    );
  }
}
