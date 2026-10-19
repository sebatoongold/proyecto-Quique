// ============================================================
// linea_tiempo_postura.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F7.3 (Historial → Postura)
//
// La línea de tiempo del día, en tres partes:
//
//  1. PANEL FIJO arriba: resumen del día (veces, tiempo, la más larga)
//     y el DETALLE DE LA HORA EN FOCO (sus episodios y juegos).
//  2. LISTA DE HORAS, la más reciente arriba. Una fila por hora, con
//     una franja de 60 minutos que marca DÓNDE pasó cada episodio.
//     Hay una LÍNEA DE FOCO fija: al desplazar (en todo el ancho), la
//     hora que queda en el foco se destaca, vibra suave al cambiar y su
//     detalle aparece en el panel. Al soltar, la lista se acomoda para
//     dejar una hora justo en el foco. Tocar una fila la lleva al foco.
//     Por qué el detalle va en el panel y no dentro de la lista: si las
//     filas se abrieran al pasar, cambiarían de alto bajo el dedo.
//  3. FRANJA DE LA SEMANA fija abajo, con un punto en los días con
//     datos. Las flechas cambian de semana; tocar el nombre del mes
//     despliega el mes completo.
//
// Los datos vienen de la cola del cinturón (servicio_cinturon.dart) y se
// ordenan en analisis_postura.dart.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/participante.dart';
import '../modelos/registro_juego.dart';
import '../servicios/almacenamiento_juegos.dart';
import '../servicios/analisis_postura.dart';
import '../servicios/servicio_cinturon.dart';
import '../servicios/servicio_participantes.dart';
import '../tema/colores.dart';
import '../tema/tema_app.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Alto de cada fila de hora (px).
const double altoFilaHora = 60;
// Dónde queda la línea de foco, como fracción del alto de la lista
// (0 = arriba, 1 = abajo).
const double fraccionFoco = 0.30;
// Ancho mínimo de la marca de un episodio en la franja (px), para que
// uno de pocos segundos no sea invisible.
const double anchoMinimoMarca = 4;
// Alto máximo de la lista de episodios dentro del panel (px).
const double altoMaximoDetalle = 150;

const _diasCortos = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _diasLargos = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

Color colorDireccion(String d) => switch (d) {
      'adelante' => Colores.categoriaAdelante,
      'lateral' => Colores.categoriaLateral,
      _ => Colores.categoriaAmbos,
    };

String textoDireccion(String d) => switch (d) {
      'adelante' => 'hacia adelante',
      'lateral' => 'hacia el lado',
      _ => 'adelante y al lado',
    };

String textoTiempo(int ms) {
  final s = (ms / 1000).round();
  if (s < 60) return '$s s';
  final m = s ~/ 60, r = s % 60;
  return r == 0 ? '$m min' : '$m min $r s';
}

String _dos(int n) => n.toString().padLeft(2, '0');
String _hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

class LineaTiempoPostura extends StatefulWidget {
  const LineaTiempoPostura({super.key});

  @override
  State<LineaTiempoPostura> createState() => _LineaTiempoPosturaState();
}

class _LineaTiempoPosturaState extends State<LineaTiempoPostura> {
  final _scroll = ScrollController();
  DateTime _dia = soloDia(DateTime.now());
  List<RegistroJuego> _juegos = const [];
  int _foco = 0; // índice de la hora en foco (0 = la más reciente)

  @override
  void initState() {
    super.initState();
    ServicioCinturon.instancia.episodios.addListener(_refrescar);
    ServicioParticipantes.instancia.activo.addListener(_cargarJuegos);
    _scroll.addListener(_alDesplazar);
    _cargarJuegos();
  }

  @override
  void dispose() {
    ServicioCinturon.instancia.episodios.removeListener(_refrescar);
    ServicioParticipantes.instancia.activo.removeListener(_cargarJuegos);
    _scroll.dispose();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarJuegos() async {
    final j = await AlmacenamientoJuegos.cargarDelActivo();
    if (mounted) setState(() => _juegos = j);
  }

  PosturaDelDia get _datos {
    final Participante? p = ServicioParticipantes.instancia.activo.value;
    return AnalisisPostura.delDia(
      _dia,
      episodios: ServicioCinturon.instancia.de(p?.codigo),
      juegos: _juegos,
    );
  }

  // ---------------- Foco ----------------

  void _alDesplazar() {
    final n = _datos.horas().length;
    if (n == 0) return;
    // Con el relleno de arriba, la fila i queda en el foco cuando el
    // desplazamiento es i × alto de fila.
    final i = (_scroll.offset / altoFilaHora).round().clamp(0, n - 1);
    if (i != _foco) {
      HapticFeedback.selectionClick();
      setState(() => _foco = i);
    }
  }

  /// Al soltar, se acomoda para dejar una hora justo en el foco.
  bool _alTerminar(ScrollEndNotification _) {
    final destino = _foco * altoFilaHora;
    if ((_scroll.offset - destino).abs() > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(destino, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
        }
      });
    }
    return false;
  }

  void _irAHora(int i) {
    _scroll.animateTo(i * altoFilaHora, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _elegirDia(DateTime d) {
    setState(() {
      _dia = soloDia(d);
      _foco = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    final datos = _datos;
    final horas = datos.horas();
    final foco = horas.isEmpty ? null : horas[_foco.clamp(0, horas.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(datos, foco),
        const SizedBox(height: 10),
        Expanded(child: _lista(datos, horas)),
        const SizedBox(height: 10),
        _semana(),
      ],
    );
  }

  // ---------- 1. Panel ----------
  Widget _panel(PosturaDelDia datos, int? hora) {
    final esHoy = datos.dia == soloDia(DateTime.now());
    final titulo = esHoy
        ? 'Hoy'
        : '${_diasLargos[datos.dia.weekday - 1]} ${datos.dia.day} de ${_meses[datos.dia.month - 1]}';
    final enHora = hora == null ? const <EpisodioDelDia>[] : datos.enHora(hora);
    final juegosHora = hora == null ? const <JuegoDelDia>[] : datos.juegosEnHora(hora);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(titulo[0].toUpperCase() + titulo.substring(1), style: Textos.tituloTarjeta),
              const Spacer(),
              Text(
                datos.veces == 1 ? '1 vez' : '${datos.veces} veces',
                style: Textos.cuerpoDestacado,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            datos.veces == 0
                ? 'Sin episodios registrados este día.'
                : 'En total ${textoTiempo(datos.msTotal)} · la más larga, ${textoTiempo(datos.msMasLargo)}'
                    '${datos.direccionDominante == null ? '' : ' · sobre todo ${textoDireccion(datos.direccionDominante!)}'}',
            style: Textos.secundario,
          ),
          if (datos.sinHora.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              onPressed: () => _verSinHora(datos),
              child: Text('+ ${datos.sinHora.length} sin hora exacta'),
            ),
          const Divider(height: 18, color: Colores.linea),
          if (hora == null)
            const Text('Sin horas que mostrar.', style: Textos.secundario)
          else ...[
            Text('${_dos(hora)}:00 – ${_dos((hora + 1) % 24)}:00', style: Textos.cuerpoDestacado),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: altoMaximoDetalle),
              child: enHora.isEmpty && juegosHora.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nada registrado en esta hora.', style: Textos.secundario),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final j in juegosHora)
                          _filaDetalle(
                            color: Colores.comodo.withValues(alpha: 0.5),
                            texto: 'Jugó · ${_hora(j.inicio)}–${_hora(j.fin)}',
                          ),
                        for (final e in enHora)
                          _filaDetalle(
                            color: e.duranteJuego ? Colores.linea : colorDireccion(e.direccion),
                            texto: '${_hora(e.inicio)} · ${textoTiempo(e.msDuracion)} · ${textoDireccion(e.direccion)}'
                                '${e.duranteJuego ? ' (durante un juego, no cuenta)' : ''}',
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filaDetalle({required Color color, required String texto}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(texto, style: Textos.cuerpo.copyWith(fontSize: 15))),
          ],
        ),
      );

  Future<void> _verSinHora(PosturaDelDia datos) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sin hora exacta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El cinturón se reinició antes de enviarlos, así que no se sabe a qué hora '
                  'ocurrieron. Se muestran el día en que llegaron.',
                  style: Textos.secundario,
                ),
                const SizedBox(height: 10),
                for (final e in datos.sinHora)
                  Text('• ${textoTiempo(e.msDuracion)}', style: Textos.cuerpo),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        ),
      );

  // ---------- 2. Lista con foco ----------
  Widget _lista(PosturaDelDia datos, List<int> horas) {
    return LayoutBuilder(builder: (context, c) {
      final alto = c.maxHeight;
      final yFoco = alto * fraccionFoco;
      final arriba = (yFoco - altoFilaHora / 2).clamp(0.0, alto);
      final abajo = (alto - yFoco - altoFilaHora / 2).clamp(0.0, alto);
      return Stack(
        children: [
          // Lente del foco (detrás de las filas, no recibe toques).
          Positioned(
            left: 0,
            right: 0,
            top: arriba,
            height: altoFilaHora,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colores.tarjeta,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colores.azul, width: 2),
                ),
              ),
            ),
          ),
          NotificationListener<ScrollEndNotification>(
            onNotification: _alTerminar,
            child: ListView.builder(
              controller: _scroll,
              itemExtent: altoFilaHora,
              padding: EdgeInsets.only(top: arriba, bottom: abajo),
              itemCount: horas.length,
              itemBuilder: (context, i) => _filaHora(datos, horas[i], i == _foco, () => _irAHora(i)),
            ),
          ),
        ],
      );
    });
  }

  Widget _filaHora(PosturaDelDia datos, int hora, bool enFoco, VoidCallback alTocar) {
    final eps = datos.enHora(hora);
    final cuentan = eps.where((e) => !e.duranteJuego).length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '${_dos(hora)}:00',
                style: (enFoco ? Textos.cuerpoDestacado : Textos.secundario).copyWith(fontSize: 15),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 22,
                child: CustomPaint(
                  painter: _FranjaHora(
                    hora: hora,
                    dia: datos.dia,
                    episodios: eps,
                    juegos: datos.juegosEnHora(hora),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                cuentan == 0 ? '' : '$cuentan',
                textAlign: TextAlign.right,
                style: Textos.cuerpoDestacado.copyWith(color: enFoco ? Colores.azul : Colores.textoSecundario),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 3. Semana ----------
  Widget _semana() {
    final conDatos = AnalisisPostura.diasConDatos(
      ServicioCinturon.instancia.de(ServicioParticipantes.instancia.activo.value?.codigo),
    );
    final hoy = soloDia(DateTime.now());
    final lunes = _dia.subtract(Duration(days: _dia.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));
    final mesTexto = lunes.month == domingo.month
        ? '${_meses[lunes.month - 1]} ${lunes.year}'
        : '${_meses[lunes.month - 1]} – ${_meses[domingo.month - 1]} ${domingo.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Semana anterior',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _elegirDia(_dia.subtract(const Duration(days: 7))),
              ),
              // Tocar el mes despliega el mes completo.
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _abrirMes(conDatos),
                  icon: const Icon(Icons.expand_less_rounded, size: 20),
                  label: Text(mesTexto[0].toUpperCase() + mesTexto.substring(1)),
                ),
              ),
              IconButton(
                tooltip: 'Semana siguiente',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: lunes.add(const Duration(days: 7)).isAfter(hoy)
                    ? null
                    : () {
                        final d = _dia.add(const Duration(days: 7));
                        _elegirDia(d.isAfter(hoy) ? hoy : d);
                      },
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _dia7(lunes.add(Duration(days: i)), conDatos, hoy)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dia7(DateTime d, Set<DateTime> conDatos, DateTime hoy) {
    final elegido = d == _dia;
    final futuro = d.isAfter(hoy);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: futuro ? null : () => _elegirDia(d),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_diasCortos[d.weekday - 1], style: Textos.secundario.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: elegido ? Colores.azul : null,
              shape: BoxShape.circle,
              border: d == hoy && !elegido ? Border.all(color: Colores.azul) : null,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: elegido ? Colores.tarjeta : (futuro ? Colores.linea : Colores.azul),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: conDatos.contains(d) ? Colores.bosque : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirMes(Set<DateTime> conDatos) async {
    final elegido = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colores.tarjeta,
      showDragHandle: true,
      builder: (_) => _Mes(inicial: _dia, conDatos: conDatos),
    );
    if (elegido != null) _elegirDia(elegido);
  }
}

/// Dibuja la franja de una hora: 60 minutos de izquierda a derecha,
/// juegos como una banda suave y episodios como marcas de color.
class _FranjaHora extends CustomPainter {
  final int hora;
  final DateTime dia;
  final List<EpisodioDelDia> episodios;
  final List<JuegoDelDia> juegos;

  _FranjaHora({required this.hora, required this.dia, required this.episodios, required this.juegos});

  @override
  void paint(Canvas canvas, Size size) {
    final inicioHora = DateTime(dia.year, dia.month, dia.day, hora);
    double x(DateTime t) =>
        (t.difference(inicioHora).inMilliseconds / 3600000).clamp(0.0, 1.0) * size.width;

    // Pista de fondo y marcas de cada 15 min.
    final fondo = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.4), const Radius.circular(4));
    canvas.drawRRect(fondo, Paint()..color = Colores.fondo);
    final guia = Paint()
      ..color = Colores.linea
      ..strokeWidth = 1;
    for (var q = 1; q < 4; q++) {
      final gx = size.width * q / 4;
      canvas.drawLine(Offset(gx, size.height * 0.3), Offset(gx, size.height * 0.7), guia);
    }

    // Juegos: banda suave a lo alto.
    for (final j in juegos) {
      final x1 = x(j.inicio), x2 = x(j.fin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x1, 0, x2 < x1 + 2 ? x1 + 2 : x2, size.height), const Radius.circular(4)),
        Paint()..color = Colores.comodo.withValues(alpha: 0.18),
      );
    }

    // Episodios.
    for (final e in episodios) {
      final x1 = x(e.inicio);
      var x2 = x(e.inicio.add(Duration(milliseconds: e.msDuracion)));
      if (x2 - x1 < anchoMinimoMarca) x2 = x1 + anchoMinimoMarca;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x1, 2, x2, size.height - 2), const Radius.circular(3)),
        Paint()..color = e.duranteJuego ? Colores.linea : colorDireccion(e.direccion),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FranjaHora old) =>
      old.hora != hora || old.dia != dia || old.episodios != episodios || old.juegos != juegos;
}

/// El mes completo, para elegir un día. Devuelve el día elegido.
class _Mes extends StatefulWidget {
  final DateTime inicial;
  final Set<DateTime> conDatos;

  const _Mes({required this.inicial, required this.conDatos});

  @override
  State<_Mes> createState() => _MesState();
}

class _MesState extends State<_Mes> {
  late DateTime _mes = DateTime(widget.inicial.year, widget.inicial.month);

  @override
  Widget build(BuildContext context) {
    final hoy = soloDia(DateTime.now());
    final primero = _mes;
    final diasDelMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final vacios = primero.weekday - 1; // la semana parte el lunes
    final esteMes = DateTime(hoy.year, hoy.month);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() => _mes = DateTime(_mes.year, _mes.month - 1)),
                ),
                Expanded(
                  child: Text(
                    '${_meses[_mes.month - 1][0].toUpperCase()}${_meses[_mes.month - 1].substring(1)} ${_mes.year}',
                    textAlign: TextAlign.center,
                    style: Textos.tituloTarjeta,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _mes == esteMes
                      ? null
                      : () => setState(() => _mes = DateTime(_mes.year, _mes.month + 1)),
                ),
              ],
            ),
            Row(
              children: [
                for (final l in _diasCortos)
                  Expanded(child: Text(l, textAlign: TextAlign.center, style: Textos.secundario)),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < vacios; i++) const SizedBox.shrink(),
                for (var d = 1; d <= diasDelMes; d++) _celda(DateTime(_mes.year, _mes.month, d), hoy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _celda(DateTime d, DateTime hoy) {
    final futuro = d.isAfter(hoy);
    final elegido = d == soloDia(widget.inicial);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: futuro ? null : () => Navigator.of(context).pop(d),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: elegido ? Colores.azul : null,
              shape: BoxShape.circle,
              border: d == hoy && !elegido ? Border.all(color: Colores.azul) : null,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: elegido ? Colores.tarjeta : (futuro ? Colores.linea : Colores.azul),
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: widget.conDatos.contains(d) ? Colores.bosque : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
