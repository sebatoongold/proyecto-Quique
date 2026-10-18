// ============================================================
// servicio_parametros.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F2 (panel de parámetros)
//
// Guarda en el teléfono los parámetros del juego elegidos en el panel
// (shared_preferences) y los entrega a quien los necesite. Servicio
// único, como el de Bluetooth y el de participantes.
//
// Los parámetros se aplican DESDE EL PRÓXIMO JUEGO: un juego en curso
// sigue con los que tenía al empezar (así el registro es coherente).
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/parametros_juego.dart';

const String _clave = 'parametros_juego_v1';

class ServicioParametros {
  ServicioParametros._();
  static final ServicioParametros instancia = ServicioParametros._();

  /// Parámetros vigentes (valores por defecto hasta que se carguen).
  final ValueNotifier<ParametrosJuego> actual = ValueNotifier(const ParametrosJuego());

  /// Se llama una vez al abrir la app (main.dart).
  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return;
    try {
      final datos = jsonDecode(texto);
      if (datos is Map<String, dynamic>) {
        actual.value = ParametrosJuego.desdeJson(datos);
      }
    } catch (_) {
      // Texto corrupto: se queda con los valores por defecto.
    }
  }

  Future<void> cambiar(ParametrosJuego nuevos) async {
    actual.value = nuevos;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(nuevos.toJson()));
  }

  Future<void> restaurar() => cambiar(const ParametrosJuego());
}
