// ============================================================
// main.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v5 — paso F2
//
// CAMBIOS v5 respecto a la v4:
//  - Antes de mostrar la app, carga también los parámetros del juego
//    guardados en el panel (ServicioParametros).
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
import 'servicios/servicio_parametros.dart';
import 'servicios/servicio_participantes.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  // Necesario para usar el almacenamiento del teléfono antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioParticipantes.instancia.iniciar();
  await ServicioParametros.instancia.iniciar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quique',
      theme: TemaApp.claro,
      home: const PantallaPrincipal(),
    );
  }
}
