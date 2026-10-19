// ============================================================
// analisis_recorrido.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F4 (qué dice el recorrido de cada pose)
//
// Lee el RECORRIDO de una pose (cada lectura desde "¡Vamos!") y lo
// resume en datos que responden preguntas del testeo. Solo para el
// modo desarrollador (Datos de prueba: juegos) y la exportación.
//
// Se calcula AL MIRAR los datos, no al jugar: si cambias los umbrales
// del panel (Parámetros → Análisis de recorridos), se recalcula todo,
// también lo de juegos anteriores. No hay que volver a jugar.
//
// EJE PRINCIPAL de una pose: el eje (lateral o adelante) en que hay
// que moverse más para llegar al objetivo desde donde partió.
//
// Qué se calcula:
//  - primerMovimiento: la primera vez que se aleja de donde partió más
//    que `umbralMovimiento` en el eje principal. ¿Hacia el objetivo
//    ("correcto") o al revés ("contrario")? "sin_movimiento" si nunca.
//    -> ¿se entiende el modo espejo?
//  - sePasoDeLargo: en algún momento fue MÁS ALLÁ del objetivo, más que
//    el margen de la pose. -> ¿la pose o el margen confunden?
//  - llegoCercaSinEntrar: nunca entró a la zona, pero estuvo a menos de
//    `factorCerca` × el margen. -> ¿pose demasiado exigente para su cuerpo?
//  - pistas: por cada pista, ¿se ACERCÓ al objetivo (al menos
//    `umbralMovimiento`) dentro de los `segundosVentanaPista` siguientes?
//    -> ¿la pista sirve?
//  - segundosEnVineta: desde que apareció la explicación hasta "¡Vamos!".
//    -> ¿lee las viñetas o se las salta?
// ============================================================

import '../modelos/parametros_juego.dart';
import '../modelos/registro_juego.dart';

class AnalisisPose {
  final String ejePrincipal; // 'lateral' | 'adelante'
  final String primerMovimiento; // 'correcto' | 'contrario' | 'sin_movimiento' | 'sin_datos'
  final double? segundosPrimerMovimiento;
  final bool sePasoDeLargo;
  final bool llegoCercaSinEntrar;
  final int pistas;
  final int pistasQueSirvieron;
  final double? segundosEnVineta;

  const AnalisisPose({
    required this.ejePrincipal,
    required this.primerMovimiento,
    required this.segundosPrimerMovimiento,
    required this.sePasoDeLargo,
    required this.llegoCercaSinEntrar,
    required this.pistas,
    required this.pistasQueSirvieron,
    required this.segundosEnVineta,
  });

  Map<String, dynamic> toJson() => {
        'ejePrincipal': ejePrincipal,
        'primerMovimiento': primerMovimiento,
        'segundosPrimerMovimiento': segundosPrimerMovimiento,
        'sePasoDeLargo': sePasoDeLargo,
        'llegoCercaSinEntrar': llegoCercaSinEntrar,
        'pistas': pistas,
        'pistasQueSirvieron': pistasQueSirvieron,
        'segundosEnVineta': segundosEnVineta,
      };
}

class AnalisisRecorrido {
  AnalisisRecorrido._();

  /// Analiza una pose de un juego. null si la pose no tiene recorrido
  /// (juegos anteriores a F4).
  static AnalisisPose? pose(RegistroJuego juego, MetricaPose m, ParametrosJuego p) {
    if (!m.tieneRecorrido) return null;
    final objL = m.objetivoLateral!;
    final objA = m.objetivoAdelante ?? 0;
    final l0 = m.recorridoLateral.first;
    final a0 = m.recorridoAdelante.first;

    // Eje principal: donde hay más camino por recorrer.
    final lateral = (objL - l0).abs() >= (objA - a0).abs();
    final eje = lateral ? m.recorridoLateral : m.recorridoAdelante;
    final obj = lateral ? objL : objA;
    final inicio = eje.first;
    final margen = lateral ? (m.margenLateral ?? 0) : (m.margenAdelante ?? m.margenLateral ?? 0);
    final haciaObjetivo = (obj - inicio).sign; // +1, -1 o 0

    // Primer movimiento.
    var primer = 'sin_movimiento';
    double? tPrimer;
    for (var i = 0; i < eje.length; i++) {
      final delta = eje[i] - inicio;
      if (delta.abs() > p.umbralMovimiento) {
        primer = (haciaObjetivo == 0 || delta.sign == haciaObjetivo) ? 'correcto' : 'contrario';
        tPrimer = m.recorridoMs[i] / 1000;
        break;
      }
    }

    // Se pasó de largo: más allá del objetivo, en la dirección del
    // movimiento, por más que el margen.
    var sePaso = false;
    if (haciaObjetivo != 0) {
      for (final v in eje) {
        if ((v - obj) * haciaObjetivo > margen) {
          sePaso = true;
          break;
        }
      }
    }

    // Llegó cerca sin entrar.
    var minError = double.infinity;
    for (final v in eje) {
      final e = (v - obj).abs();
      if (e < minError) minError = e;
    }
    final cercaSinEntrar = m.segundosHastaEntrar == null && minError <= margen * p.factorCercaAnalisis;

    // Pistas: ¿se acercó después?
    final msVamos = _msEvento(juego, 'vamos', m.indice);
    var pistas = 0, sirvieron = 0;
    if (msVamos != null) {
      for (final ev in juego.eventos) {
        if (ev.tipo != 'pista' || ev.pose != m.indice) continue;
        pistas++;
        final t0 = ev.ms - msVamos; // ms desde "¡Vamos!"
        final t1 = t0 + (p.segundosVentanaPista * 1000).round();
        double? errorAlInicio;
        var mejorError = double.infinity;
        for (var i = 0; i < eje.length; i++) {
          final t = m.recorridoMs[i];
          if (t < t0) continue;
          if (t > t1) break;
          final e = (eje[i] - obj).abs();
          errorAlInicio ??= e;
          if (e < mejorError) mejorError = e;
        }
        if (errorAlInicio != null && errorAlInicio - mejorError >= p.umbralMovimiento) sirvieron++;
      }
    }

    // Tiempo en las viñetas.
    final msVineta = _msEvento(juego, 'vineta', m.indice);
    final enVineta = (msVineta != null && msVamos != null) ? (msVamos - msVineta) / 1000 : null;

    return AnalisisPose(
      ejePrincipal: lateral ? 'lateral' : 'adelante',
      primerMovimiento: primer,
      segundosPrimerMovimiento: tPrimer,
      sePasoDeLargo: sePaso,
      llegoCercaSinEntrar: cercaSinEntrar,
      pistas: pistas,
      pistasQueSirvieron: sirvieron,
      segundosEnVineta: enVineta,
    );
  }

  /// ms (desde el inicio del juego) del ÚLTIMO evento de ese tipo para
  /// esa pose (el último: si tocó "Otra vez", cuenta el más reciente).
  static int? _msEvento(RegistroJuego j, String tipo, int pose) {
    int? ms;
    for (final e in j.eventos) {
      if (e.tipo == tipo && e.pose == pose) ms = e.ms;
    }
    return ms;
  }

  /// Dónde abandonó un juego interrumpido: "pose 2 (pose)" o null.
  static String? dondeAbandono(RegistroJuego j) {
    for (final e in j.eventos.reversed) {
      if (e.tipo == 'salida') {
        return 'pose ${(e.pose ?? 0) + 1}${e.dato == null ? '' : ' (${_fase(e.dato!)})'}';
      }
    }
    return null;
  }

  static String _fase(String f) => switch (f) {
        'explicacion' => 'mirando las viñetas',
        'pose' => 'haciendo la pose',
        'partida' => 'al empezar',
        'logrado' => 'celebrando',
        _ => f,
      };
}
