// ============================================================
// main.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso C1 (tema visual)
//
// CAMBIOS v2 respecto a la v1 (versión del respaldo de GitHub):
//  - Se aplica el tema de la guía de marca (tema/tema_app.dart).
//  - Se agrega el título de la app.
//  La pantalla de inicio sigue siendo PosturaScreen, sin cambios.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/postura_screen.dart';
import 'tema/tema_app.dart';

void main() {
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
      home: const PosturaScreen(),
    );
  }
}
