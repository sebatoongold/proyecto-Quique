// ============================================================
// almacenamiento_juegos.dart
// Fecha: 13-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F1
//
// CAMBIOS v2 respecto a la v1:
//  - Al guardar un juego se le asigna el PARTICIPANTE ACTIVO (si hay
//    uno). Así la pantalla del juego no necesita saber de perfiles.
//  - Nuevo `cargarDelActivo()`: solo los juegos del participante
//    activo. Lo usan el Historial, los Datos de prueba y la racha, para
//    que los datos de distintos niños no se mezclen.
//  - Nuevo `cargarDe(codigo)` (para exportar) y `borrarDe(codigo)`
//    (al eliminar un participante).
//
// Guarda la lista de juegos jugados en el almacenamiento local del
// teléfono (shared_preferences), como texto JSON. Persiste aunque se
// cierre la app. Nada sale del teléfono (sin servidor ni cuentas).
// Si el formato cambia de forma incompatible, se cambia la CLAVE
// (v1 -> v2) para no mezclar datos viejos con nuevos.
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/registro_juego.dart';
import 'servicio_participantes.dart';

const String _clave = 'registros_juegos_v1';

class AlmacenamientoJuegos {
  AlmacenamientoJuegos._();

  /// Todos los juegos guardados (de todos los participantes), del más
  /// antiguo al más reciente.
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

  /// Juegos de un participante (codigo null = juegos sin participante).
  static Future<List<RegistroJuego>> cargarDe(String? codigo) async {
    final todos = await cargar();
    return todos.where((r) => r.participante == codigo).toList();
  }

  /// Juegos del participante activo. Si no hay ninguno activo, los
  /// juegos que se jugaron sin participante.
  static Future<List<RegistroJuego>> cargarDelActivo() =>
      cargarDe(ServicioParticipantes.instancia.activo.value?.codigo);

  /// Agrega un juego al final de la lista, asignándole el participante
  /// activo si todavía no tiene uno.
  static Future<void> guardar(RegistroJuego registro) async {
    registro.participante ??= ServicioParticipantes.instancia.activo.value?.codigo;
    final lista = await cargar();
    lista.add(registro);
    await _escribir(lista);
  }

  /// Borra los juegos de un participante (al eliminar su perfil).
  static Future<void> borrarDe(String? codigo) async {
    final lista = await cargar();
    await _escribir(lista.where((r) => r.participante != codigo).toList());
  }

  /// Borra TODOS los juegos de todos los participantes (antes del testeo).
  static Future<void> borrarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }

  static Future<void> _escribir(List<RegistroJuego> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clave,
      jsonEncode(lista.map((r) => r.toJson()).toList()),
    );
  }

  /// Racha del participante activo: días seguidos con al menos un juego
  /// COMPLETADO, contando hasta hoy. Si hoy todavía no jugó, se cuenta
  /// hasta ayer (la racha no se "pierde" a mitad del día).
  static Future<int> racha() async {
    final lista = await cargarDelActivo();
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
