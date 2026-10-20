// ============================================================
// servicio_quiz.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F9.2 (quiz antes y después de jugar)
//
// Guarda los quiz hechos (todos los participantes) en el teléfono
// (shared_preferences). Si un quiz se repite para el mismo participante
// y momento, se guardan todos; Datos de prueba muestra el ÚLTIMO.
//
// `sesiones` avisa a las pantallas cuando cambia algo (p. ej. el ✓ de
// Configuración).
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/quiz.dart';

const String _clave = 'quiz_v1';

class ServicioQuiz {
  ServicioQuiz._();
  static final ServicioQuiz instancia = ServicioQuiz._();

  final ValueNotifier<List<SesionQuiz>> sesiones = ValueNotifier(const []);

  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return;
    try {
      final datos = jsonDecode(texto);
      if (datos is List) {
        sesiones.value = datos.whereType<Map<String, dynamic>>().map(SesionQuiz.desdeJson).toList();
      }
    } catch (_) {
      // Datos dañados: se parte de cero.
    }
  }

  Future<void> _guardarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(sesiones.value.map((s) => s.toJson()).toList()));
  }

  /// Agrega un quiz terminado (o interrumpido).
  Future<void> guardar(SesionQuiz s) async {
    sesiones.value = [...sesiones.value, s];
    await _guardarTodo();
  }

  /// Quiz de un participante, del más antiguo al más reciente.
  List<SesionQuiz> de(String? codigo) =>
      sesiones.value.where((s) => s.participante == codigo).toList();

  /// El último quiz COMPLETO de un participante en un momento (o null).
  SesionQuiz? ultimo(String? codigo, MomentoQuiz momento) {
    final lista = de(codigo).where((s) => s.momento == momento && s.completo).toList();
    return lista.isEmpty ? null : lista.last;
  }

  bool hecho(String? codigo, MomentoQuiz momento) => ultimo(codigo, momento) != null;

  Future<void> borrarDe(String? codigo) async {
    sesiones.value = sesiones.value.where((s) => s.participante != codigo).toList();
    await _guardarTodo();
  }
}
