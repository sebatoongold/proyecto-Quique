// ============================================================
// servicio_progreso.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// El PROGRESO de explorador de cada participante: su experiencia (XP),
// los capítulos vistos, las fotos de animales, las postales de lugares,
// las insignias y los días que jugó. Se guarda en el teléfono
// (shared_preferences), separado por participante.
//
// Reglas (decididas con el usuario, ver "Guion — El viaje de Sóma"):
//  - UNA SOLA experiencia por niño; todo suma a ella. NUNCA se pierde.
//  - Rachas SIN CASTIGO: el multiplicador cuenta cuántos días jugó en la
//    semana (lunes a domingo), no días seguidos. Si un día no juega, no
//    pierde nada.
//  - Todo se consigue haciendo algo concreto: NADA al azar.
//
// `progreso` avisa a las pantallas cuando cambia algo.
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/animal_postura.dart';
import '../modelos/historia.dart';
import '../modelos/registro_juego.dart';
import 'servicio_parametros.dart';
import 'servicio_participantes.dart';

// ---------- PARÁMETROS AJUSTABLES (experiencia) ----------
// Por terminar una actividad (aunque se salte alguna pose).
const int xpActividad = 30;
// Por cada pose lograda dentro de una actividad.
const int xpPorPose = 5;
// Por terminar de ver un capítulo (una sola vez por capítulo).
const int xpCapitulo = 15;
// Por cada foto de animal nueva.
const int xpFoto = 20;
// Por cada insignia nueva.
const int xpInsignia = 20;
// Multiplicador de la XP de las actividades según los días jugados en
// la semana: 1 día = ×1,1; 2 = ×1,2 … hasta `multiplicadorMaximo`.
const double multiplicadorPorDia = 0.1;
const double multiplicadorMaximo = 1.5;

const String _clave = 'progreso_v1';

class ProgresoExplorador {
  int xp = 0;
  final Set<String> capitulosVistos = {};
  final Set<String> fotos = {}; // ids de AnimalPostura
  final Set<String> insignias = {};
  final Set<String> diasJugados = {}; // 'aaaa-mm-dd'

  /// Las postales salen de los capítulos vistos (una por lugar).
  Set<String> get postales {
    final s = <String>{};
    for (final id in capitulosVistos) {
      final c = capituloPorId(id);
      if (c != null && c.numero > 0) s.add(c.lugar.name);
    }
    return s;
  }

  /// Días jugados en la semana de `hoy` (lunes a domingo).
  int diasEstaSemana(DateTime hoy) {
    final lunes = DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: hoy.weekday - 1));
    return diasJugados.where((d) {
      final f = DateTime.tryParse(d);
      return f != null && !f.isBefore(lunes) && f.isBefore(lunes.add(const Duration(days: 7)));
    }).length;
  }

  double multiplicador(DateTime hoy) {
    final dias = diasEstaSemana(hoy);
    if (dias == 0) return 1;
    final m = 1 + multiplicadorPorDia * dias;
    return m > multiplicadorMaximo ? multiplicadorMaximo : m;
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'capitulosVistos': capitulosVistos.toList(),
        'fotos': fotos.toList(),
        'insignias': insignias.toList(),
        'diasJugados': diasJugados.toList(),
      };

  static ProgresoExplorador desdeJson(Map<String, dynamic> j) {
    List<String> lista(String k) => (j[k] as List?)?.whereType<String>().toList() ?? const [];
    return ProgresoExplorador()
      ..xp = (j['xp'] as num?)?.toInt() ?? 0
      ..capitulosVistos.addAll(lista('capitulosVistos'))
      ..fotos.addAll(lista('fotos'))
      ..insignias.addAll(lista('insignias'))
      ..diasJugados.addAll(lista('diasJugados'));
  }
}

/// Lo que ganó el niño en una actividad (para mostrarlo en el cierre).
class Ganancia {
  final int xp;
  final AnimalPostura? foto; // foto nueva, si la ganó
  final List<Insignia> insignias; // insignias nuevas
  final List<Capitulo> capitulosNuevos; // capítulos que se abrieron
  const Ganancia(this.xp, this.foto, this.insignias, this.capitulosNuevos);
}

class ServicioProgreso {
  ServicioProgreso._();
  static final ServicioProgreso instancia = ServicioProgreso._();

  final Map<String, ProgresoExplorador> _porParticipante = {};

  /// Avisa cuando cambia el progreso de cualquiera (las pantallas leen
  /// el del participante activo con `actual`).
  final ValueNotifier<int> cambios = ValueNotifier(0);

  static String _llave(String? codigo) => codigo ?? '_sin_participante';

  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null) return;
    try {
      final datos = jsonDecode(texto);
      if (datos is Map<String, dynamic>) {
        datos.forEach((k, v) {
          if (v is Map<String, dynamic>) _porParticipante[k] = ProgresoExplorador.desdeJson(v);
        });
      }
    } catch (_) {
      // Datos dañados: se parte de cero.
    }
  }

  Future<void> _guardar() async {
    cambios.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(_porParticipante.map((k, v) => MapEntry(k, v.toJson()))));
  }

  ProgresoExplorador de(String? codigo) =>
      _porParticipante.putIfAbsent(_llave(codigo), ProgresoExplorador.new);

  ProgresoExplorador get actual => de(ServicioParticipantes.instancia.activo.value?.codigo);

  /// Una actividad TERMINADA (llegó al cierre). `fotoDe`: el animal del
  /// capítulo desde el que se abrió ("¡Ayúdame!"), si viene de la historia.
  Future<Ganancia> registrarActividad(RegistroJuego r, {AnimalPostura? fotoDe}) async {
    final p = actual;
    final hoy = DateTime.now();
    final antes = _abiertos(p.xp);
    p.diasJugados.add(_dia(hoy));
    final logradas = r.poses.where((m) => m.completada).length;
    var xp = ((xpActividad + xpPorPose * logradas) * p.multiplicador(hoy)).round();

    // Foto: solo si logró la postura de ese animal en esta actividad.
    AnimalPostura? foto;
    if (fotoDe != null &&
        !p.fotos.contains(fotoDe.id) &&
        r.poses.any((m) => m.animal == fotoDe.id && m.completada)) {
      p.fotos.add(fotoDe.id);
      foto = fotoDe;
      xp += xpFoto;
    }

    // Insignias.
    final nuevas = <Insignia>[];
    void ganar(String id) {
      if (p.insignias.add(id)) {
        nuevas.add(insigniasExplorador.firstWhere((i) => i.id == id));
        xp += xpInsignia;
      }
    }

    ganar('primera_exploracion');
    if (r.completado) ganar('todas_las_poses');
    if (p.diasEstaSemana(hoy) >= 3) ganar('tres_dias');

    p.xp += xp;
    final abiertos = _abiertos(p.xp).where((c) => !antes.contains(c)).toList();
    await _guardar();
    return Ganancia(xp, foto, nuevas, abiertos);
  }

  /// Terminó de ver un capítulo (da XP solo la primera vez).
  Future<int> capituloVisto(Capitulo c) async {
    final p = actual;
    if (!p.capitulosVistos.add(c.id)) return 0;
    var xp = c.numero == 0 ? 0 : xpCapitulo;
    final todos = capitulosHistoria.where((x) => x.numero > 0 && !x.proximamente);
    if (todos.every((x) => p.capitulosVistos.contains(x.id)) && p.insignias.add('viaje_completo')) {
      xp += xpInsignia;
    }
    p.xp += xp;
    await _guardar();
    return xp;
  }

  /// Capítulos abiertos con esta experiencia (con los umbrales del panel).
  List<Capitulo> _abiertos(int xp) {
    final par = ServicioParametros.instancia.actual.value;
    return [for (final c in capitulosHistoria) if (!c.proximamente && xp >= c.xpNecesaria(par)) c];
  }

  /// Para el investigador: vuelve a cero el progreso de un participante.
  Future<void> reiniciar(String? codigo) async {
    _porParticipante.remove(_llave(codigo));
    await _guardar();
  }

  Future<void> borrarDe(String? codigo) => reiniciar(codigo);

  static String _dia(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
