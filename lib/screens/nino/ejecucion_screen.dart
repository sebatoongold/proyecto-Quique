// ============================================================
// ejecucion_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v11 — paso F9.1b
//
// CAMBIOS v11 respecto a la v10:
//  - El ícono del PINGÜINO se refleja según el lado de la pose: se
//    inclina hacia el mismo lado que la figura en pantalla (con o sin
//    modo espejo). Ver _espejarIcono().
//
// Flujo completo: flujo_nino_actividad_guiada_v1.svg. Sigue pendiente:
// el botón "Escuchar" (requiere una dependencia de voz) y las
// ilustraciones de Quique (por ahora, marcador con carita).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../modelos/animal_postura.dart';
import '../../modelos/datos_postura.dart';
import '../../modelos/juego.dart';
import '../../modelos/parametros_juego.dart';
import '../../modelos/pose.dart';
import '../../modelos/registro_juego.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../servicios/servicio_ble.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/confeti.dart';
import '../../widgets/figura_tu.dart';
import '../../widgets/icono_animal.dart';
import '../../widgets/vinetas_pose.dart';

// ############################################################
// ##  PARÁMETROS AJUSTABLES DEL JUEGO                       ##
// ############################################################
// EN EL PANEL DE PARÁMETROS (valores por defecto en
// modelos/parametros_juego.dart): segundos para mantener cada pose,
// ángulo y márgenes de las poses, segundos hasta la pista y hasta
// ofrecer ayuda, y si se muestran los números de prueba.
//
// Fijos (no suelen necesitar cambios durante el testeo):
// "Cerca" = dentro de este múltiplo del margen (Quique un poco incómodo).
const double factorCerca = 1.8;
// Salidas de la zona más cortas que esto se ignoran (ruido del sensor).
const double graciaSalida = 0.5;
// Postura de partida: cuánto rato quieto y cuánta variación se permite.
const double segundosPartidaQuieto = 2;
const double toleranciaQuieto = 4;
// Suavizado de la figura (más alto = sigue más rápido, menos suave).
const double velocidadSuavizado = 8;
// (La duración de la celebración de cada pose está en el panel.)
// Cerca de la zona (Quique "un poco incómodo") en poses con zona de
// límites: a menos de estas unidades del límite.
const double distanciaCercaRango = 8;
// Límites que se dibujan para el lado "sin límite" de una zona de un
// solo lado (solo dibujo).
const double dibujoZonaMin = -40;
const double dibujoZonaMax = 85;

// --- Pista visible (F8) ---
// Segundos que dura un latido de la flecha (más bajo = late más rápido).
const double periodoLatidoFlecha = 0.9;

// --- Celebración animada (F8) ---
// Saltitos de la figura al lograr una pose: cuántos, cuánto dura cada
// uno y qué tan alto (en cabezas).
const int saltosCelebracion = 2;
const double segundosPorSalto = 0.45;
const double alturaSalto = 0.35;
// Papelitos de confeti al lograr una pose y en el cierre.
const int confetiPose = 40;
const int confetiCierre = 80;
// Cuánto dura el confeti del cierre, y en cuántos segundos van saliendo
// sus papelitos (escalonado: parece una lluvia más que un estallido).
const double segundosConfetiCierre = 4;
const double salidaConfetiCierre = 1.2;
// Tamaño de las miniaturas de las poses en el cierre.
const double anchoMiniaturaCierre = 62;
const double altoMiniaturaCierre = 80;

// --- Tarjetas de postura (F9.1) ---
// Miniatura de la pose en la esquina del juego (antes 70 × 92).
const double anchoMiniatura = 84;
const double altoMiniatura = 110;
// Tamaño del ícono del animal en la tarjeta de la pose y en la miniatura.
const double iconoTarjeta = 56;
const double iconoMiniatura = 24;

enum _Fase { partida, explicacion, pose, logrado, fin }

enum _Comodidad { comodo, pocoIncomodo, incomodo }

enum _OpcionAyuda { seguir, saltar, volverAlRio }

class _Muestra {
  final double t, adelante, lateral;
  _Muestra(this.t, this.adelante, this.lateral);
}

class EjecucionScreen extends StatefulWidget {
  final Juego juego;
  // Poses fijas (pruebas); null = las del juego con los números del panel.
  final List<Pose>? poses;

  const EjecucionScreen({super.key, this.juego = juegoImitaAQuique, this.poses});

  @override
  State<EjecucionScreen> createState() => _EjecucionScreenState();
}

class _EjecucionScreenState extends State<EjecucionScreen>
    with SingleTickerProviderStateMixin {
  final ServicioBle ble = ServicioBle.instancia;

  late final Ticker _ticker;
  double _t = 0; // segundos desde que se abrió la pantalla

  _Fase _fase = _Fase.partida;
  int _indicePose = 0;
  double _progreso = 0; // segundos mantenidos en la pose actual
  double _progresoPartida = 0; // 0..1
  double _inicioLogrado = 0;
  bool _pausado = false;

  // Postura cero (se fija en la postura de partida).
  double _ceroAdelante = 0;
  double _ceroLateral = 0;

  // Valores suavizados de la postura (unidades crudas).
  double _adelante = 0;
  double _lateral = 0;
  bool _hayDato = false;
  DatosPostura? _ultimoDato; // F4: para guardar solo lecturas nuevas en el recorrido
  DateTime _horaVamos = DateTime.now(); // F4: cuándo tocó "¡Vamos!" en la pose actual

  final List<_Muestra> _muestras = [];
  double _ultimoDentro = -100;
  _Comodidad _comodidad = _Comodidad.incomodo;
  String _pista = '';
  double _errorLateral = 0;
  double _errorAdelante = 0;

  // Seguimiento de la pose actual (para ayudas y métricas).
  double _tiempoEnPose = 0; // solo cuenta con conexión y sin pausa
  double _tiempoSinAvance = 0;
  double _ultimaAyudaEn = 0;
  bool _pistaActiva = false;
  // F8: lo que falta se ve en la vista de la figura (la flecha puede ir
  // sobre la figura grande).
  bool _faltaEnLaVista = false;
  double _inicioFin = 0; // F8: para el confeti del cierre
  bool _yaEntro = false;
  bool _estabaDentro = false;
  bool _ayudaAbierta = false;

  // Parámetros y poses de ESTE juego (se fijan al empezar).
  late ParametrosJuego _p;
  late List<Pose> _poses;

  // Registro del juego que se guarda.
  late RegistroJuego _registro;
  bool _registroGuardado = false;
  bool _algunaSaltada = false;
  int? _racha; // se muestra en el cierre

  Pose get _pose => _poses[_indicePose];
  MetricaPose? get _metricaActual =>
      _registro.poses.isEmpty ? null : _registro.poses.last;

  @override
  void initState() {
    super.initState();
    _nuevoRegistro();
    _aplicarCero();
    ble.iniciar(); // por si se entra al juego sin conexión
    _ticker = createTicker(_alTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Lee los parámetros vigentes y empieza un registro nuevo con ellos.
  void _nuevoRegistro() {
    _p = ServicioParametros.instancia.actual.value;
    _poses = widget.poses ?? widget.juego.poses(_p);
    _registro = RegistroJuego(juego: widget.juego.id, inicio: DateTime.now())
      ..parametros = _p.toJson();
  }

  /// Decide de dónde sale la postura cero de este juego.
  void _aplicarCero() {
    final cal = ServicioParticipantes.instancia.activo.value?.calibracion;
    // Juego frontal: su propio tipo de cero (Parámetros → Juego frontal).
    if (widget.juego.esFrontal) {
      final tipo = _p.ceroFrontal;
      if (tipo == 'fijo') {
        _ceroAdelante = 0;
        _ceroLateral = 0;
        _registro
          ..ceroAdelante = 0
          ..ceroLateral = 0
          ..tipoCero = 'fijo';
        _registro.evento('cero', dato: 'fijo');
        _mostrarExplicacion(0); // sin fase de partida
        return;
      }
      if (tipo == 'calibrado' && cal != null) {
        _ceroAdelante = cal.adelante;
        _ceroLateral = cal.lateral;
        _registro
          ..ceroAdelante = cal.adelante
          ..ceroLateral = cal.lateral
          ..tipoCero = 'calibrado';
        _registro.evento('cero', dato: 'calibrado');
        _mostrarExplicacion(0);
        return;
      }
      _registro.tipoCero = tipo == 'calibrado' ? 'automatico_sin_calibracion' : 'automatico';
      _fase = _Fase.partida;
      return;
    }
    if (_p.ceroCalibrado && cal != null) {
      _ceroAdelante = cal.adelante;
      _ceroLateral = cal.lateral;
      _registro
        ..ceroAdelante = cal.adelante
        ..ceroLateral = cal.lateral
        ..tipoCero = 'calibrado';
      _registro.evento('cero', dato: 'calibrado');
      _mostrarExplicacion(0); // sin fase de partida
    } else {
      _registro.tipoCero = _p.ceroCalibrado ? 'automatico_sin_calibracion' : 'automatico';
      _fase = _Fase.partida;
    }
  }

  bool get _costado => widget.juego.vista == VistaFigura.costado;

  /// Segundos para mantener la pose actual (la pose puede tener los suyos).
  double get _segundosPose => _pose.segundos ?? _p.segundosMantener;

  /// Valor de una pose en el eje de la vista (para flechas).
  double _ejeDe(Pose p) => _costado ? p.adelante : p.lateral;

  /// Zona que se DIBUJA de costado: los límites de la pose (o, si no
  /// tiene, objetivo ± margen). El lado "sin límite" se dibuja amplio.
  (double, double) get _zonaDibujo {
    if (_pose.usaRango) {
      return (_pose.adelanteDesde ?? dibujoZonaMin, _pose.adelanteHasta ?? dibujoZonaMax);
    }
    final m = _pose.margenAdelante ?? 10;
    return (_pose.adelante - m, _pose.adelante + m);
  }

  /// F8: la flecha de la pista va sobre la figura grande.
  bool get _flechaEnFigura => _p.pistaAnimada && _pistaActiva && _faltaEnLaVista;

  /// F8: punto del latido de la flecha (0..1).
  double get _latido => 0.5 + 0.5 * math.sin(2 * math.pi * _t / periodoLatidoFlecha);

  /// F8: segundos desde que se logró la pose (para la celebración).
  double get _tiempoCelebrando => _t - _inicioLogrado;

  /// F8: cuánto sube la figura en los saltitos (en cabezas).
  double get _salto {
    if (!_p.celebracionAnimada || _fase != _Fase.logrado) return 0;
    final e = _tiempoCelebrando;
    if (e < 0 || e >= saltosCelebracion * segundosPorSalto) return 0;
    final fraccion = (e % segundosPorSalto) / segundosPorSalto;
    return alturaSalto * math.sin(math.pi * fraccion);
  }

  // ------------------------------------------------------------
  // LÓGICA (se ejecuta en cada cuadro)
  // ------------------------------------------------------------
  void _alTick(Duration transcurrido) {
    final ahora = transcurrido.inMicroseconds / 1e6;
    final dt = (ahora - _t).clamp(0.0, 0.1).toDouble();
    _t = ahora;

    final DatosPostura? d = ble.datos.value;
    if (d != null) {
      final k = 1 - math.exp(-velocidadSuavizado * dt);
      if (!_hayDato) {
        _adelante = d.adelante.toDouble();
        _lateral = d.lateral.toDouble();
        _hayDato = true;
      } else {
        _adelante += (d.adelante - _adelante) * k;
        _lateral += (d.lateral - _lateral) * k;
      }
    }

    // Sin conexión o en pausa, el juego no avanza (el avance queda guardado).
    if (d != null && ble.conectado && !_pausado) {
      switch (_fase) {
        case _Fase.partida:
          _revisarPartida(d, ahora);
        case _Fase.pose:
          _revisarPose(dt, ahora);
        case _Fase.logrado:
          if (ahora - _inicioLogrado >= _p.segundosCelebracion) _despuesDeLaPose();
        case _Fase.explicacion:
        case _Fase.fin:
          break;
      }
    }

    // F4: recorrido de la pose (solo lecturas nuevas, sin pausa).
    if (d != null && !identical(d, _ultimoDato)) {
      _ultimoDato = d;
      if (_fase == _Fase.pose && !_pausado && ble.conectado) {
        final m = _metricaActual;
        if (m != null) {
          m.recorridoMs.add(DateTime.now().difference(_horaVamos).inMilliseconds);
          m.recorridoLateral.add(_redondear(d.lateral - _ceroLateral));
          m.recorridoAdelante.add(_redondear(d.adelante - _ceroAdelante));
        }
      }
    }

    setState(() {});
  }

  static double _redondear(double v) => (v * 10).roundToDouble() / 10;

  void _revisarPartida(DatosPostura d, double ahora) {
    final m = _Muestra(ahora, d.adelante.toDouble(), d.lateral.toDouble());
    _muestras.add(m);
    // Si se movió o el firmware marca mala postura, el conteo vuelve a empezar.
    if (d.malaPostura || !_estaQuieto()) {
      _muestras
        ..clear()
        ..add(m);
    }
    final quietoHace = ahora - _muestras.first.t;
    _progresoPartida = (quietoHace / segundosPartidaQuieto).clamp(0.0, 1.0).toDouble();

    if (quietoHace >= segundosPartidaQuieto) {
      double sumaA = 0, sumaL = 0;
      for (final x in _muestras) {
        sumaA += x.adelante;
        sumaL += x.lateral;
      }
      _ceroAdelante = sumaA / _muestras.length;
      _ceroLateral = sumaL / _muestras.length;
      _registro.ceroAdelante = _ceroAdelante;
      _registro.ceroLateral = _ceroLateral;
      _registro.evento('cero', dato: _registro.tipoCero);
      _muestras.clear();
      _mostrarExplicacion(0);
    }
  }

  bool _estaQuieto() {
    double minA = double.infinity, maxA = -double.infinity;
    double minL = double.infinity, maxL = -double.infinity;
    for (final x in _muestras) {
      minA = math.min(minA, x.adelante);
      maxA = math.max(maxA, x.adelante);
      minL = math.min(minL, x.lateral);
      maxL = math.max(maxL, x.lateral);
    }
    return (maxA - minA) <= toleranciaQuieto && (maxL - minL) <= toleranciaQuieto;
  }

  void _revisarPose(double dt, double ahora) {
    final metrica = _metricaActual!;
    _tiempoEnPose += dt;

    final errorLateral = _pose.lateral - (_lateral - _ceroLateral);
    // Con zona de límites: lo que falta hasta el límite más cercano.
    final errorAdelante = _pose.errorAdelanteDe(_adelante - _ceroAdelante);
    _errorLateral = errorLateral;
    _errorAdelante = errorAdelante;

    final margenL = _pose.margenLateral;
    final margenA = _pose.margenAdelante; // null = no se evalúa
    final okLateral = errorLateral.abs() <= margenL;
    final okAdelante = _pose.adelanteDentro(errorAdelante);

    // F8: ¿lo que falta se ve en esta vista? De costado se ve adelante/atrás;
    // de frente, los lados.
    _faltaEnLaVista = _costado ? !okAdelante : !okLateral;

    if (okLateral && okAdelante) _ultimoDentro = ahora;
    final dentro = ahora - _ultimoDentro <= graciaSalida;

    final cercaLateral = errorLateral.abs() <= margenL * factorCerca;
    final cercaAdelante = _pose.usaRango
        ? errorAdelante.abs() <= distanciaCercaRango
        : (margenA == null || errorAdelante.abs() <= margenA * factorCerca);
    _comodidad = dentro
        ? _Comodidad.comodo
        : (cercaLateral && cercaAdelante ? _Comodidad.pocoIncomodo : _Comodidad.incomodo);

    // Pista: primero lo que la figura NO muestra (encorvarse), después el lado.
    if (dentro) {
      _pista = '';
    } else if (!okAdelante) {
      _pista = errorAdelante < 0
          ? 'Endereza un poquito la espalda'
          : (widget.juego.esFrontal
              ? 'Curva un poquito más la espalda'
              : 'Inclínate un poquito hacia adelante');
    } else {
      _pista = errorLateral < 0
          ? 'Un poquito más hacia tu izquierda'
          : 'Un poquito más hacia tu derecha';
    }

    // --- Métricas ---
    if (dentro && !_yaEntro) {
      _yaEntro = true;
      metrica.segundosHastaEntrar = _tiempoEnPose;
    }
    if (_estabaDentro && !dentro) {
      metrica.salidasDeZona++;
      _registro.evento('salio', pose: _indicePose);
    }
    if (!_estabaDentro && dentro) _registro.evento('entro', pose: _indicePose);
    _estabaDentro = dentro;

    // --- Avance y pista de los 20 s ---
    if (dentro) {
      _tiempoSinAvance = 0;
      _pistaActiva = false;
      _progreso += dt; // fuera de la zona no suma: se congela
      if (_progreso >= _segundosPose) {
        _progreso = _segundosPose;
        metrica.segundosHastaCompletar = _tiempoEnPose;
        metrica.resultado = 'completada';
        _registro.evento('completo', pose: _indicePose);
        _fase = _Fase.logrado;
        _inicioLogrado = ahora;
        return;
      }
    } else {
      _tiempoSinAvance += dt;
      if (_tiempoSinAvance >= _p.segundosPista && !_pistaActiva) {
        _pistaActiva = true;
        metrica.pistasUsadas++;
        _registro.evento('pista', pose: _indicePose, dato: _flechaEnFigura ? 'figura' : 'esquina');
        if (_p.vibrarPista) HapticFeedback.mediumImpact();
      }
    }

    // --- Ayuda al minuto ---
    if (!_ayudaAbierta && _tiempoEnPose - _ultimaAyudaEn >= _p.segundosAyuda) {
      _ayudaAbierta = true;
      _pausado = true;
      metrica.ayudasOfrecidas++;
      _registro.evento('ayuda', pose: _indicePose);
      // Se abre después de dibujar este cuadro (no en medio del cálculo).
      WidgetsBinding.instance.addPostFrameCallback((_) => _ofrecerAyuda());
    }
  }

  void _mostrarExplicacion(int indice) {
    _indicePose = indice;
    _fase = _Fase.explicacion;
    _registro.evento('vineta', pose: indice);
  }

  /// El niño tocó "¡Vamos!": empieza la pose y su registro.
  void _empezarPose() {
    setState(() {
      _registro.poses.add(MetricaPose(indice: _indicePose, instruccion: _pose.instruccion)
        ..animal = _pose.animal.id
        ..objetivoLateral = _pose.lateral
        ..objetivoAdelante = _pose.adelante
        ..margenLateral = _pose.margenLateral
        ..margenAdelante = _pose.margenAdelante
        ..zonaAdelanteDesde = _pose.adelanteDesde
        ..zonaAdelanteHasta = _pose.adelanteHasta);
      _registro.evento('vamos', pose: _indicePose);
      _horaVamos = DateTime.now();
      _progreso = 0;
      _ultimoDentro = -100;
      _comodidad = _Comodidad.incomodo;
      _pista = '';
      _tiempoEnPose = 0;
      _tiempoSinAvance = 0;
      _ultimaAyudaEn = 0;
      _pistaActiva = false;
      _yaEntro = false;
      _estabaDentro = false;
      _fase = _Fase.pose;
    });
  }

  /// Después de completar o saltar una pose: la siguiente, o el cierre.
  void _despuesDeLaPose() {
    if (_indicePose < _poses.length - 1) {
      _mostrarExplicacion(_indicePose + 1);
    } else {
      _terminar();
    }
  }

  void _terminar() {
    _fase = _Fase.fin;
    _inicioFin = _t;
    _registro.evento('fin');
    _registro.completado = !_algunaSaltada &&
        _registro.poses.length == _poses.length &&
        _registro.poses.every((p) => p.completada);
    _guardarRegistro(interrumpido: false).then((_) async {
      final r = await AlmacenamientoJuegos.racha();
      if (mounted) setState(() => _racha = r);
    });
  }

  Future<void> _guardarRegistro({required bool interrumpido}) async {
    if (_registroGuardado) return;
    // Si salió antes de empezar alguna pose, no hay nada que valga guardar.
    if (_registro.poses.isEmpty) return;
    _registroGuardado = true;
    _registro.fin = DateTime.now();
    _registro.interrumpido = interrumpido;
    try {
      await AlmacenamientoJuegos.guardar(_registro);
    } catch (e) {
      debugPrint('No se pudo guardar el juego: $e');
    }
  }

  /// Salir del juego a medias: queda como interrumpido (sin culpa) y se guarda.
  Future<void> _salirDelJuego() async {
    if (_fase != _Fase.fin) {
      _registro.evento('salida', pose: _indicePose, dato: _fase.name);
      await _guardarRegistro(interrumpido: true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _reiniciar() {
    setState(() {
      _nuevoRegistro(); // "Otra vez" usa los parámetros vigentes
      _registro.evento('otra_vez');
      _registroGuardado = false;
      _algunaSaltada = false;
      _racha = null;
      _muestras.clear();
      _progresoPartida = 0;
      _indicePose = 0;
      _progreso = 0;
      _aplicarCero(); // fase de partida, o directo a la explicación
    });
  }

  Future<void> _pausar() async {
    if (_pausado) return;
    setState(() => _pausado = true);
    _registro.evento('pausa', pose: _indicePose);
    final salir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Seguimos después?'),
        content: const Text('Si sales ahora, Quique te espera para la próxima.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _registro.evento('pausa_resp', pose: _indicePose, dato: salir == true ? 'salir' : 'seguir');
    if (salir == true) {
      await _salirDelJuego();
    } else {
      setState(() => _pausado = false);
    }
  }

  Future<void> _ofrecerAyuda() async {
    if (!mounted) return;
    final opcion = await showDialog<_OpcionAyuda>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const CircleAvatar(
          radius: 34,
          backgroundColor: Colores.quique,
          child: Icon(Icons.sentiment_neutral_rounded, size: 40, color: Colores.quiqueClaro),
        ),
        title: const Text('¡Esta pose es difícil!', textAlign: TextAlign.center),
        content: const Text('¿Qué hacemos?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_OpcionAyuda.seguir),
            child: const Text('Seguir intentando'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(_OpcionAyuda.saltar),
            child: const Text('Saltar esta pose'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_OpcionAyuda.volverAlRio),
            child: const Text('Volver al río'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _ayudaAbierta = false;
    _registro.evento('ayuda_resp', pose: _indicePose, dato: switch (opcion) {
      _OpcionAyuda.saltar => 'saltar',
      _OpcionAyuda.volverAlRio => 'salir',
      _ => 'seguir',
    });
    switch (opcion) {
      case _OpcionAyuda.saltar:
        // Queda como "intentada" (ya es el valor por defecto).
        _algunaSaltada = true;
        setState(() {
          _pausado = false;
          _despuesDeLaPose();
        });
      case _OpcionAyuda.volverAlRio:
        await _salirDelJuego();
      case _OpcionAyuda.seguir:
      case null:
        setState(() {
          _ultimaAyudaEn = _tiempoEnPose; // la próxima oferta, en otro minuto
          _pausado = false;
        });
    }
  }

  Future<void> _pedirAyudaAdulto() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.family_restroom_rounded, size: 40, color: Colores.azul),
        title: const Text('Para el adulto'),
        content: const Text(
          '1. Revisa que el cinturón esté encendido.\n'
          '2. Revisa que el Bluetooth del teléfono esté activado.\n'
          '3. Acerca el teléfono al cinturón.\n\n'
          'La app se conecta sola apenas lo encuentra.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PANTALLA
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final conectado = ble.conectado && ble.datos.value != null;

    Widget contenido;
    if (_fase == _Fase.fin) {
      contenido = _cierre();
    } else if (_fase == _Fase.explicacion) {
      contenido = _explicacion();
    } else {
      contenido = _juego(conectado);
    }

    // El botón "atrás" del teléfono no saca al niño de golpe: pregunta.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_fase == _Fase.fin) {
          Navigator.of(context).pop();
        } else {
          _pausar();
        }
      },
      child: Scaffold(
        backgroundColor: Colores.arena,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: contenido,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Fase: explicación con viñetas ----------
  Widget _explicacion() {
    final anterior = _indicePose == 0 ? null : _poses[_indicePose - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(),
        _indicadorPoses(),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: VinetasPose(
            pose: _pose,
            lateralInicio: anterior?.lateral ?? 0,
            adelanteInicio: anterior?.adelante ?? 0,
            vista: widget.juego.vista,
          ),
        ),
        const SizedBox(height: 16),
        _tarjetaPose(),
        const SizedBox(height: 12),
        _quique(true, fraseFija: '¡Mira cómo se hace!', caraFija: Icons.sentiment_satisfied_rounded),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 60)),
          onPressed: _empezarPose,
          child: const Text('¡Vamos!'),
        ),
      ],
    );
  }

  // ---------- Fases: partida, pose y logrado ----------
  Widget _juego(bool conectado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(),
        if (_fase != _Fase.partida) _indicadorPoses(),
        const SizedBox(height: 8),
        _instruccion(),
        const SizedBox(height: 12),
        Expanded(child: conectado ? _areaFigura() : _sinCinturon()),
        const SizedBox(height: 12),
        _quique(conectado),
        const SizedBox(height: 12),
        _avance(),
      ],
    );
  }

  Widget _encabezado() {
    final titulo = _fase == _Fase.partida
        ? widget.juego.nombre
        : 'Pose ${_indicePose + 1} de ${_poses.length}';
    return Row(
      children: [
        IconButton(
          tooltip: 'Salir',
          icon: const Icon(Icons.close_rounded, color: Colores.azul),
          onPressed: _pausar,
        ),
        Expanded(
          child: Text(titulo, textAlign: TextAlign.center, style: Textos.cuerpoDestacado),
        ),
        IconButton(
          tooltip: 'Pausa',
          icon: const Icon(Icons.pause_rounded, color: Colores.azul),
          onPressed: _pausar,
        ),
      ],
    );
  }

  /// Puntos que muestran en qué pose va (●○○).
  Widget _indicadorPoses() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _poses.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= _indicePose ? Colores.bosque : Colores.linea,
            ),
          ),
      ],
    );
  }

  Widget _tarjetaTexto(String grande, String chico) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colores.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(grande,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colores.azul)),
          if (chico.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(chico, style: Textos.secundario.copyWith(fontSize: 15)),
          ],
        ],
      ),
    );
  }

  /// F9.1b: el ícono del pingüino (inclinado hacia la izquierda de la
  /// pantalla) se refleja si la figura se inclina hacia la derecha de la
  /// pantalla. Mismo signo que usa figura_tu.dart para la vista de frente.
  bool _espejarIcono(Pose pose) {
    if (pose.animal != AnimalPostura.pinguino) return false;
    final haciaDerechaPantalla = pose.lateral * (_p.espejo ? 1 : -1) > 0;
    return haciaDerechaPantalla;
  }

  /// F9.1: tarjeta de la pose: ícono del animal, "¡Sé una tortuga!" y,
  /// debajo, la instrucción y el detalle.
  Widget _tarjetaPose() {
    final animal = _pose.animal;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: animal.borde, width: 2),
      ),
      child: Row(
        children: [
          IconoAnimal(animal: animal, tamano: iconoTarjeta, espejar: _espejarIcono(_pose)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.llamado,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colores.azul)),
                const SizedBox(height: 2),
                Text(_pose.instruccion,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colores.azul)),
                if (_pose.detalle.isNotEmpty)
                  Text(_pose.detalle, style: Textos.secundario.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instruccion() {
    switch (_fase) {
      case _Fase.partida:
        return _tarjetaTexto('Siéntate derecho y quédate quieto',
            'Así Quique conoce tu postura cómoda.');
      case _Fase.logrado:
        return _tarjetaTexto('¡Lo lograste!',
            _pose.animal.felicitacion + (_indicePose < _poses.length - 1 ? ' Vamos con la siguiente.' : ''));
      default:
        return _tarjetaPose();
    }
  }

  Color get _colorEstado {
    if (_fase == _Fase.partida) return Colores.rio;
    if (_fase == _Fase.logrado) return Colores.comodo;
    return switch (_comodidad) {
      _Comodidad.comodo => Colores.comodo,
      _Comodidad.pocoIncomodo => Colores.pocoIncomodo,
      _Comodidad.incomodo => Colores.incomodo,
    };
  }

  Widget _areaFigura() {
    final enPartida = _fase == _Fase.partida;
    return Container(
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: enPartida ? Colores.linea : _colorEstado, width: 3),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FiguraTu(
                adelante: _adelante - _ceroAdelante,
                lateral: _lateral - _ceroLateral,
                siluetaAdelante: enPartida ? 0 : _pose.adelante,
                siluetaLateral: enPartida ? 0 : _pose.lateral,
                color: _colorEstado,
                vista: widget.juego.vista,
                brazosSilueta: enPartida ? ModoBrazos.apoyados : _pose.brazos,
                // De frente: zona = silueta ± margen lateral.
                margenLateral: enPartida || _costado ? null : _pose.margenLateral,
                // De costado: zona en el eje adelante (puede ser de un solo lado).
                zonaDesde: enPartida || !_costado ? null : _zonaDibujo.$1,
                zonaHasta: enPartida || !_costado ? null : _zonaDibujo.$2,
                // F8: la pista, sobre la figura grande: desde cómo está
                // sentado hasta la pose, latiendo.
                flechaDesde: _flechaEnFigura ? (_costado ? _adelante - _ceroAdelante : _lateral - _ceroLateral) : null,
                flechaHasta: _flechaEnFigura ? _ejeDe(_pose) : null,
                pulsoFlecha: _flechaEnFigura ? _latido : null,
                salto: _salto,
              ),
            ),
          ),
          // F8: confeti al lograr la pose.
          if (_fase == _Fase.logrado && _p.celebracionAnimada)
            Positioned.fill(
              child: IgnorePointer(
                child: Confeti(
                  tiempo: _tiempoCelebrando,
                  duracion: _p.segundosCelebracion,
                  cantidad: confetiPose,
                  semilla: _indicePose + 1,
                ),
              ),
            ),
          // Miniatura de la pose: siempre a mano. Se destaca con la pista.
          if (!enPartida)
            Positioned(
              top: 10,
              left: 10,
              width: anchoMiniatura,
              height: altoMiniatura,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colores.tarjeta,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _pistaActiva ? Colores.ambar : Colores.azul,
                    width: _pistaActiva ? 4 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                      child: FiguraTu(
                        adelante: _pose.adelante,
                        lateral: _pose.lateral,
                        siluetaAdelante: 0,
                        siluetaLateral: 0,
                        color: Colores.comodo,
                        mostrarSilueta: false,
                        mostrarSensores: false,
                        mostrarSilla: false,
                        vista: widget.juego.vista,
                        brazos: _pose.brazos,
                        // Con la pista: flecha desde la pose anterior hasta esta
                        // (en el eje de la vista), salvo que ya esté sobre la
                        // figura grande (F8).
                        flechaDesde: _pistaActiva && !_flechaEnFigura
                            ? (_indicePose == 0 ? 0 : _ejeDe(_poses[_indicePose - 1]))
                            : null,
                        flechaHasta: _pistaActiva && !_flechaEnFigura ? _ejeDe(_pose) : null,
                      ),
                          ),
                          // F9.1: ícono del animal, arriba a la derecha.
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconoAnimal(
                                animal: _pose.animal, tamano: iconoMiniatura, espejar: _espejarIcono(_pose)),
                          ),
                        ],
                      ),
                    ),
                    // F9.1: el animal de la pose en vez de "la pose".
                    Text(_pose.animal.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colores.azul)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 16,
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: _colorEstado),
                const SizedBox(width: 4),
                const Text('Tú',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colores.azul)),
              ],
            ),
          ),
          if (_p.mostrarNumeros && !enPartida)
            Positioned(
              left: 14,
              bottom: 10,
              child: Text(
                'lado: falta ${_errorLateral.toStringAsFixed(0)} (±${_pose.margenLateral.toStringAsFixed(0)})   '
                'adelante: falta ${_errorAdelante.toStringAsFixed(0)}'
                '${_pose.usaRango ? ' (zona ${_pose.adelanteDesde?.toStringAsFixed(0) ?? '−∞'}…${_pose.adelanteHasta?.toStringAsFixed(0) ?? '∞'})' : _pose.margenAdelante == null ? ' (no cuenta)' : ' (±${_pose.margenAdelante!.toStringAsFixed(0)})'}',
                style: const TextStyle(fontSize: 11, color: Colores.textoSecundario),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sinCinturon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colores.linea),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.bluetooth_searching_rounded, size: 56, color: Colores.rio),
          const SizedBox(height: 16),
          const Text(
            '¡Necesito tu cinturón para jugar!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colores.azul),
          ),
          const SizedBox(height: 8),
          const Text(
            'Póntelo y acércate al teléfono. Te espero.',
            textAlign: TextAlign.center,
            style: Textos.secundario,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 48),
              shape: const StadiumBorder(),
              foregroundColor: Colores.azul,
            ),
            icon: const Icon(Icons.family_restroom_rounded),
            label: const Text('Pedir ayuda a un adulto'),
            onPressed: _pedirAyudaAdulto,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _salirDelJuego,
            child: const Text('Volver al río',
                style: TextStyle(color: Colores.textoSecundario, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  /// Marcador provisorio de Quique: círculo con su "cara" según cómo se
  /// siente, y su frase. Se reemplazará por las ilustraciones.
  Widget _quique(bool conectado, {String? fraseFija, IconData? caraFija}) {
    IconData cara = Icons.sentiment_satisfied_rounded;
    String frase = '';
    if (fraseFija != null) {
      frase = fraseFija;
      cara = caraFija ?? cara;
    } else if (!conectado) {
      cara = Icons.sentiment_neutral_rounded;
      frase = '¡Te espero!';
    } else if (_fase == _Fase.partida) {
      frase = '¡Siéntate derecho como yo!';
    } else if (_fase == _Fase.logrado) {
      cara = Icons.celebration_rounded;
      frase = '¡Lo lograste!';
    } else {
      switch (_comodidad) {
        case _Comodidad.comodo:
          cara = Icons.sentiment_very_satisfied_rounded;
          frase = '¡Qué cómodo!';
        case _Comodidad.pocoIncomodo:
          cara = Icons.sentiment_neutral_rounded;
          frase = _pista.isEmpty ? 'Un poquito más…' : _pista;
        case _Comodidad.incomodo:
          cara = Icons.sentiment_dissatisfied_rounded;
          frase = _pista.isEmpty ? '¡Ayúdame a llegar a la pose!' : _pista;
      }
      if (_pistaActiva && _comodidad != _Comodidad.comodo) {
        frase = _flechaEnFigura
            ? '$frase. ¡Sigue la flecha!'
            : '$frase. ¡Mira ${_pose.animal.conArticulo} de la esquina!';
      }
    }
    final colorBorde = fraseFija != null ? Colores.linea : (conectado ? _colorEstado : Colores.linea);
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colores.quique,
            shape: BoxShape.circle,
            border: Border.all(color: colorBorde, width: 3),
          ),
          child: Icon(cara, size: 38, color: Colores.quiqueClaro),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colores.tarjeta,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colores.linea),
            ),
            child: Text(frase,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colores.azul)),
          ),
        ),
      ],
    );
  }

  Widget _avance() {
    final enPartida = _fase == _Fase.partida;
    final valor = enPartida ? _progresoPartida : _progreso / _segundosPose;
    final texto = enPartida
        ? 'Quédate quieto un momentito…'
        : '${_progreso.floor()} de ${_segundosPose.round()} segundos';
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LinearProgressIndicator(
            value: valor,
            minHeight: 24,
            color: enPartida ? Colores.comodo : Colores.rio,
            backgroundColor: const Color(0xFFE3EBF2),
          ),
        ),
        const SizedBox(height: 8),
        Text(texto, style: Textos.cuerpoDestacado),
      ],
    );
  }

  // ---------- Fase: cierre ----------
  Widget _cierre() {
    // Se celebra el esfuerzo, sin comparar con días anteriores.
    final todoCompletado = _registro.completado;
    final titulo = todoCompletado ? '¡Muy bien hecho!' : '¡Buen intento!';
    final subtitulo = todoCompletado
        ? 'Terminaste «${widget.juego.nombre}».'
        : 'La próxima lo logramos juntos.';
    final animada = _p.celebracionAnimada;
    final columna = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // F8: con la celebración animada, las poses del juego con su ✓.
        if (animada)
          _posesDelCierre()
        else
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colores.quique,
            child: Icon(Icons.celebration_rounded, size: 64, color: Colores.quiqueClaro),
          ),
        const SizedBox(height: 24),
        Text(titulo, textAlign: TextAlign.center, style: Textos.titulo),
        const SizedBox(height: 6),
        Text(subtitulo, textAlign: TextAlign.center, style: Textos.cuerpo),
        const SizedBox(height: 16),
        // Racha sin presión: una hoja y los días.
        if (_racha != null && _racha! > 0)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0DE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded, color: Colores.bosqueClaro),
                  const SizedBox(width: 6),
                  Text(
                    _racha == 1 ? '1 día' : '$_racha días',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colores.bosque),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver al río'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            shape: const StadiumBorder(),
            foregroundColor: Colores.azul,
          ),
          onPressed: _reiniciar,
          child: const Text('Otra vez'),
        ),
      ],
    );
    if (!animada) return columna;
    return Stack(
      children: [
        columna,
        // Confeti que cae desde arriba (no tapa los botones al tocarlos).
        Positioned.fill(
          child: IgnorePointer(
            child: Confeti(
              tiempo: _t - _inicioFin,
              duracion: segundosConfetiCierre,
              cantidad: confetiCierre,
              origen: const Offset(0.5, 0.3),
              semilla: 99,
              salidaEscalonada: salidaConfetiCierre,
            ),
          ),
        ),
      ],
    );
  }

  /// F8: las poses del juego en miniatura. Las logradas, en verde y con
  /// ✓; las demás, tenues (sin cruz: se celebra el esfuerzo).
  Widget _posesDelCierre() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _poses.length; i++)
          _miniaturaCierre(
            _poses[i],
            _registro.poses.any((m) => m.indice == i && m.completada),
          ),
      ],
    );
  }

  Widget _miniaturaCierre(Pose pose, bool lograda) {
    return Opacity(
      opacity: lograda ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _figuraCierre(pose, lograda),
          const SizedBox(height: 4),
          // F9.1: el nombre del animal debajo.
          Text(pose.animal.nombre,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colores.azul)),
        ],
      ),
    );
  }

  Widget _figuraCierre(Pose pose, bool lograda) {
    return SizedBox(
        width: anchoMiniaturaCierre,
        height: altoMiniaturaCierre,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colores.tarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lograda ? Colores.comodo : Colores.linea, width: 2),
                ),
                child: FiguraTu(
                  adelante: pose.adelante,
                  lateral: pose.lateral,
                  siluetaAdelante: 0,
                  siluetaLateral: 0,
                  color: lograda ? Colores.comodo : Colores.incomodo,
                  mostrarSilueta: false,
                  mostrarSensores: false,
                  mostrarSilla: false,
                  vista: widget.juego.vista,
                  brazos: pose.brazos,
                ),
              ),
            ),
            if (lograda)
              const Positioned(
                right: -6,
                top: -6,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colores.comodo,
                  child: Icon(Icons.check_rounded, size: 16, color: Colores.tarjeta),
                ),
              ),
          ],
        ),
      );
  }
}
