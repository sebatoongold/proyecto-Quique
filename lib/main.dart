// ============================================================
// main.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v10 — paso G3
//
// CAMBIOS v10 respecto a la v9:
//  - Carga el progreso de explorador al abrir la app (ServicioProgreso).
//  - Título de la app: Sóma.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
import 'servicios/registro_uso.dart';
import 'servicios/servicio_cinturon.dart';
import 'servicios/servicio_monitoreo.dart';
import 'servicios/servicio_parametros.dart';
import 'servicios/servicio_participantes.dart';
import 'servicios/servicio_progreso.dart';
import 'servicios/servicio_quiz.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  // Necesario para usar el almacenamiento del teléfono antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioParticipantes.instancia.iniciar();
  await ServicioParametros.instancia.iniciar();
  await ServicioMonitoreo.instancia.iniciar();
  await ServicioCinturon.instancia.iniciar();
  await RegistroUso.iniciar();
  await ServicioQuiz.instancia.iniciar();
  await ServicioProgreso.instancia.iniciar();
  RegistroUso.anotar('app_abierta');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sóma',
      theme: TemaApp.claro,
      home: const PantallaPrincipal(),
    );
  }
}
