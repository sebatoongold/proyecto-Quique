// ============================================================
// analisis_juegos.dart
// Fecha: 12-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso E (traducir las métricas a algo comprensible)
//
// Convierte los registros crudos de juegos en lo que necesita ver el
// APODERADO en el Historial (pestaña Juegos):
//  - Una sola métrica principal: TIEMPO PARA LOGRAR UNA POSE (segundos
//    desde "¡Vamos!" hasta completar los 10 s). Si baja con los días,
//    le está costando menos.
//  - Comparación SIEMPRE contra el propio niño: su PRIMER DÍA de juego
//    es la línea base (nunca una norma: el sistema no está validado
//    clínicamente).
//  - La semana se compara como promedio, no día a día: un mal día por
//    cansancio no debe leerse como retroceso.
//  - La pose que más le cuesta, para sugerir dónde acompañarlo.
//
// Todo el texto es no alarmista: nada de "mal" ni rojo.
// ============================================================

import '../modelos/registro_juego.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cambio mínimo respecto al primer día para decir que mejoró o que
// costó más (0.10 = 10 %). Menos que eso = "se mantiene parecido".
const double umbralCambio = 0.10;
// Para elegir la pose que más cuesta, una pose "intentada" (no
// completada) cuenta como si hubiese tardado estos segundos.
const double segundosPenalizacionIntentada = 60;
// Mínimo de intentos de una pose para poder decir que es la que más cuesta.
const int minimoIntentosPorPose = 2;
// Días que muestra el gráfico (terminando hoy).
const int diasDelGrafico = 7;

class ResumenDiaJuegos {
  final DateTime dia;
  final double? segundosPromedio; // null = no completó ninguna pose ese día
  final int completadas;
  final int intentadas;
  final bool esPrimerDia;

  const ResumenDiaJuegos({
    required this.dia,
    required this.segundosPromedio,
    required this.completadas,
    required this.intentadas,
    required this.esPrimerDia,
  });

  bool get jugo => completadas + intentadas > 0;
}

class ResumenSemanaJuegos {
  final DateTime? primerDia;
  final double? lineaBase; // segundos promedio del primer día
  final double? promedioSemana; // últimos días, sin contar el primer día
  final List<ResumenDiaJuegos> dias; // del más antiguo a hoy
  final int completadas;
  final int intentadas;
  final String? poseQueMasCuesta;
  final String mensaje;

  const ResumenSemanaJuegos({
    required this.primerDia,
    required this.lineaBase,
    required this.promedioSemana,
    required this.dias,
    required this.completadas,
    required this.intentadas,
    required this.poseQueMasCuesta,
    required this.mensaje,
  });
}

class AnalisisJuegos {
  AnalisisJuegos._();

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  static double? _promedio(Iterable<double> valores) {
    final lista = valores.toList();
    if (lista.isEmpty) return null;
    return lista.reduce((a, b) => a + b) / lista.length;
  }

  static String _s(double segundos) => '${segundos.round()} s';

  static ResumenSemanaJuegos calcular(List<RegistroJuego> registros, {DateTime? ahora}) {
    final hoy = _dia(ahora ?? DateTime.now());

    // Poses de cada día (por fecha de inicio del juego).
    final porDia = <DateTime, List<MetricaPose>>{};
    for (final r in registros) {
      porDia.putIfAbsent(_dia(r.inicio), () => []).addAll(r.poses);
    }

    // Línea base: el primer día en que logró al menos una pose.
    final diasOrdenados = porDia.keys.toList()..sort();
    DateTime? primerDia;
    double? lineaBase;
    for (final d in diasOrdenados) {
      final tiempos = porDia[d]!
          .where((p) => p.completada && p.segundosHastaCompletar != null)
          .map((p) => p.segundosHastaCompletar!);
      final prom = _promedio(tiempos);
      if (prom != null) {
        primerDia = d;
        lineaBase = prom;
        break;
      }
    }

    // Los últimos días, terminando hoy.
    final dias = <ResumenDiaJuegos>[];
    final posesVentana = <MetricaPose>[];
    final tiemposSemana = <double>[];
    for (var i = diasDelGrafico - 1; i >= 0; i--) {
      final d = hoy.subtract(Duration(days: i));
      final poses = porDia[d] ?? const <MetricaPose>[];
      posesVentana.addAll(poses);
      final tiempos = poses
          .where((p) => p.completada && p.segundosHastaCompletar != null)
          .map((p) => p.segundosHastaCompletar!)
          .toList();
      final esPrimero = d == primerDia;
      if (!esPrimero) tiemposSemana.addAll(tiempos);
      dias.add(ResumenDiaJuegos(
        dia: d,
        segundosPromedio: _promedio(tiempos),
        completadas: poses.where((p) => p.completada).length,
        intentadas: poses.where((p) => !p.completada).length,
        esPrimerDia: esPrimero,
      ));
    }
    final promedioSemana = _promedio(tiemposSemana);

    // La pose que más cuesta en estos días.
    final costos = <String, List<double>>{};
    for (final p in posesVentana) {
      final costo = p.completada && p.segundosHastaCompletar != null
          ? p.segundosHastaCompletar!
          : segundosPenalizacionIntentada;
      costos.putIfAbsent(p.instruccion, () => []).add(costo);
    }
    String? masCuesta;
    double peor = -1;
    var posesConDatos = 0;
    costos.forEach((pose, lista) {
      if (lista.length < minimoIntentosPorPose) return;
      posesConDatos++;
      final prom = _promedio(lista)!;
      if (prom > peor) {
        peor = prom;
        masCuesta = pose;
      }
    });
    if (posesConDatos < 2) masCuesta = null; // con una sola pose no hay comparación

    // Mensaje de tendencia, en lenguaje simple y sin alarmar.
    String mensaje;
    if (lineaBase == null || primerDia == null) {
      mensaje = registros.isEmpty
          ? 'Todavía no hay juegos. Su primer juego será el punto de partida para comparar.'
          : 'Todavía no logra una pose completa. Cuando lo haga, ese día será su punto de partida.';
    } else if (promedioSemana == null) {
      mensaje = 'Su primer día de juego es su punto de partida: tardó ${_s(lineaBase)} '
          'en lograr una pose. Desde el próximo día de juego podrás ver cómo cambia.';
    } else {
      final cambio = promedioSemana / lineaBase;
      if (cambio < 1 - umbralCambio) {
        mensaje = 'Esta semana le cuesta menos lograr las poses: su primer día tardaba '
            '${_s(lineaBase)}; esta semana, ${_s(promedioSemana)} en promedio.';
      } else if (cambio > 1 + umbralCambio) {
        mensaje = 'Esta semana le ha costado un poco más que su primer día '
            '(${_s(lineaBase)} → ${_s(promedioSemana)}). Algunos días cuestan más; '
            'puede valer la pena ver si está cansado o distraído al jugar.';
      } else {
        mensaje = 'Se mantiene parecido a su primer día: alrededor de '
            '${_s(promedioSemana)} para lograr una pose.';
      }
    }

    return ResumenSemanaJuegos(
      primerDia: primerDia,
      lineaBase: lineaBase,
      promedioSemana: promedioSemana,
      dias: dias,
      completadas: posesVentana.where((p) => p.completada).length,
      intentadas: posesVentana.where((p) => !p.completada).length,
      poseQueMasCuesta: masCuesta,
      mensaje: mensaje,
    );
  }
}
