// ============================================================
// servicio_participantes.dart
// Fecha: 13-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F1 (perfiles de participante)
//
// Guarda la lista de participantes y cuál está ACTIVO, en el teléfono
// (shared_preferences, como los juegos). El participante activo es al
// que se le asignan los juegos que se jueguen desde ese momento.
//
// Es un servicio único (como el de Bluetooth): todas las pantallas leen
// el mismo `activo` y se actualizan solas cuando cambia.
//
// Uso en el testeo: antes de que llegue cada niño, el investigador
// crea o elige su perfil en Configuración → Participante.
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/participante.dart';

const String _claveLista = 'participantes_v1';
const String _claveActivo = 'participante_activo_v1';

class ServicioParticipantes {
  ServicioParticipantes._();
  static final ServicioParticipantes instancia = ServicioParticipantes._();

  /// Todos los participantes, en orden de creación.
  final ValueNotifier<List<Participante>> lista = ValueNotifier(const []);

  /// El participante activo (null = ninguno elegido todavía).
  final ValueNotifier<Participante?> activo = ValueNotifier(null);

  /// Se llama una vez al abrir la app (main.dart).
  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveLista);
    var participantes = <Participante>[];
    if (texto != null) {
      try {
        final datos = jsonDecode(texto);
        if (datos is List) {
          participantes = datos
              .whereType<Map<String, dynamic>>()
              .map(Participante.desdeJson)
              .toList();
        }
      } catch (_) {
        // Texto corrupto: se parte sin participantes en vez de fallar.
      }
    }
    lista.value = participantes;
    final codigoActivo = prefs.getString(_claveActivo);
    activo.value = _buscar(codigoActivo);
  }

  Participante? _buscar(String? codigo) {
    if (codigo == null) return null;
    for (final p in lista.value) {
      if (p.codigo == codigo) return p;
    }
    return null;
  }

  /// Propone el siguiente código libre: P01, P02, P03…
  String siguienteCodigo() {
    var n = 1;
    while (_buscar(_formatear(n)) != null) {
      n++;
    }
    return _formatear(n);
  }

  static String _formatear(int n) => 'P${n.toString().padLeft(2, '0')}';

  bool existeCodigo(String codigo) => _buscar(codigo) != null;

  /// Crea un participante y lo deja ACTIVO (lo normal es crearlo justo
  /// antes de que juegue).
  Future<void> crear(Participante p) async {
    lista.value = [...lista.value, p];
    activo.value = p;
    await _guardar();
  }

  Future<void> activar(Participante? p) async {
    activo.value = p;
    await _guardar();
  }

  /// Borra el perfil (los juegos se borran aparte, en AlmacenamientoJuegos).
  Future<void> eliminar(Participante p) async {
    lista.value = lista.value.where((x) => x.codigo != p.codigo).toList();
    if (activo.value?.codigo == p.codigo) activo.value = null;
    await _guardar();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveLista,
      jsonEncode(lista.value.map((p) => p.toJson()).toList()),
    );
    final a = activo.value;
    if (a == null) {
      await prefs.remove(_claveActivo);
    } else {
      await prefs.setString(_claveActivo, a.codigo);
    }
  }
}
