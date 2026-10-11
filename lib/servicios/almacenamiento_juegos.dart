// ============================================================
// almacenamiento_juegos.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso D2 (guardar los juegos en el teléfono)
//
// Guarda la lista de juegos jugados en el almacenamiento local del
// teléfono (shared_preferences), como texto JSON. Persiste aunque se
// cierre la app. Nada sale del teléfono (sin servidor ni cuentas).
//
// Por qué shared_preferences y no una base de datos: el volumen es
// pequeño (algunos juegos al día) y es una sola dependencia, sin SQL.
// Se descartó sqflite tras la crisis de compilación.
//
// Si el formato cambia en el futuro, se cambia la CLAVE (v1 -> v2)
// para no mezclar datos viejos con nuevos.
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/registro_juego.dart';

const String _clave = 'registros_juegos_v1';

class AlmacenamientoJuegos {
  AlmacenamientoJuegos._();

  /// Todos los juegos guardados, del más antiguo al más reciente.
  static Future<List<RegistroJuego>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return [];
    try {
      final lista = jsonDecode(texto);
      if (lista is! List) return [];
      return lista
          .whereType<Map<String, dynamic>>()
          .map(RegistroJuego.desdeJson)
          .toList();
    } catch (_) {
      // Texto corrupto: se devuelve vacío en vez de que la app falle.
      return [];
    }
  }

  /// Agrega un juego al final de la lista.
  static Future<void> guardar(RegistroJuego registro) async {
    final lista = await cargar();
    lista.add(registro);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clave,
      jsonEncode(lista.map((r) => r.toJson()).toList()),
    );
  }

  /// Borra todos los juegos (útil en pruebas, antes del testeo).
  static Future<void> borrarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }

  /// Racha: días seguidos con al menos un juego COMPLETADO, contando
  /// hasta hoy. Si hoy todavía no jugó, se cuenta hasta ayer (la racha
  /// no se "pierde" a mitad del día).
  static Future<int> racha() async {
    final lista = await cargar();
    final dias = <String>{
      for (final r in lista)
        if (r.completado) _claveDia(r.inicio),
    };
    var dia = DateTime.now();
    if (!dias.contains(_claveDia(dia))) {
      dia = dia.subtract(const Duration(days: 1));
    }
    var cuenta = 0;
    while (dias.contains(_claveDia(dia))) {
      cuenta++;
      dia = dia.subtract(const Duration(days: 1));
    }
    return cuenta;
  }

  static String _claveDia(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
