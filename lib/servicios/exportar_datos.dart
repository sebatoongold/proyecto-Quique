// ============================================================
// exportar_datos.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v8 — paso F9.2
//
// CAMBIOS v8 respecto a la v7:
//  - Se exportan los QUIZ de cada participante ('quiz'): momento,
//    respuestas, lectura de cada una, orden de las tarjetas, tiempos y
//    cambios de opción (ver modelos/quiz.dart).
//  - Formato 'quique-testeo-v8'.
//
// Arma un texto JSON con los datos de un participante (o de todos) y
// lo copia al PORTAPAPELES. Desde ahí se pega donde convenga: un correo
// a uno mismo, una nota, WhatsApp, etc. No necesita ninguna dependencia
// nueva (el portapapeles viene incluido en Flutter).
//
// Cada juego lleva su hora exacta de inicio y fin (formato ISO, hora
// del teléfono), para poder cruzarlo con lo observado o con un video.
//
// Por privacidad, el NOMBRE del niño solo se incluye si se marca
// `incluirNombre` (por defecto, no): para el análisis basta el código.
// ============================================================

import 'dart:convert';

import 'package:flutter/services.dart';

import '../modelos/episodio_cinturon.dart';
import '../modelos/participante.dart';
import '../modelos/registro_juego.dart';
import '../modelos/sesion_monitoreo.dart';
import 'almacenamiento_juegos.dart';
import 'analisis_monitoreo.dart';
import 'analisis_recorrido.dart';
import 'registro_uso.dart';
import 'servicio_parametros.dart';
import 'servicio_cinturon.dart';
import 'servicio_monitoreo.dart';
import 'servicio_participantes.dart';
import 'servicio_quiz.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Identifica la versión del formato exportado. Si en un paso futuro se
// agregan datos (eventos, recorrido…), se sube el número para saber
// qué contiene cada exportación.
const String formatoExportacion = 'quique-testeo-v8';

class ExportarDatos {
  ExportarDatos._();

  static Map<String, dynamic> _perfil(Participante p, bool incluirNombre) => {
        'codigo': p.codigo,
        if (incluirNombre) 'nombre': p.nombre,
        'edad': p.edad,
        'creado': p.creado.toIso8601String(),
        'calibracion': p.calibracion?.toJson(),
      };

  /// Sesiones de monitoreo de un participante, con los dos resúmenes.
  static List<Map<String, dynamic>> _sesiones(
    String? codigo,
    List<RegistroJuego> juegos, {
    required bool conLecturas,
  }) {
    final delCinturon = ServicioCinturon.instancia.episodios.value;
    return [
      for (final s in ServicioMonitoreo.instancia.de(codigo))
        {
          ...s.toJson(conLecturas: false),
          'resumenFijo': AnalisisMonitoreo.calcular(s, Criterio.fijo,
                  juegos: juegos, episodiosCinturon: delCinturon)
              ?.toJson(),
          'resumenCalibrado': AnalisisMonitoreo.calcular(s, Criterio.calibrado,
                  juegos: juegos, episodiosCinturon: delCinturon)
              ?.toJson(),
          'validacionCinturon': _validacion(s, juegos, delCinturon),
          if (conLecturas)
            'lecturasCompactas': jsonEncode({'t': s.t, 'x': s.x, 'y': s.y, 'm': s.m}),
        },
    ];
  }

  static Map<String, dynamic>? _validacion(
    SesionMonitoreo s,
    List<RegistroJuego> juegos,
    List<EpisodioCinturon> delCinturon,
  ) {
    final v = AnalisisMonitoreo.comparar(s, juegos: juegos, episodiosCinturon: delCinturon);
    if (v == null) return null;
    return {'criterio': v.criterio.name, 'cinturon': v.cinturon, 'app': v.app};
  }

  /// Un juego con el análisis de los recorridos de sus poses.
  static Map<String, dynamic> _juego(RegistroJuego r) {
    final p = ServicioParametros.instancia.actual.value;
    return {
      ...r.toJson(),
      'analisisPoses': [for (final m in r.poses) AnalisisRecorrido.pose(r, m, p)?.toJson()],
    };
  }

  /// Registro de uso de la app de un participante.
  static List<Map<String, dynamic>> _uso(String? codigo) =>
      RegistroUso.de(codigo).map((e) => e.toJson()).toList();

  /// Quiz de un participante (completos e incompletos).
  static List<Map<String, dynamic>> _quiz(String? codigo) =>
      ServicioQuiz.instancia.de(codigo).map((s) => s.toJson()).toList();

  /// Episodios del cinturón de un participante.
  static List<Map<String, dynamic>> _episodiosCinturon(String? codigo) =>
      ServicioCinturon.instancia.de(codigo).map((e) => e.toJson()).toList();

  /// Datos de UN participante, como texto JSON legible.
  static Future<String> textoDe(Participante p, {bool incluirNombre = false}) async {
    final juegos = await AlmacenamientoJuegos.cargarDe(p.codigo);
    final datos = {
      'formato': formatoExportacion,
      'exportado': DateTime.now().toIso8601String(),
      'participante': _perfil(p, incluirNombre),
      'juegos': juegos.map(_juego).toList(),
      'monitoreo': _sesiones(p.codigo, juegos, conLecturas: true),
      'episodiosCinturon': _episodiosCinturon(p.codigo),
      'usoApp': _uso(p.codigo),
      'quiz': _quiz(p.codigo),
    };
    return const JsonEncoder.withIndent('  ').convert(datos);
  }

  /// Datos de TODOS los participantes (y de los juegos sin participante).
  static Future<String> textoDeTodos({bool incluirNombre = false}) async {
    final participantes = ServicioParticipantes.instancia.lista.value;
    final lista = <Map<String, dynamic>>[];
    for (final p in participantes) {
      final juegos = await AlmacenamientoJuegos.cargarDe(p.codigo);
      lista.add({
        ..._perfil(p, incluirNombre),
        'juegos': juegos.map(_juego).toList(),
        'monitoreo': _sesiones(p.codigo, juegos, conLecturas: false),
        'episodiosCinturon': _episodiosCinturon(p.codigo),
        'usoApp': _uso(p.codigo),
        'quiz': _quiz(p.codigo),
      });
    }
    final sinParticipante = await AlmacenamientoJuegos.cargarDe(null);
    final datos = {
      'formato': formatoExportacion,
      'exportado': DateTime.now().toIso8601String(),
      'participantes': lista,
      'juegosSinParticipante': sinParticipante.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(datos);
  }

  /// Copia el texto al portapapeles.
  static Future<void> copiar(String texto) =>
      Clipboard.setData(ClipboardData(text: texto));
}
