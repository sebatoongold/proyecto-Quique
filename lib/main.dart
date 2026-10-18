// ============================================================
// main.dart
// Fecha: 13-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v4 — paso F1
//
// CAMBIOS v4 respecto a la v3:
//  - Antes de mostrar la app, carga los participantes guardados y cuál
//    está activo (ServicioParticipantes), para que el primer saludo y
//    los juegos ya usen el participante correcto.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
import 'servicios/servicio_participantes.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  // Necesario para usar el almacenamiento del teléfono antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioParticipantes.instancia.iniciar();
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
