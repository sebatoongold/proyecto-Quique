// ============================================================
// servicio_cinturon.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F7.3
//
// CAMBIOS v2 respecto a la v1:
//  - Sincroniza cada 30 s (antes 120 s) mientras hay conexión: ahora el
//    Resumen de hoy y la línea de tiempo salen de la cola, y deben
//    sentirse al día.
//
// Dos trabajos:
//
// 1) SINCRONIZAR la cola de episodios del cinturón (firmware v6+):
//    lee una tanda, la GUARDA en el teléfono y recién entonces manda
//    "ACK:<último id>" para que el cinturón la borre. Repite hasta
//    vaciar la cola. Nada se borra en el cinturón sin estar guardado.
//    Se sincroniza: al conectarse, cada `segundosSincronizacion`
//    mientras está conectado, al terminar un monitoreo, antes de
//    cambiar de participante y con el botón de la pantalla Cinturón.
//
// 2) ASIGNAR el cinturón al participante activo (firmware v8):
//    con un solo cinturón que se turna entre niños, al elegir a otro
//    participante primero se sincroniza (los episodios pendientes son
//    del niño anterior) y después se le envía al cinturón:
//      UMBRAL:<adelante>,<lateral>  (los de analisis_monitoreo.dart: así
//                                    la app y el cinturón usan los mismos)
//      CAL:<neutroX>,<neutroY>,<idCal>  si el niño tiene calibración y
//                                       el parámetro "El cinturón registra
//                                       con la calibración" está activo;
//      RESET                             si no.
//    Si el cinturón no está conectado, queda PENDIENTE y se hace al
//    conectarse.
//
// A QUIÉN SE ATRIBUYE cada episodio leído:
//  - si trae idCal ≠ 0: al participante dueño de esa calibración;
//  - si trae idCal = 0: al participante al que estaba asignado el
//    cinturón (el último al que se le envió CAL o RESET).
// El idCal de cada participante es un número fijo que elige la app la
// primera vez (1, 2, 3…) y guarda en el teléfono.
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/episodio_cinturon.dart';
import '../modelos/participante.dart';
import 'analisis_monitoreo.dart';
import 'servicio_ble.dart';
import 'servicio_parametros.dart';
import 'servicio_participantes.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cada cuántos segundos se sincroniza la cola mientras hay conexión.
const int segundosSincronizacion = 30;
// Máximo de tandas por sincronización (seguro contra un ciclo sin fin;
// con 4 episodios por tanda, 40 tandas = 160 episodios > 100 de la cola).
const int maximoTandas = 40;

const String _claveEpisodios = 'episodios_cinturon_v1';
const String _claveAsignado = 'cinturon_asignado_v1';
const String _claveIdCal = 'idcal_por_participante_v1';

class ServicioCinturon {
  ServicioCinturon._();
  static final ServicioCinturon instancia = ServicioCinturon._();

  final ServicioBle _ble = ServicioBle.instancia;

  /// Todos los episodios recibidos del cinturón, en orden de id.
  final ValueNotifier<List<EpisodioCinturon>> episodios = ValueNotifier(const []);

  /// Última configuración que informó el cinturón (null = aún no se lee).
  final ValueNotifier<ConfigCinturon?> config = ValueNotifier(null);

  /// Texto corto del estado, para la pantalla Cinturón.
  final ValueNotifier<String> estado = ValueNotifier('Sin conexión todavía');

  /// A quién está asignado el cinturón (código), y si falta enviárselo.
  final ValueNotifier<String?> asignadoA = ValueNotifier(null);
  final ValueNotifier<bool> asignacionPendiente = ValueNotifier(false);

  /// Fecha de la última sincronización completa.
  final ValueNotifier<DateTime?> ultimaSincronizacion = ValueNotifier(null);

  Map<String, int> _idCalPorCodigo = {};
  Timer? _periodico;
  Timer? _antirebote;
  Future<void> _cola = Future.value(); // las operaciones BLE van de a una

  // ---------------- Inicio ----------------

  Future<void> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final texto = prefs.getString(_claveEpisodios);
      if (texto != null) {
        final datos = jsonDecode(texto);
        if (datos is List) {
          episodios.value = datos
              .whereType<Map<String, dynamic>>()
              .map(EpisodioCinturon.desdeJson)
              .toList();
        }
      }
      final mapa = prefs.getString(_claveIdCal);
      if (mapa != null) {
        final datos = jsonDecode(mapa);
        if (datos is Map<String, dynamic>) {
          _idCalPorCodigo = datos.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      }
    } catch (_) {
      // Datos dañados: se parte sin ellos en vez de fallar.
    }
    asignadoA.value = prefs.getString(_claveAsignado);

    // Al conectarse: sincronizar y asignar al participante activo.
    _ble.conexiones.addListener(_alConectarse);
    // Al cambiar de participante (o su calibración) o el parámetro.
    ServicioParticipantes.instancia.activo.addListener(_programarAsignacion);
    ServicioParametros.instancia.actual.addListener(_programarAsignacion);
    asignacionPendiente.value = true;
    if (_ble.conectado) _alConectarse();
  }

  void _alConectarse() {
    _periodico?.cancel();
    _periodico = Timer.periodic(const Duration(seconds: segundosSincronizacion), (_) {
      if (_ble.tieneRegistro) sincronizar();
    });
    asignarActivo();
  }

  /// Espera un instante antes de asignar: guardar una calibración avisa
  /// dos veces seguidas, y basta con enviar una.
  void _programarAsignacion() {
    asignacionPendiente.value = true;
    _antirebote?.cancel();
    _antirebote = Timer(const Duration(milliseconds: 400), asignarActivo);
  }

  /// Ejecuta las operaciones de a una (el Bluetooth no admite dos a la vez).
  Future<T> _enOrden<T>(Future<T> Function() tarea) {
    final resultado = _cola.then((_) => tarea());
    _cola = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  // ---------------- idCal por participante ----------------

  int _idCalDe(String codigo) {
    final existente = _idCalPorCodigo[codigo];
    if (existente != null) return existente;
    var n = 1;
    while (_idCalPorCodigo.containsValue(n)) {
      n++;
    }
    _idCalPorCodigo[codigo] = n;
    SharedPreferences.getInstance()
        .then((p) => p.setString(_claveIdCal, jsonEncode(_idCalPorCodigo)));
    return n;
  }

  String? _codigoDeIdCal(int idCal) {
    for (final e in _idCalPorCodigo.entries) {
      if (e.value == idCal) return e.key;
    }
    return null;
  }

  /// La calibración que el cinturón DEBERÍA tener para el activo
  /// (0 = ninguna). Sirve para verificar contra lo que informa.
  int idCalEsperado() {
    final p = ServicioParticipantes.instancia.activo.value;
    final usar = ServicioParametros.instancia.actual.value.cinturonCalibrado;
    if (p == null || p.calibracion == null || !usar) return 0;
    return _idCalDe(p.codigo);
  }

  // ---------------- Sincronizar ----------------

  /// Lee la cola completa. Devuelve cuántos episodios nuevos llegaron
  /// (o -1 si no se pudo leer).
  Future<int> sincronizar() => _enOrden(_sincronizar);

  Future<int> _sincronizar() async {
    if (!_ble.tieneRegistro) {
      estado.value = 'Sin conexión con el cinturón';
      return -1;
    }
    estado.value = 'Sincronizando…';
    var nuevos = 0;
    final idsConocidos = {for (final e in episodios.value) e.id};

    for (var tanda = 0; tanda < maximoTandas; tanda++) {
      final texto = await _ble.leerRegistro();
      if (texto == null) {
        estado.value = 'No se pudo leer el cinturón';
        return nuevos > 0 ? nuevos : -1;
      }
      Map<String, dynamic>? leido;
      try {
        final d = jsonDecode(texto);
        if (d is Map<String, dynamic>) leido = d;
      } catch (_) {
        // texto dañado: se trata abajo
      }
      if (leido == null) {
        estado.value = 'Lectura dañada; se reintentará';
        return nuevos > 0 ? nuevos : -1;
      }
      final datos = leido;

      final ahoraTelefono = DateTime.now();
      final boot = (datos['boot'] as num?)?.toInt() ?? -1;
      final ahoraMillis = (datos['ahora'] as num?)?.toInt() ?? 0;
      final pendientes = (datos['pendientes'] as num?)?.toInt() ?? 0;
      config.value = ConfigCinturon(
        idCal: (datos['cal'] as num?)?.toInt() ?? 0,
        neutroX: (datos['nx'] as num?)?.toDouble() ?? 0,
        neutroY: (datos['ny'] as num?)?.toDouble() ?? 0,
        umbralAdelante: (datos['ua'] as num?)?.toDouble() ?? umbralAdelante,
        umbralLateral: (datos['ul'] as num?)?.toDouble() ?? umbralLateral,
        pendientes: pendientes,
        leida: ahoraTelefono,
      );

      final eventos = (datos['eventos'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
      if (eventos.isEmpty) break; // cola vacía

      var maxId = 0;
      final lista = [...episodios.value];
      for (final e in eventos) {
        int n(String k) => (e[k] as num?)?.toInt() ?? 0;
        final id = n('id');
        if (id > maxId) maxId = id;
        if (idsConocidos.contains(id)) continue; // ya estaba guardado (ACK perdido)
        final idCal = n('cal');
        final mismoEncendido = n('boot') == boot;
        lista.add(EpisodioCinturon(
          id: id,
          boot: n('boot'),
          millisInicio: n('inicio'),
          horaInicio: mismoEncendido
              ? ahoraTelefono.subtract(Duration(milliseconds: ahoraMillis - n('inicio')))
              : null,
          dsAdelante: n('adel'),
          dsLateral: n('lat'),
          dsAmbos: n('amb'),
          idCal: idCal,
          participante: idCal != 0 ? (_codigoDeIdCal(idCal) ?? asignadoA.value) : asignadoA.value,
          recibido: ahoraTelefono,
        ));
        idsConocidos.add(id);
        nuevos++;
      }

      // PRIMERO se guarda en el teléfono, DESPUÉS se confirma.
      episodios.value = lista;
      await _guardarEpisodios();
      final ok = await _ble.escribirComando('ACK:$maxId');
      if (!ok) {
        estado.value = 'No se pudo confirmar; se reintentará';
        return nuevos;
      }
      if (pendientes <= eventos.length) break; // era la última tanda
    }

    ultimaSincronizacion.value = DateTime.now();
    estado.value = nuevos == 0 ? 'Sincronizado: sin episodios nuevos' : 'Sincronizado: $nuevos episodios nuevos';
    return nuevos;
  }

  // ---------------- Asignar al participante activo ----------------

  /// Sincroniza y deja el cinturón con la calibración del activo.
  Future<bool> asignarActivo() => _enOrden(_asignarActivo);

  Future<bool> _asignarActivo() async {
    if (!_ble.tieneRegistro) {
      asignacionPendiente.value = true;
      return false;
    }
    // 1. Lo pendiente es del participante anterior: se lee antes de cambiar.
    await _sincronizar();

    // 2. Umbrales (los mismos que usa la app) y calibración.
    final Participante? p = ServicioParticipantes.instancia.activo.value;
    final ua = umbralAdelante.toStringAsFixed(1);
    final ul = umbralLateral.toStringAsFixed(1);
    var ok = await _ble.escribirComando('UMBRAL:$ua,$ul');

    final idCal = idCalEsperado();
    final cal = p?.calibracion;
    if (idCal != 0 && cal != null) {
      ok = ok &&
          await _ble.escribirComando(
              'CAL:${cal.difXs.toStringAsFixed(1)},${cal.difYs.toStringAsFixed(1)},$idCal');
    } else {
      ok = ok && await _ble.escribirComando('RESET');
    }
    if (!ok) {
      estado.value = 'No se pudo enviar la calibración; se reintentará';
      asignacionPendiente.value = true;
      return false;
    }

    // 3. Se recuerda a quién quedó asignado y se vuelve a leer la
    //    cabecera para confirmar lo que el cinturón tiene cargado.
    asignadoA.value = p?.codigo;
    final prefs = await SharedPreferences.getInstance();
    if (p == null) {
      await prefs.remove(_claveAsignado);
    } else {
      await prefs.setString(_claveAsignado, p.codigo);
    }
    asignacionPendiente.value = false;
    await _sincronizar();
    estado.value = idCal != 0
        ? 'Cinturón con la calibración de ${p!.codigo}'
        : 'Cinturón con el umbral fijo${p == null ? '' : ' (${p.codigo})'}';
    return true;
  }

  /// Vacía la cola del cinturón SIN guardarla (BORRAR_TODO). Para limpiar
  /// las pruebas antes del testeo.
  Future<bool> vaciarCinturon() => _enOrden(() async {
        final ok = await _ble.escribirComando('BORRAR_TODO');
        if (ok) estado.value = 'Cola del cinturón vaciada';
        return ok;
      });

  // ---------------- Consultas ----------------

  /// Episodios atribuidos a un participante (null = sin participante).
  List<EpisodioCinturon> de(String? codigo) =>
      episodios.value.where((e) => e.participante == codigo).toList();

  Future<void> borrarDe(String? codigo) async {
    episodios.value = episodios.value.where((e) => e.participante != codigo).toList();
    await _guardarEpisodios();
  }

  Future<void> _guardarEpisodios() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveEpisodios, jsonEncode(episodios.value.map((e) => e.toJson()).toList()));
  }
}
