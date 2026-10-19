// ============================================================
// analisis_monitoreo.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F7.2
//
// CAMBIOS v2 respecto a la v1:
//  - El criterio FIJO ahora se calcula en la app desde los valores
//    crudos (|difXs| y |difYs| contra los umbrales). Antes se tomaba la
//    marca "malaPostura" del firmware, pero desde el firmware v8 esa
//    marca usa la calibración cargada en el cinturón y ya no es el fijo.
//  - Los CORTES DE CONEXIÓN se rellenan con los episodios que registró
//    el cinturón en su cola (si se le pasan `episodiosCinturon`): cada
//    episodio del cinturón que empezó durante un corte, y que se midió
//    con el mismo criterio (fijo = sin calibración; calibrado = con
//    calibración), se suma marcado como "delCinturon".
//  - Nuevo comparar(): cuántos episodios registró el cinturón con
//    conexión vs. cuántos calculó la app con el mismo criterio. Si
//    coinciden, la detección de la app queda validada con datos reales.
//  - Los umbrales de abajo ahora son la ÚNICA fuente: la app se los
//    envía al cinturón (comando UMBRAL, firmware v8).
//
// Convierte las lecturas de una sesión de monitoreo en EPISODIOS de
// mala postura, igual que lo hace el firmware:
//  - un episodio empieza con la primera lectura en mala postura y
//    termina con la primera lectura en buena postura;
//  - solo cuenta si duró al menos `duracionMinimaEpisodio` (3 s);
//  - el tiempo de cada episodio se reparte por dirección: adelante,
//    lateral o ambos.
//
// Dos CRITERIOS para decidir qué es mala postura en cada lectura:
//  - fijo: |difXs| > umbralAdelante  o  |difYs| > umbralLateral
//    (= lo que marca el firmware v7);
//  - calibrado: lo mismo, pero restando antes la postura neutral
//    calibrada del niño.
//
// Además se descuenta:
//  - el tiempo SIN CONEXIÓN (saltos entre lecturas de más de
//    `saltoSinConexion`): no se sabe qué pasó, no se cuenta;
//  - el tiempo JUGANDO: los juegos del participante que caen dentro de
//    la sesión no cuentan como mala postura (decisión del 11-10).
// ============================================================

import '../modelos/episodio_cinturon.dart';
import '../modelos/registro_juego.dart';
import '../modelos/sesion_monitoreo.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Umbrales de mala postura (unidades del sensor). Desde el firmware v8
// la app se los ENVÍA al cinturón al asignarlo a un participante, así
// que este es el único lugar donde se cambian.
const double umbralAdelante = 15;
const double umbralLateral = 10;
// Duración mínima de un episodio (firmware: DURACION_MINIMA_SEGUNDOS).
const int duracionMinimaEpisodioMs = 3000;
// Si entre dos lecturas pasa más que esto, se considera sin conexión.
const int saltoSinConexion = 2000;

enum Criterio { fijo, calibrado }

class EpisodioMonitoreo {
  final int inicioMs; // desde el inicio de la sesión
  final int duracionMs;
  final int msAdelante;
  final int msLateral;
  final int msAmbos;
  final bool delCinturon; // true = recuperado de la cola del cinturón (corte de conexión)

  const EpisodioMonitoreo({
    required this.inicioMs,
    required this.duracionMs,
    required this.msAdelante,
    required this.msLateral,
    required this.msAmbos,
    this.delCinturon = false,
  });

  Map<String, dynamic> toJson() => {
        'inicioMs': inicioMs,
        'duracionMs': duracionMs,
        'msAdelante': msAdelante,
        'msLateral': msLateral,
        'msAmbos': msAmbos,
        'delCinturon': delCinturon,
      };
}

class ResumenMonitoreo {
  final Criterio criterio;
  final int msMonitoreado; // con conexión y sin juego
  final int msSinConexion;
  final int msJugando;
  final List<EpisodioMonitoreo> episodios;

  const ResumenMonitoreo({
    required this.criterio,
    required this.msMonitoreado,
    required this.msSinConexion,
    required this.msJugando,
    required this.episodios,
  });

  int get veces => episodios.length;
  int get vecesDelCinturon => episodios.where((e) => e.delCinturon).length;
  int get msMalaPostura => episodios.fold(0, (a, e) => a + e.duracionMs);
  int get msMasLargo => episodios.fold(0, (a, e) => e.duracionMs > a ? e.duracionMs : a);
  int get msAdelante => episodios.fold(0, (a, e) => a + e.msAdelante);
  int get msLateral => episodios.fold(0, (a, e) => a + e.msLateral);
  int get msAmbos => episodios.fold(0, (a, e) => a + e.msAmbos);

  /// 'adelante', 'lateral', 'ambos' o null si no hubo episodios.
  String? get direccionDominante {
    if (episodios.isEmpty) return null;
    final a = msAdelante, l = msLateral, b = msAmbos;
    if (b >= a && b >= l) return 'ambos';
    return a >= l ? 'adelante' : 'lateral';
  }

  Map<String, dynamic> toJson() => {
        'criterio': criterio.name,
        'msMonitoreado': msMonitoreado,
        'msSinConexion': msSinConexion,
        'msJugando': msJugando,
        'veces': veces,
        'vecesDelCinturon': vecesDelCinturon,
        'msMalaPostura': msMalaPostura,
        'msMasLargo': msMasLargo,
        'direccionDominante': direccionDominante,
        'episodios': episodios.map((e) => e.toJson()).toList(),
      };

  /// Suma varios resúmenes (ej.: todas las sesiones de hoy).
  static ResumenMonitoreo sumar(Criterio c, List<ResumenMonitoreo> lista) => ResumenMonitoreo(
        criterio: c,
        msMonitoreado: lista.fold(0, (a, r) => a + r.msMonitoreado),
        msSinConexion: lista.fold(0, (a, r) => a + r.msSinConexion),
        msJugando: lista.fold(0, (a, r) => a + r.msJugando),
        episodios: [for (final r in lista) ...r.episodios],
      );
}

class AnalisisMonitoreo {
  AnalisisMonitoreo._();

  /// Calcula el resumen de una sesión con un criterio. Devuelve null si
  /// se pide el criterio calibrado y la sesión no tiene calibración.
  static ResumenMonitoreo? calcular(
    SesionMonitoreo s,
    Criterio criterio, {
    List<RegistroJuego> juegos = const [],
    List<EpisodioCinturon> episodiosCinturon = const [],
  }) {
    final calX = s.calibracionDifXs, calY = s.calibracionDifYs;
    if (criterio == Criterio.calibrado && (calX == null || calY == null)) return null;

    // Tramos de juego dentro de la sesión, en ms desde su inicio.
    final tramosJuego = <(int, int)>[
      for (final j in juegos)
        if (j.fin != null)
          (j.inicio.difference(s.inicio).inMilliseconds, j.fin!.difference(s.inicio).inMilliseconds),
    ];
    bool jugando(int ms) => tramosJuego.any((r) => ms >= r.$1 && ms <= r.$2);

    var msMonitoreado = 0, msSinConexion = 0, msJugando = 0;
    final episodios = <EpisodioMonitoreo>[];
    final cortes = <(int, int)>[]; // tramos sin conexión, ms desde el inicio

    // Episodio en curso.
    int? inicioEp;
    var ad = 0, la = 0, am = 0;

    void cerrar(int finMs) {
      final ini = inicioEp;
      if (ini == null) return;
      final dur = finMs - ini;
      if (dur >= duracionMinimaEpisodioMs) {
        episodios.add(EpisodioMonitoreo(
          inicioMs: ini,
          duracionMs: dur,
          msAdelante: ad,
          msLateral: la,
          msAmbos: am,
        ));
      }
      inicioEp = null;
      ad = 0;
      la = 0;
      am = 0;
    }

    final n = s.lecturas;
    for (var i = 0; i < n; i++) {
      final ms = s.t[i];
      // Tiempo hasta la siguiente lectura (la última dura 0).
      final dt = i + 1 < n ? s.t[i + 1] - ms : 0;
      final sinConexion = dt > saltoSinConexion;

      if (jugando(ms)) {
        cerrar(ms);
        msJugando += sinConexion ? 0 : dt;
        if (sinConexion) {
          msSinConexion += dt;
          cortes.add((ms, ms + dt));
        }
        continue;
      }

      // ¿Mala postura en esta lectura, y en qué dirección?
      final dx = (s.x[i] - (criterio == Criterio.calibrado ? calX! : 0)).abs();
      final dy = (s.y[i] - (criterio == Criterio.calibrado ? calY! : 0)).abs();
      final malaA = dx > umbralAdelante;
      final malaL = dy > umbralLateral;
      final mala = malaA || malaL; // fijo: desde 0; calibrado: desde su postura neutral

      if (mala) {
        inicioEp ??= ms;
        final tramo = sinConexion ? 0 : dt;
        if (malaA && malaL) {
          am += tramo;
        } else if (malaA) {
          ad += tramo;
        } else {
          la += tramo; // incluye el caso raro en que el firmware marca y la app no
        }
      } else {
        cerrar(ms);
      }

      if (sinConexion) {
        msSinConexion += dt;
        cortes.add((ms, ms + dt));
        cerrar(ms); // sin datos, no se sabe si siguió: el episodio termina aquí
      } else {
        msMonitoreado += dt;
      }
    }
    if (n > 0) cerrar(s.t[n - 1]);

    // Cortes de conexión: se rellenan con lo que registró el cinturón.
    for (final e in _delCinturonEn(s, criterio, episodiosCinturon)) {
      final ini = e.horaInicio!.difference(s.inicio).inMilliseconds;
      final enCorte = cortes.any((c) => ini >= c.$1 && ini <= c.$2);
      if (!enCorte || jugando(ini)) continue;
      episodios.add(EpisodioMonitoreo(
        inicioMs: ini,
        duracionMs: e.msDuracion,
        msAdelante: e.dsAdelante * 100,
        msLateral: e.dsLateral * 100,
        msAmbos: e.dsAmbos * 100,
        delCinturon: true,
      ));
    }
    episodios.sort((a, b) => a.inicioMs.compareTo(b.inicioMs));

    return ResumenMonitoreo(
      criterio: criterio,
      msMonitoreado: msMonitoreado,
      msSinConexion: msSinConexion,
      msJugando: msJugando,
      episodios: episodios,
    );
  }

  /// Episodios del cinturón de este participante, con hora conocida,
  /// que empezaron dentro de la sesión y se midieron con el criterio pedido.
  static List<EpisodioCinturon> _delCinturonEn(
    SesionMonitoreo s,
    Criterio criterio,
    List<EpisodioCinturon> todos,
  ) {
    final fin = s.fin ?? DateTime.now();
    return [
      for (final e in todos)
        if (e.participante == s.participante &&
            e.horaInicio != null &&
            !e.horaInicio!.isBefore(s.inicio) &&
            !e.horaInicio!.isAfter(fin) &&
            e.calibrado == (criterio == Criterio.calibrado))
          e,
    ];
  }

  /// Validación: con el criterio que usó el cinturón en la sesión,
  /// ¿cuántos episodios registró él con conexión y cuántos calculó la
  /// app? null si el cinturón no registró nada en la sesión.
  static ({Criterio criterio, int cinturon, int app})? comparar(
    SesionMonitoreo s, {
    List<RegistroJuego> juegos = const [],
    required List<EpisodioCinturon> episodiosCinturon,
  }) {
    for (final criterio in Criterio.values) {
      final delCinturon = _delCinturonEn(s, criterio, episodiosCinturon);
      if (delCinturon.isEmpty) continue;
      final r = calcular(s, criterio, juegos: juegos, episodiosCinturon: episodiosCinturon);
      if (r == null) continue;
      final recuperados = r.vecesDelCinturon;
      return (
        criterio: criterio,
        cinturon: delCinturon.length - recuperados, // los que ocurrieron con conexión
        app: r.veces - recuperados,
      );
    }
    return null;
  }
}
