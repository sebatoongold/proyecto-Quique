// ============================================================
// analisis_postura.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F7.3 (la postura del día, desde el cinturón)
//
// Lo que ve el APODERADO sobre la postura sale de lo que registra el
// CINTURÓN en su cola (no hay que "iniciar" nada): este archivo ordena
// esos episodios por día y por hora para el Resumen de hoy y la línea
// de tiempo del Historial.
//
//  - Un episodio que EMPIEZA durante un juego del niño no cuenta como
//    mala postura (decisión del 11-10): se muestra aparte, "durante un
//    juego".
//  - Episodios sin hora (de antes de un reinicio del cinturón): no se
//    pueden ubicar en el día; se agrupan en "Sin hora exacta" en el día
//    en que la app los RECIBIÓ.
//  - El criterio es el que tenía cargado el cinturón al medirlos
//    (calibrado o umbral fijo): el apoderado ve un solo criterio.
// ============================================================

import '../modelos/episodio_cinturon.dart';
import '../modelos/registro_juego.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Primera hora que muestra la línea de tiempo (antes, solo si hay datos).
const int horaInicioDia = 8;
// Última hora que se muestra en días pasados (si no hay datos después).
const int horaFinDia = 22;

DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Un episodio ya ubicado en el día.
class EpisodioDelDia {
  final EpisodioCinturon e;
  final bool duranteJuego;

  const EpisodioDelDia(this.e, {required this.duranteJuego});

  DateTime get inicio => e.horaInicio!;
  int get msDuracion => e.msDuracion;

  /// 'adelante', 'lateral' o 'ambos' (donde pasó más tiempo).
  String get direccion {
    final a = e.dsAdelante, l = e.dsLateral, b = e.dsAmbos;
    if (b >= a && b >= l) return 'ambos';
    return a >= l ? 'adelante' : 'lateral';
  }
}

/// Un juego del día, para mostrarlo como contexto.
class JuegoDelDia {
  final DateTime inicio;
  final DateTime fin;
  const JuegoDelDia(this.inicio, this.fin);
}

class PosturaDelDia {
  final DateTime dia;
  final List<EpisodioDelDia> episodios; // con hora, del más reciente al más antiguo
  final List<EpisodioCinturon> sinHora; // recibidos este día, sin hora
  final List<JuegoDelDia> juegos;

  const PosturaDelDia({
    required this.dia,
    required this.episodios,
    required this.sinHora,
    required this.juegos,
  });

  /// Los que cuentan (fuera de los juegos).
  List<EpisodioDelDia> get queCuentan => episodios.where((e) => !e.duranteJuego).toList();

  int get veces => queCuentan.length;
  int get msTotal => queCuentan.fold(0, (a, e) => a + e.msDuracion);
  int get msMasLargo => queCuentan.fold(0, (a, e) => e.msDuracion > a ? e.msDuracion : a);

  /// 'adelante', 'lateral', 'ambos' o null si no hubo.
  String? get direccionDominante {
    if (queCuentan.isEmpty) return null;
    var a = 0, l = 0, b = 0;
    for (final x in queCuentan) {
      a += x.e.dsAdelante;
      l += x.e.dsLateral;
      b += x.e.dsAmbos;
    }
    if (b >= a && b >= l) return 'ambos';
    return a >= l ? 'adelante' : 'lateral';
  }

  /// Horas que muestra la línea de tiempo, de la más reciente a la más
  /// antigua: desde las 08:00 (o antes si hay datos) hasta la hora
  /// actual (hoy) o hasta las 22:00 / el último dato (días pasados).
  List<int> horas({DateTime? ahora}) {
    final n = ahora ?? DateTime.now();
    final esHoy = soloDia(n) == dia;
    final horasConDatos = [
      for (final e in episodios) e.inicio.hour,
      for (final j in juegos) j.inicio.hour,
    ];
    var desde = horaInicioDia;
    var hasta = esHoy ? n.hour : horaFinDia;
    for (final h in horasConDatos) {
      if (h < desde) desde = h;
      if (h > hasta) hasta = h;
    }
    if (desde > hasta) desde = hasta; // hoy, antes de las 08:00
    return [for (var h = hasta; h >= desde; h--) h];
  }

  List<EpisodioDelDia> enHora(int h) => episodios.where((e) => e.inicio.hour == h).toList();
  List<JuegoDelDia> juegosEnHora(int h) =>
      juegos.where((j) => j.inicio.hour <= h && j.fin.hour >= h).toList();
}

class AnalisisPostura {
  AnalisisPostura._();

  static PosturaDelDia delDia(
    DateTime dia, {
    required List<EpisodioCinturon> episodios, // del participante
    List<RegistroJuego> juegos = const [], // del participante
  }) {
    final d = soloDia(dia);
    final juegosDia = [
      for (final j in juegos)
        if (j.fin != null && (soloDia(j.inicio) == d || soloDia(j.fin!) == d))
          JuegoDelDia(j.inicio, j.fin!),
    ];
    bool enJuego(DateTime t) =>
        juegosDia.any((j) => !t.isBefore(j.inicio) && !t.isAfter(j.fin));

    final conHora = [
      for (final e in episodios)
        if (e.horaInicio != null && soloDia(e.horaInicio!) == d)
          EpisodioDelDia(e, duranteJuego: enJuego(e.horaInicio!)),
    ]..sort((a, b) => b.inicio.compareTo(a.inicio));

    final sinHora = [
      for (final e in episodios)
        if (e.horaInicio == null && soloDia(e.recibido) == d) e,
    ];

    return PosturaDelDia(dia: d, episodios: conHora, sinHora: sinHora, juegos: juegosDia);
  }

  /// Días que tienen algún episodio (para marcar el calendario).
  static Set<DateTime> diasConDatos(List<EpisodioCinturon> episodios) => {
        for (final e in episodios) soloDia(e.horaInicio ?? e.recibido),
      };
}
