// ============================================================
// registro_uso.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F4 (registro de uso, modo desarrollador)
//
// Anota qué se hace en la app FUERA del juego, con hora y participante
// activo. Responde la Lectura y la Motivación del lado del apoderado:
// ¿encontró la línea de tiempo?, ¿entendió el gesto?, ¿intentó entrar
// el niño al mundo del apoderado?
//
// Tipos de evento (`tipo`, y `dato` cuando aplica):
//   app_abierta
//   mundo             dato: apoderado / nino / nino_por_actividad_sugerida
//   puerta_intento    dato: corto (toque, < 15 %) / soltada (se soltó antes) / ok
//   juego_desde       dato: boton_jugar (el niño) — el juego lo abre él
//   historial         dato: postura / juegos (al abrir o cambiar pestaña)
//                     + origen: resumen_hoy / boton_historial
//   linea_tiempo      dato: desplazo (arrastró con el dedo) / toco_hora /
//                     cambio_dia / abrio_mes
//
// Se guarda en el teléfono (shared_preferences), con un tope de
// `maximoEventosUso` (se descartan los más antiguos).
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'servicio_participantes.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Máximo de eventos guardados (los más antiguos se descartan).
const int maximoEventosUso = 5000;

const String _clave = 'registro_uso_v1';

class EventoUso {
  final DateTime hora;
  final String tipo;
  final String? dato;
  final String? participante;

  const EventoUso(this.hora, this.tipo, {this.dato, this.participante});

  Map<String, dynamic> toJson() => {
        'hora': hora.toIso8601String(),
        'tipo': tipo,
        if (dato != null) 'dato': dato,
        'participante': participante,
      };

  factory EventoUso.desdeJson(Map<String, dynamic> j) => EventoUso(
        DateTime.tryParse(j['hora'] as String? ?? '') ?? DateTime(2000),
        j['tipo'] as String? ?? '',
        dato: j['dato'] as String?,
        participante: j['participante'] as String?,
      );
}

class RegistroUso {
  RegistroUso._();

  static final List<EventoUso> _eventos = [];
  static bool _cargado = false;
  static bool _guardando = false;
  static bool _pendiente = false;

  static Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto != null) {
      try {
        final datos = jsonDecode(texto);
        if (datos is List) {
          _eventos.addAll(datos.whereType<Map<String, dynamic>>().map(EventoUso.desdeJson));
        }
      } catch (_) {
        // Datos dañados: se parte de cero.
      }
    }
    _cargado = true;
  }

  /// Anota un evento (con el participante activo). No espera a guardar.
  static void anotar(String tipo, {String? dato}) {
    _eventos.add(EventoUso(
      DateTime.now(),
      tipo,
      dato: dato,
      participante: ServicioParticipantes.instancia.activo.value?.codigo,
    ));
    if (_eventos.length > maximoEventosUso) {
      _eventos.removeRange(0, _eventos.length - maximoEventosUso);
    }
    _guardar();
  }

  /// Guarda sin bloquear; si llegan varios seguidos, los junta.
  static Future<void> _guardar() async {
    if (!_cargado) return;
    if (_guardando) {
      _pendiente = true;
      return;
    }
    _guardando = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(_eventos.map((e) => e.toJson()).toList()));
    _guardando = false;
    if (_pendiente) {
      _pendiente = false;
      await _guardar();
    }
  }

  /// Eventos de un participante (null = sin participante).
  static List<EventoUso> de(String? codigo) =>
      _eventos.where((e) => e.participante == codigo).toList();

  static Future<void> borrarDe(String? codigo) async {
    _eventos.removeWhere((e) => e.participante == codigo);
    await _guardar();
  }
}
