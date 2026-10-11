// ============================================================
// main.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso C3 (dos mundos)
//
// CAMBIOS v3 respecto a la v2:
//  - La pantalla de inicio ahora es PantallaPrincipal (los dos mundos
//    con su barra inferior). La pantalla "Datos del sensor" sigue
//    disponible desde el engranaje del mundo apoderado.
// ============================================================

import 'package:flutter/material.dart';

import 'screens/pantalla_principal.dart';
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
      home: const PantallaPrincipal(),
    );
  }
}
