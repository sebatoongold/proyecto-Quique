// ============================================================
// calibracion_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F3 (calibración con botón)
//
// Mide la POSTURA NEUTRAL de un participante y la guarda en su perfil.
// Lo maneja el INVESTIGADOR, con el niño sentado y el cinturón puesto.
//
// Pasos:
//  1. Elegir la frase que se le dice al niño (queda registrada):
//       "Siéntate cómodo"        -> mide su postura habitual (puede
//                                   ser encorvada);
//       "Siéntate alto y cómodo" -> mide su postura erguida cómoda.
//  2. Botón "Empezar": cuenta regresiva para que se acomode.
//  3. Captura: se promedian las lecturas durante unos segundos. Si se
//     mueve demasiado, la captura se reinicia sola y lo avisa.
//  4. Resultado: valores, cuánto se movió y qué parte del tiempo el
//     firmware marcó mala postura (con su umbral fijo). Guardar o repetir.
//
// NO cambia todavía cómo detecta el cinturón: eso es el paso F7. En el
// juego se puede usar como "cero" (Parámetros del juego → tipo de cero).
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../modelos/datos_postura.dart';
import '../../modelos/participante.dart';
import '../../servicios/servicio_ble.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Segundos de cuenta regresiva antes de empezar a medir.
const int segundosCuentaRegresiva = 3;
// Segundos que dura la captura.
const double segundosCaptura = 8;
// Cuánto puede variar la postura durante la captura (máx − mín, en
// unidades, en cualquiera de los dos ejes). Si se pasa, se reinicia.
const double toleranciaCalibracion = 6;
// Mínimo de lecturas para aceptar la captura (llegan ~3 por segundo).
const int minimoMuestras = 12;
// Frases que se pueden elegir (la elegida se guarda con la calibración).
const List<String> frasesCalibracion = [
  'Siéntate cómodo',
  'Siéntate alto y cómodo',
];

enum _Etapa { preparar, cuenta, captura, resultado }

class CalibracionScreen extends StatefulWidget {
  final Participante participante;

  const CalibracionScreen({super.key, required this.participante});

  @override
  State<CalibracionScreen> createState() => _CalibracionScreenState();
}

class _CalibracionScreenState extends State<CalibracionScreen> {
  final ble = ServicioBle.instancia;

  _Etapa _etapa = _Etapa.preparar;
  String _frase = frasesCalibracion.first;
  int _cuenta = segundosCuentaRegresiva;
  Timer? _reloj;
  final Stopwatch _cronometro = Stopwatch();
  final List<DatosPostura> _muestras = [];
  int _reinicios = 0;
  String _aviso = '';
  Calibracion? _resultado;

  @override
  void initState() {
    super.initState();
    ble.iniciar(); // por si se entra sin conexión
    ble.datos.addListener(_alLlegarDato);
  }

  @override
  void dispose() {
    ble.datos.removeListener(_alLlegarDato);
    _reloj?.cancel();
    super.dispose();
  }

  // ---------------- Lógica ----------------

  void _empezar() {
    _reloj?.cancel();
    setState(() {
      _etapa = _Etapa.cuenta;
      _cuenta = segundosCuentaRegresiva;
      _reinicios = 0;
      _aviso = '';
      _resultado = null;
    });
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cuenta <= 1) {
        t.cancel();
        _iniciarCaptura();
      } else {
        setState(() => _cuenta--);
      }
    });
  }

  void _iniciarCaptura() {
    _muestras.clear();
    _cronometro
      ..reset()
      ..start();
    setState(() => _etapa = _Etapa.captura);
    // Refresca la barra de avance y revisa si ya terminó.
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _etapa != _Etapa.captura) return;
      final listo = _cronometro.elapsedMilliseconds / 1000 >= segundosCaptura &&
          _muestras.length >= minimoMuestras;
      if (listo) {
        _terminarCaptura();
      } else {
        setState(() {});
      }
    });
  }

  void _alLlegarDato() {
    if (_etapa != _Etapa.captura) return;
    final d = ble.datos.value;
    if (d == null) return;
    _muestras.add(d);
    if (_variacion(_muestras) > toleranciaCalibracion) {
      // Se movió: se reinicia la captura (sin volver a la cuenta regresiva).
      _reinicios++;
      _aviso = 'Se movió un poco: empezamos a medir de nuevo.';
      _muestras
        ..clear()
        ..add(d);
      _cronometro
        ..reset()
        ..start();
    }
  }

  static double _variacion(List<DatosPostura> m) {
    if (m.isEmpty) return 0;
    var minA = double.infinity, maxA = -double.infinity;
    var minL = double.infinity, maxL = -double.infinity;
    for (final d in m) {
      minA = math.min(minA, d.adelante.toDouble());
      maxA = math.max(maxA, d.adelante.toDouble());
      minL = math.min(minL, d.lateral.toDouble());
      maxL = math.max(maxL, d.lateral.toDouble());
    }
    return math.max(maxA - minA, maxL - minL);
  }

  void _terminarCaptura() {
    _reloj?.cancel();
    _cronometro.stop();
    final n = _muestras.length;
    double prom(num Function(DatosPostura) f) =>
        _muestras.map(f).fold<double>(0, (a, b) => a + b.toDouble()) / n;
    final malas = _muestras.where((d) => d.malaPostura).length;
    setState(() {
      _resultado = Calibracion(
        adelante: prom((d) => d.adelante),
        lateral: prom((d) => d.lateral),
        difXs: prom((d) => d.difXs),
        difYs: prom((d) => d.difYs),
        variacion: _variacion(_muestras),
        fraccionMalaPostura: malas / n,
        muestras: n,
        instruccion: _frase,
        fecha: DateTime.now(),
      );
      _etapa = _Etapa.resultado;
    });
  }

  Future<void> _guardar() async {
    final r = _resultado;
    if (r == null) return;
    await ServicioParticipantes.instancia.guardarCalibracion(widget.participante, r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calibración de ${widget.participante.codigo} guardada')),
    );
    Navigator.of(context).pop();
  }

  void _cancelar() {
    _reloj?.cancel();
    _cronometro.stop();
    setState(() {
      _etapa = _Etapa.preparar;
      _aviso = '';
    });
  }

  // ---------------- Pantalla ----------------

  static String _grados(double u) {
    final g = math.asin((u / 90).clamp(-1.0, 1.0)) * 180 / math.pi;
    return '${g.round()}°';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calibrar a ${widget.participante.codigo}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ValueListenableBuilder<EstadoConexion>(
            valueListenable: ble.estado,
            builder: (context, estado, _) {
              final conectado = estado == EstadoConexion.conectado;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (!conectado) _sinConexion(),
                  if (conectado) ...switch (_etapa) {
                    _Etapa.preparar => _preparar(),
                    _Etapa.cuenta => _cuentaRegresiva(),
                    _Etapa.captura => _captura(),
                    _Etapa.resultado => _verResultado(),
                  },
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tarjeta({required Widget child, Color? borde}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borde ?? Colores.linea, width: borde == null ? 1 : 2),
        ),
        child: child,
      );

  Widget _sinConexion() => _tarjeta(
        child: const Row(
          children: [
            Icon(Icons.bluetooth_searching_rounded, color: Colores.ambar),
            SizedBox(width: 12),
            Expanded(
              child: Text('Buscando el cinturón… La calibración necesita la conexión.',
                  style: Textos.cuerpo),
            ),
          ],
        ),
      );

  List<Widget> _preparar() {
    final anterior = widget.participante.calibracion;
    return [
      if (anterior != null) ...[
        _tarjeta(
          child: Text(
            'Ya tiene una calibración (${_fecha(anterior.fecha)}, «${anterior.instruccion}»). '
            'Si calibras de nuevo, se reemplaza.',
            style: Textos.secundario,
          ),
        ),
        const SizedBox(height: 14),
      ],
      _tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué le dirás?', style: Textos.tituloTarjeta),
            const SizedBox(height: 4),
            const Text(
              'La frase cambia lo que se mide. Queda guardada con la calibración.',
              style: Textos.secundario,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in frasesCalibracion)
                  ChoiceChip(
                    label: Text('«$f»'),
                    selected: _frase == f,
                    showCheckmark: false,
                    selectedColor: Colores.bosque,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _frase == f ? Colores.tarjeta : Colores.azul,
                    ),
                    onSelected: (_) => setState(() => _frase = f),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _tarjeta(
        child: const Text(
          'Con el niño sentado y el cinturón puesto: dile la frase, y cuando esté '
          'listo presiona Empezar. Habrá una cuenta regresiva y luego unos '
          'segundos en que debe quedarse quieto.',
          style: Textos.secundario,
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 58)),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Empezar'),
        onPressed: _empezar,
      ),
    ];
  }

  List<Widget> _cuentaRegresiva() => [
        const SizedBox(height: 40),
        Text('«$_frase»', textAlign: TextAlign.center, style: Textos.tituloTarjeta),
        const SizedBox(height: 24),
        Text('$_cuenta',
            textAlign: TextAlign.center,
            style: Textos.dato.copyWith(fontSize: 96, color: Colores.bosque)),
        const SizedBox(height: 12),
        const Text('Acomódate…', textAlign: TextAlign.center, style: Textos.cuerpo),
        const SizedBox(height: 40),
        TextButton(onPressed: _cancelar, child: const Text('Cancelar')),
      ];

  List<Widget> _captura() {
    final avance = (_cronometro.elapsedMilliseconds / 1000 / segundosCaptura).clamp(0.0, 1.0).toDouble();
    final d = ble.datos.value;
    return [
      const SizedBox(height: 32),
      const Text('Quieto, como una estatua…', textAlign: TextAlign.center, style: Textos.tituloTarjeta),
      const SizedBox(height: 24),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LinearProgressIndicator(
          value: avance,
          minHeight: 24,
          color: Colores.comodo,
          backgroundColor: Colores.linea,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '${_muestras.length} lecturas · variación ${_variacion(_muestras).toStringAsFixed(0)} '
        '(máx. ${toleranciaCalibracion.toStringAsFixed(0)})',
        textAlign: TextAlign.center,
        style: Textos.secundario,
      ),
      if (d != null)
        Text('ahora: adelante ${d.adelante} · lado ${d.lateral}',
            textAlign: TextAlign.center, style: Textos.secundario),
      if (_aviso.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('$_aviso (${_reinicios == 1 ? '1 vez' : '$_reinicios veces'})',
            textAlign: TextAlign.center,
            style: Textos.cuerpoDestacado.copyWith(color: Colores.ambar)),
      ],
      const SizedBox(height: 40),
      TextButton(onPressed: _cancelar, child: const Text('Cancelar')),
    ];
  }

  List<Widget> _verResultado() {
    final r = _resultado!;
    final pct = (r.fraccionMalaPostura * 100).round();
    final alerta = r.fraccionMalaPostura >= 0.5;
    return [
      _tarjeta(
        borde: Colores.comodo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Postura neutral medida', style: Textos.tituloTarjeta),
            const SizedBox(height: 4),
            Text('«${r.instruccion}» · ${r.muestras} lecturas · se movió ${r.variacion.toStringAsFixed(0)} u'
                '${_reinicios > 0 ? ' · reinicios: $_reinicios' : ''}',
                style: Textos.secundario),
            const SizedBox(height: 16),
            _fila('Adelante / atrás', r.adelante),
            const SizedBox(height: 8),
            _fila('Hacia los lados', r.lateral),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _tarjeta(
        borde: alerta ? Colores.ambar : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(alerta ? Icons.info_rounded : Icons.check_circle_rounded,
                color: alerta ? Colores.ambar : Colores.comodo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Con el umbral fijo del cinturón, su postura neutral se marcó como '
                'mala postura el $pct % del tiempo.'
                '${alerta ? ' El umbral fijo no calza con su postura: dato para justificar la calibración.' : ''}',
                style: Textos.cuerpo,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
        icon: const Icon(Icons.save_rounded),
        label: const Text('Guardar en su perfil'),
        onPressed: _guardar,
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          foregroundColor: Colores.azul,
        ),
        onPressed: _empezar,
        child: const Text('Repetir'),
      ),
    ];
  }

  Widget _fila(String nombre, double valor) {
    final signo = valor >= 0 ? '+' : '−';
    return Row(
      children: [
        Expanded(child: Text(nombre, style: Textos.cuerpo)),
        Text('$signo${valor.abs().toStringAsFixed(1).replaceAll('.', ',')} u  (${_grados(valor.abs())})',
            style: Textos.cuerpoDestacado),
      ],
    );
  }

  static String _fecha(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)} ${dos(d.hour)}:${dos(d.minute)}';
  }
}
