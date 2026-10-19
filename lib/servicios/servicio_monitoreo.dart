// ============================================================
// servicio_monitoreo.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F5 (monitoreo en vivo)
//
// Graba sesiones de monitoreo: mientras hay una sesión en curso, cada
// lectura que llega del cinturón se guarda en ella. Servicio único (como
// el de Bluetooth): sigue grabando aunque se cambie de pantalla o de
// mundo, incluso si el niño se pone a jugar (los juegos se descuentan
// después, en el análisis).
//
// Guardado en el teléfono (shared_preferences):
//  - al terminar la sesión;
//  - y cada `segundosAutoguardado` mientras está en curso, para no
//    perderla si la app se cierra. Si al abrir la app hay una sesión
//    sin terminar, se cierra en su última lectura y queda marcada como
//    "interrumpida".
//
// IMPORTANTE para el testeo: dejar el teléfono con la PANTALLA
// ENCENDIDA (o con el apagado automático en 30 min) y la app abierta.
// Con la pantalla apagada, Android puede pausar la app y cortar la
// grabación.
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/sesion_monitoreo.dart';
import 'servicio_ble.dart';
import 'servicio_participantes.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cada cuántos segundos se guarda la sesión en curso.
const int segundosAutoguardado = 60;

const String _clave = 'sesiones_monitoreo_v1';

class ServicioMonitoreo {
  ServicioMonitoreo._();
  static final ServicioMonitoreo instancia = ServicioMonitoreo._();

  final ServicioBle _ble = ServicioBle.instancia;

  /// Todas las sesiones terminadas, de la más antigua a la más reciente.
  final ValueNotifier<List<SesionMonitoreo>> sesiones = ValueNotifier(const []);

  /// La sesión que se está grabando (null = ninguna).
  final ValueNotifier<SesionMonitoreo?> enCurso = ValueNotifier(null);

  Timer? _autoguardado;

  bool get grabando => enCurso.value != null;

  /// Se llama una vez al abrir la app (main.dart).
  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    var lista = <SesionMonitoreo>[];
    if (texto != null) {
      try {
        final datos = jsonDecode(texto);
        if (datos is List) {
          lista = datos
              .whereType<Map<String, dynamic>>()
              .map(SesionMonitoreo.desdeJson)
              .toList();
        }
      } catch (_) {
        // Texto corrupto: se parte sin sesiones en vez de fallar.
      }
    }
    // Sesiones que quedaron abiertas (la app se cerró): se cierran en su
    // última lectura.
    for (final s in lista) {
      if (s.fin == null) {
        s.interrumpida = true;
        s.fin = s.lecturas == 0 ? s.inicio : s.inicio.add(Duration(milliseconds: s.t.last));
      }
    }
    sesiones.value = lista;
    _ble.datos.addListener(_alLlegarDato);
  }

  void _alLlegarDato() {
    final s = enCurso.value;
    final d = _ble.datos.value;
    if (s == null || d == null) return;
    s.agregar(DateTime.now(), d.difXs, d.difYs, d.malaPostura);
  }

  /// Empieza a grabar para el participante activo.
  Future<void> empezar() async {
    if (grabando) return;
    final p = ServicioParticipantes.instancia.activo.value;
    final s = SesionMonitoreo(participante: p?.codigo, inicio: DateTime.now())
      ..calibracionDifXs = p?.calibracion?.difXs
      ..calibracionDifYs = p?.calibracion?.difYs;
    enCurso.value = s;
    _autoguardado?.cancel();
    _autoguardado = Timer.periodic(
      const Duration(seconds: segundosAutoguardado),
      (_) => _guardar(),
    );
    await _guardar();
  }

  /// Termina la sesión en curso y la devuelve (para preguntar la
  /// estimación y mostrar el resultado).
  Future<SesionMonitoreo?> terminar() async {
    final s = enCurso.value;
    if (s == null) return null;
    _autoguardado?.cancel();
    s.fin = DateTime.now();
    enCurso.value = null;
    sesiones.value = [...sesiones.value, s];
    await _guardar();
    return s;
  }

  /// Guarda la estimación del apoderado en una sesión ya terminada.
  Future<void> guardarEstimacion(SesionMonitoreo s, String? estimacion) async {
    s.estimacionApoderado = estimacion;
    sesiones.value = [...sesiones.value];
    await _guardar();
  }

  /// Sesiones de un participante (codigo null = sin participante).
  List<SesionMonitoreo> de(String? codigo) =>
      sesiones.value.where((s) => s.participante == codigo).toList();

  /// Sesiones de HOY del participante activo.
  List<SesionMonitoreo> deHoyDelActivo() {
    final codigo = ServicioParticipantes.instancia.activo.value?.codigo;
    final hoy = DateTime.now();
    return de(codigo)
        .where((s) =>
            s.inicio.year == hoy.year && s.inicio.month == hoy.month && s.inicio.day == hoy.day)
        .toList();
  }

  /// Borra las sesiones de un participante (al eliminar su perfil).
  Future<void> borrarDe(String? codigo) async {
    sesiones.value = sesiones.value.where((s) => s.participante != codigo).toList();
    await _guardar();
  }

  Future<void> _guardar() async {
    final lista = [
      ...sesiones.value,
      if (enCurso.value != null) enCurso.value!,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(lista.map((s) => s.toJson()).toList()));
  }
}
