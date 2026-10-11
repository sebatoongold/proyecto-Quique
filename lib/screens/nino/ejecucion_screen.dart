// ============================================================
// ejecucion_screen.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso C4, corrección tras la primera prueba física
//
// CAMBIOS v2 respecto a la v1:
//  - La pose se evalúa POR EJE, con los márgenes de cada pose
//    (pose.dart), en vez de una sola distancia que mezclaba lateral y
//    encorvamiento. Los márgenes son más amplios.
//  - Quique dice QUÉ corregir y hacia dónde: "un poquito más hacia tu
//    izquierda", "endereza un poquito la espalda", etc. Es la única
//    forma de avisar el encorvamiento, que de frente no se dibuja.
//  - La figura muestra la zona de la pose (cuña clara).
//  - Postura de partida: además de estar quieto, el firmware no debe
//    marcar mala postura (evita guardar un "cero" encorvado).
//  - Datos de prueba en pantalla (números), para calibrar en las
//    pruebas. Se apagan con "mostrarDatosDePrueba".
//
// Versión mínima del flujo de la actividad guiada (fases 2, 3 y 5):
//  1. POSTURA DE PARTIDA: el niño se sienta derecho y se queda quieto
//     2 segundos. Esa postura se guarda como su "postura cero" (una
//     calibración provisoria, hasta que exista la calibración real).
//  2. POSES: para cada pose, la figura «Tú» se mueve en vivo sobre la
//     silueta objetivo. Dentro de la zona, el avance se llena; si
//     sale, el avance se CONGELA (no se reinicia).
//  3. CIERRE: "¡Muy bien hecho!", con "Otra vez" o "Volver".
// Si el cinturón se desconecta, todo se pausa solo y Quique espera.
//
// Quique aparece como un marcador provisorio (ícono de carita), hasta
// tener sus ilustraciones. Todavía NO están: viñetas, pistas a los
// 20 s, ayuda al minuto, ni guardado de datos (pasos siguientes).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../modelos/datos_postura.dart';
import '../../modelos/pose.dart';
import '../../servicios/servicio_ble.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/figura_tu.dart';

// ############################################################
// ##  PARÁMETROS AJUSTABLES DEL JUEGO                       ##
// ############################################################
// Segundos que hay que mantener cada pose.
const double segundosParaCompletar = 10;
// Los márgenes de cada pose están en modelos/pose.dart.
// "Cerca" = dentro de este múltiplo del margen (Quique un poco incómodo).
const double factorCerca = 1.8;
// Muestra números de prueba sobre la figura (útil para calibrar).
// Poner en false para el testeo con niños.
const bool mostrarDatosDePrueba = true;
// Salidas de la zona más cortas que esto se ignoran (ruido del sensor).
const double graciaSalida = 0.5;
// Postura de partida: cuánto rato quieto y cuánta variación se permite.
const double segundosPartidaQuieto = 2;
const double toleranciaQuieto = 4;
// Suavizado de la figura: los datos llegan ~3 veces por segundo; sin
// suavizar, la figura saltaría. Más alto = sigue más rápido, menos suave.
const double velocidadSuavizado = 8;
// Duración de la celebración breve al completar una pose.
const double segundosCelebracion = 1.5;

enum _Fase { partida, pose, logrado, fin }

enum _Comodidad { comodo, pocoIncomodo, incomodo }

class _Muestra {
  final double t, adelante, lateral;
  _Muestra(this.t, this.adelante, this.lateral);
}

class EjecucionScreen extends StatefulWidget {
  final List<Pose> poses;

  const EjecucionScreen({super.key, this.poses = posesImitaAQuique});

  @override
  State<EjecucionScreen> createState() => _EjecucionScreenState();
}

class _EjecucionScreenState extends State<EjecucionScreen>
    with SingleTickerProviderStateMixin {
  final ServicioBle ble = ServicioBle.instancia;

  // Un "ticker" llama a _alTick en cada cuadro de la pantalla (~60 veces
  // por segundo): ahí se suaviza la figura y se cuenta el tiempo.
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

  final List<_Muestra> _muestras = [];
  double _ultimoDentro = -100;
  _Comodidad _comodidad = _Comodidad.incomodo;
  String _pista = ''; // qué corregir, lo dice Quique
  double _errorLateral = 0; // para los datos de prueba
  double _errorAdelante = 0;

  Pose get _pose => widget.poses[_indicePose];

  @override
  void initState() {
    super.initState();
    ble.iniciar(); // por si se entra al juego sin conexión
    _ticker = createTicker(_alTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
      // Suavizado exponencial: acerca la figura al dato real de a poco.
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
          if (ahora - _inicioLogrado >= segundosCelebracion) _siguientePose();
        case _Fase.fin:
          break;
      }
    }

    setState(() {});
  }

  void _revisarPartida(DatosPostura d, double ahora) {
    final m = _Muestra(ahora, d.adelante.toDouble(), d.lateral.toDouble());
    _muestras.add(m);

    // Si el niño se movió más de lo permitido, o el firmware detecta mala
    // postura, el conteo vuelve a empezar.
    if (d.malaPostura || !_estaQuieto()) {
      _muestras
        ..clear()
        ..add(m);
    }

    final quietoHace = ahora - _muestras.first.t;
    _progresoPartida = (quietoHace / segundosPartidaQuieto).clamp(0.0, 1.0).toDouble();

    if (quietoHace >= segundosPartidaQuieto) {
      // Se guarda el promedio como "postura cero".
      double sumaA = 0, sumaL = 0;
      for (final x in _muestras) {
        sumaA += x.adelante;
        sumaL += x.lateral;
      }
      _ceroAdelante = sumaA / _muestras.length;
      _ceroLateral = sumaL / _muestras.length;
      _muestras.clear();
      _empezarPose(0);
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
    // Error en cada eje: cuánto falta (+) o sobra (−) respecto a la pose.
    final errorLateral = _pose.lateral - (_lateral - _ceroLateral);
    final errorAdelante = _pose.adelante - (_adelante - _ceroAdelante);
    _errorLateral = errorLateral;
    _errorAdelante = errorAdelante;

    final margenL = _pose.margenLateral;
    final margenA = _pose.margenAdelante; // null = no se evalúa
    final okLateral = errorLateral.abs() <= margenL;
    final okAdelante = margenA == null || errorAdelante.abs() <= margenA;

    if (okLateral && okAdelante) _ultimoDentro = ahora;
    // Si salió hace menos de "graciaSalida", se cuenta como dentro.
    final dentro = ahora - _ultimoDentro <= graciaSalida;

    final cercaLateral = errorLateral.abs() <= margenL * factorCerca;
    final cercaAdelante = margenA == null || errorAdelante.abs() <= margenA * factorCerca;
    _comodidad = dentro
        ? _Comodidad.comodo
        : (cercaLateral && cercaAdelante ? _Comodidad.pocoIncomodo : _Comodidad.incomodo);

    // Pista: primero lo que la figura NO muestra (encorvarse), después el lado.
    if (dentro) {
      _pista = '';
    } else if (!okAdelante) {
      _pista = errorAdelante < 0
          ? 'Endereza un poquito la espalda'
          : 'Inclínate un poquito hacia adelante';
    } else {
      _pista = errorLateral < 0
          ? 'Un poquito más hacia tu izquierda'
          : 'Un poquito más hacia tu derecha';
    }

    if (dentro) {
      _progreso += dt; // fuera de la zona, simplemente no suma (se congela)
      if (_progreso >= segundosParaCompletar) {
        _progreso = segundosParaCompletar;
        _fase = _Fase.logrado;
        _inicioLogrado = ahora;
      }
    }
  }

  void _empezarPose(int indice) {
    _indicePose = indice;
    _progreso = 0;
    _ultimoDentro = -100;
    _comodidad = _Comodidad.incomodo;
    _pista = '';
    _fase = _Fase.pose;
  }

  void _siguientePose() {
    if (_indicePose < widget.poses.length - 1) {
      _empezarPose(_indicePose + 1);
    } else {
      _fase = _Fase.fin;
    }
  }

  void _reiniciar() {
    setState(() {
      _muestras.clear();
      _progresoPartida = 0;
      _indicePose = 0;
      _progreso = 0;
      _fase = _Fase.partida;
    });
  }

  Future<void> _pausar() async {
    setState(() => _pausado = true);
    final salir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Seguimos después?'),
        content: const Text('Tu avance queda guardado mientras juegas.'),
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
    if (salir == true) {
      Navigator.of(context).pop();
    } else {
      setState(() => _pausado = false);
    }
  }

  // ------------------------------------------------------------
  // PANTALLA
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final conectado = ble.conectado && ble.datos.value != null;

    return Scaffold(
      backgroundColor: Colores.arena,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _fase == _Fase.fin ? _cierre() : _juego(conectado),
            ),
          ),
        ),
      ),
    );
  }

  Widget _juego(bool conectado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _encabezado(),
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
        ? 'Imita a Quique'
        : 'Pose ${_indicePose + 1} de ${widget.poses.length}';
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

  Widget _instruccion() {
    String grande = '';
    String chico = '';
    switch (_fase) {
      case _Fase.partida:
        grande = 'Siéntate derecho y quédate quieto';
        chico = 'Así Quique conoce tu postura cómoda.';
      case _Fase.pose:
        grande = _pose.instruccion;
        chico = _pose.detalle;
      case _Fase.logrado:
        grande = '¡Lo lograste!';
        chico = _indicePose < widget.poses.length - 1 ? 'Vamos con la siguiente.' : '';
      case _Fase.fin:
        grande = '';
        chico = '';
    }
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
          Text(grande, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colores.azul)),
          if (chico.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(chico, style: Textos.secundario.copyWith(fontSize: 15)),
          ],
        ],
      ),
    );
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
                // En la partida aún no hay postura cero: se muestra tal cual.
                adelante: _adelante - _ceroAdelante,
                lateral: _lateral - _ceroLateral,
                siluetaAdelante: enPartida ? 0 : _pose.adelante,
                siluetaLateral: enPartida ? 0 : _pose.lateral,
                color: _colorEstado,
                margenLateral: enPartida ? null : _pose.margenLateral,
              ),
            ),
          ),
          if (mostrarDatosDePrueba && !enPartida)
            Positioned(
              left: 14,
              bottom: 10,
              child: Text(
                'lado: falta ${_errorLateral.toStringAsFixed(0)} (±${_pose.margenLateral.toStringAsFixed(0)})   '
                'adelante: falta ${_errorAdelante.toStringAsFixed(0)}'
                '${_pose.margenAdelante == null ? ' (no cuenta)' : ' (±${_pose.margenAdelante!.toStringAsFixed(0)})'}',
                style: const TextStyle(fontSize: 11, color: Colores.textoSecundario),
              ),
            ),
          Positioned(
            top: 12,
            right: 16,
            child: Row(
              children: [
                Icon(Icons.circle, size: 12, color: _colorEstado),
                const SizedBox(width: 4),
                const Text('Tú', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colores.azul)),
                const SizedBox(width: 12),
                const Icon(Icons.square_rounded, size: 13, color: Colores.silueta),
                const SizedBox(width: 4),
                const Text('la pose', style: TextStyle(fontSize: 13, color: Colores.textoSecundario)),
              ],
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching_rounded, size: 56, color: Colores.rio),
          SizedBox(height: 16),
          Text(
            '¡Necesito tu cinturón para jugar!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colores.azul),
          ),
          SizedBox(height: 8),
          Text(
            'Póntelo y acércate al teléfono. Te espero.',
            textAlign: TextAlign.center,
            style: Textos.secundario,
          ),
        ],
      ),
    );
  }

  /// Marcador provisorio de Quique: un círculo con su "cara" según cómo
  /// se siente, y su frase. Se reemplazará por las ilustraciones.
  Widget _quique(bool conectado) {
    IconData cara = Icons.sentiment_satisfied_rounded;
    String frase = '';
    if (!conectado) {
      cara = Icons.sentiment_neutral_rounded;
      frase = '¡Te espero!';
    } else if (_fase == _Fase.partida) {
      cara = Icons.sentiment_satisfied_rounded;
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
    }
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: Colores.quique, shape: BoxShape.circle,
              border: Border.all(color: conectado ? _colorEstado : Colores.linea, width: 3)),
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
            child: Text(frase, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colores.azul)),
          ),
        ),
      ],
    );
  }

  Widget _avance() {
    final enPartida = _fase == _Fase.partida;
    final valor = enPartida ? _progresoPartida : _progreso / segundosParaCompletar;
    final texto = enPartida
        ? 'Quédate quieto un momentito…'
        : '${_progreso.floor()} de ${segundosParaCompletar.round()} segundos';
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

  Widget _cierre() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: Colores.quique,
          child: Icon(Icons.celebration_rounded, size: 64, color: Colores.quiqueClaro),
        ),
        const SizedBox(height: 24),
        const Text('¡Muy bien hecho!', textAlign: TextAlign.center, style: Textos.titulo),
        const SizedBox(height: 6),
        const Text('Terminaste «Imita a Quique».', textAlign: TextAlign.center, style: Textos.cuerpo),
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
  }
}
