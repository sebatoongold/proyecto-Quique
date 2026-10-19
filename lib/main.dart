// ============================================================
// main.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v7 — paso F7.2
//
// CAMBIOS v7 respecto a la v6:
//  - Inicia ServicioCinturon: carga los episodios ya recibidos del
//    cinturón y, cada vez que se conecta, sincroniza su cola y le envía
//    la calibración del participante activo.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
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
