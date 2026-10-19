// ============================================================
// main.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v8 — paso F4
//
// CAMBIOS v8 respecto a la v7:
//  - Inicia el registro de uso de la app (modo desarrollador) y anota
//    que se abrió la app.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
import 'servicios/registro_uso.dart';
import 'servicios/servicio_cinturon.dart';
import 'servicios/servicio_monitoreo.dart';
import 'servicios/servicio_parametros.dart';
import 'servicios/servicio_participantes.dart';
import 'tema/tema_app.dart';

Future<void> main() async {
  // Necesario para usar el almacenamiento del teléfono antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioParticipantes.instancia.iniciar();
  await ServicioParametros.instancia.iniciar();
  await ServicioMonitoreo.instancia.iniciar();
  await ServicioCinturon.instancia.iniciar();
  await RegistroUso.iniciar();
  RegistroUso.anotar('app_abierta');
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
