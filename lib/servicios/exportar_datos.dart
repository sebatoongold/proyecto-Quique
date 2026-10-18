// ============================================================
// exportar_datos.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v3 — paso F2
//
// CAMBIOS v3 respecto a la v2:
//  - Cada juego exportado incluye ahora sus 'parametros' (la variante
//    con que se jugó). Formato 'quique-testeo-v3'.
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

import '../modelos/participante.dart';
import 'almacenamiento_juegos.dart';
import 'servicio_participantes.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Identifica la versión del formato exportado. Si en un paso futuro se
// agregan datos (eventos, recorrido…), se sube el número para saber
// qué contiene cada exportación.
const String formatoExportacion = 'quique-testeo-v3';

class ExportarDatos {
  ExportarDatos._();

  static Map<String, dynamic> _perfil(Participante p, bool incluirNombre) => {
        'codigo': p.codigo,
        if (incluirNombre) 'nombre': p.nombre,
        'edad': p.edad,
        'creado': p.creado.toIso8601String(),
      };

  /// Datos de UN participante, como texto JSON legible.
  static Future<String> textoDe(Participante p, {bool incluirNombre = false}) async {
    final juegos = await AlmacenamientoJuegos.cargarDe(p.codigo);
    final datos = {
      'formato': formatoExportacion,
      'exportado': DateTime.now().toIso8601String(),
      'participante': _perfil(p, incluirNombre),
      'juegos': juegos.map((r) => r.toJson()).toList(),
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
        'juegos': juegos.map((r) => r.toJson()).toList(),
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
