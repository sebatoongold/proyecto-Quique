// ============================================================
// servicio_ble.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F7.2
//
// CAMBIOS v2 respecto a la v1:
//  - Al conectarse busca también la característica del REGISTRO (la
//    cola de episodios del firmware) y ofrece dos operaciones:
//      leerRegistro()          -> lee una tanda (texto JSON)
//      escribirComando(texto)  -> ACK:<id>, BORRAR_TODO, CAL:…, RESET, UMBRAL:…
//    Las usa servicio_cinturon.dart. Si el firmware es antiguo y no la
//    tiene, todo lo demás funciona igual (las dos devuelven fallo).
//  - Nuevo contador `conexiones`: sube en 1 cada vez que se conecta,
//    para que otros servicios sepan cuándo sincronizar.
//
// QUÉ HACE: busca el wearable, se conecta, escucha los datos en vivo y
// los deja disponibles para CUALQUIER pantalla. Antes todo esto vivía
// dentro de postura_screen.dart; separado, el diseño de las pantallas
// se puede cambiar sin tocar la lógica de Bluetooth.
//
// CÓMO SE USA desde una pantalla:
//   final ble = ServicioBle.instancia;
//   ble.iniciar();                       // seguro de llamar varias veces
//   ble.estado  -> buscando / conectando / conectado / ...
//   ble.datos   -> el último DatosPostura recibido (o null)
// Ambos avisan cuando cambian (ValueNotifier), así la pantalla se
// redibuja sola.
//
// DECISIONES:
//  - Una sola instancia para toda la app ("instancia"): la conexión
//    NO se corta al cambiar de pantalla o de mundo.
//  - Protección contra doble conexión: si ya está buscando o
//    conectando, una segunda llamada a iniciar() no hace nada.
//  - Si no encuentra el wearable o se desconecta, reintenta solo cada
//    pocos segundos (el niño no tiene que hacer nada; flujo de la
//    actividad guiada, fase 1).
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../modelos/datos_postura.dart';

// --- Deben ser IDÉNTICOS a los del firmware (.ino) ---
const String uuidServicio = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String uuidDatosEnVivo = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String uuidRegistro = 'a1b2c3d4-0002-4e5f-8a9b-1234567890ab'; // cola de episodios + comandos
const String nombreWearable = 'ESP32_Sensor_Postura';

// ---------- PARÁMETROS AJUSTABLES ----------
// Cuánto dura cada búsqueda antes de rendirse y volver a intentar.
const Duration duracionBusqueda = Duration(seconds: 10);
// Pausa entre un intento fallido y el siguiente.
const Duration esperaEntreReintentos = Duration(seconds: 3);

enum EstadoConexion { desconectado, buscando, conectando, conectado, error }

class ServicioBle {
  ServicioBle._();
  static final ServicioBle instancia = ServicioBle._();

  /// Estado de la conexión; las pantallas lo escuchan para mostrarlo.
  final ValueNotifier<EstadoConexion> estado =
      ValueNotifier(EstadoConexion.desconectado);

  /// Último dato recibido del wearable (null si no hay conexión).
  final ValueNotifier<DatosPostura?> datos = ValueNotifier(null);

  /// Texto del último error, para mostrarlo o depurar.
  String? ultimoError;

  /// Sube en 1 cada vez que se logra una conexión (para sincronizar).
  final ValueNotifier<int> conexiones = ValueNotifier(0);

  BluetoothCharacteristic? _registro; // null = no conectado o firmware sin cola

  /// true si el cinturón conectado tiene la cola de episodios.
  bool get tieneRegistro => conectado && _registro != null;

  /// Lee una tanda del registro (texto JSON). null si no se pudo.
  Future<String?> leerRegistro() async {
    final c = _registro;
    if (!conectado || c == null) return null;
    try {
      final bytes = await c.read();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      debugPrint('ServicioBle.leerRegistro: $e');
      return null;
    }
  }

  /// Escribe un comando en el registro. true si el cinturón lo recibió.
  Future<bool> escribirComando(String comando) async {
    final c = _registro;
    if (!conectado || c == null) return false;
    try {
      await c.write(utf8.encode(comando), withoutResponse: false);
      return true;
    } catch (e) {
      debugPrint('ServicioBle.escribirComando($comando): $e');
      return false;
    }
  }

  BluetoothDevice? _dispositivo;
  StreamSubscription<List<ScanResult>>? _subBusqueda;
  StreamSubscription<List<int>>? _subDatos;
  StreamSubscription<BluetoothConnectionState>? _subConexion;
  Timer? _temporizadorReintento;

  bool _enProceso = false; // protección contra doble conexión
  bool _permisosPedidos = false;
  bool _activo = false; // false después de detener(): ya no reintenta

  bool get conectado => estado.value == EstadoConexion.conectado;

  /// Empieza a buscar y conectar. Se puede llamar desde varias
  /// pantallas: si ya está conectado o en proceso, no hace nada.
  Future<void> iniciar() async {
    _activo = true;
    if (_enProceso || conectado) return;
    _enProceso = true;
    _temporizadorReintento?.cancel();

    try {
      if (!_permisosPedidos) {
        await _pedirPermisos();
        _permisosPedidos = true;
      }

      final encontrado = await _buscar();
      if (encontrado == null) {
        // No apareció en esta búsqueda: se vuelve a intentar solo.
        estado.value = EstadoConexion.desconectado;
        _programarReintento();
        return;
      }

      await _conectar(encontrado);
    } catch (e) {
      // Ejemplos: Bluetooth apagado, permisos denegados, fallo al conectar.
      ultimoError = e.toString();
      estado.value = EstadoConexion.error;
      debugPrint('ServicioBle: $e');
      _programarReintento();
    } finally {
      _enProceso = false;
    }
  }

  /// Corta la conexión y deja de reintentar.
  Future<void> detener() async {
    _activo = false;
    _temporizadorReintento?.cancel();
    await _subBusqueda?.cancel();
    await _subDatos?.cancel();
    await _subConexion?.cancel();
    _subBusqueda = null;
    _subDatos = null;
    _subConexion = null;
    await _dispositivo?.disconnect();
    _dispositivo = null;
    _registro = null;
    datos.value = null;
    estado.value = EstadoConexion.desconectado;
  }

  // ------------------------------------------------------------

  Future<void> _pedirPermisos() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  /// Busca el wearable por su nombre. Devuelve el dispositivo, o null
  /// si terminó el tiempo de búsqueda sin encontrarlo.
  Future<BluetoothDevice?> _buscar() async {
    estado.value = EstadoConexion.buscando;
    final encontrado = Completer<BluetoothDevice?>();

    await _subBusqueda?.cancel();
    _subBusqueda = FlutterBluePlus.scanResults.listen((resultados) {
      for (final r in resultados) {
        // "isCompleted" evita la doble conexión: aunque el escaneo
        // entregue el mismo dispositivo varias veces seguidas, solo
        // se usa la primera.
        if (r.device.platformName == nombreWearable && !encontrado.isCompleted) {
          encontrado.complete(r.device);
        }
      }
    });

    await FlutterBluePlus.startScan(
      withNames: [nombreWearable],
      timeout: duracionBusqueda,
    );

    // Gana lo que pase primero: encontrarlo, o que termine la búsqueda.
    final dispositivo = await Future.any<BluetoothDevice?>([
      encontrado.future,
      FlutterBluePlus.isScanning
          .where((buscando) => buscando == false)
          .first
          .then<BluetoothDevice?>((_) => null),
    ]);

    await FlutterBluePlus.stopScan();
    await _subBusqueda?.cancel();
    _subBusqueda = null;
    return dispositivo;
  }

  Future<void> _conectar(BluetoothDevice dispositivo) async {
    estado.value = EstadoConexion.conectando;

    try {
      await dispositivo.connect();
      _dispositivo = dispositivo;

      // Igual que antes: se busca el servicio y la característica de
      // datos en vivo. Se compara en minúsculas porque a veces un lado
      // entrega el UUID en mayúsculas.
      final servicios = await dispositivo.discoverServices();
      BluetoothCharacteristic? caracteristica;
      BluetoothCharacteristic? registro;
      for (final servicio in servicios) {
        if (servicio.uuid.toString().toLowerCase() != uuidServicio) continue;
        for (final c in servicio.characteristics) {
          final id = c.uuid.toString().toLowerCase();
          if (id == uuidDatosEnVivo) caracteristica = c;
          if (id == uuidRegistro) registro = c;
        }
      }
      _registro = registro; // puede ser null con un firmware antiguo
      if (caracteristica == null) {
        throw Exception('El wearable no tiene la característica de datos en vivo');
      }

      await caracteristica.setNotifyValue(true);

      await _subDatos?.cancel();
      _subDatos = caracteristica.lastValueStream.listen((valor) {
        if (valor.isEmpty) return;
        final dato = DatosPostura.desdeTexto(utf8.decode(valor, allowMalformed: true));
        if (dato != null) datos.value = dato; // si llegó corrupto, se espera el siguiente
      });

      ultimoError = null;
      estado.value = EstadoConexion.conectado;
      conexiones.value++;

      // Si el wearable se apaga o se aleja, se detecta aquí y se
      // vuelve a buscar automáticamente.
      await _subConexion?.cancel();
      _subConexion = dispositivo.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected && conectado) {
          _alDesconectarse();
        }
      });
    } catch (e) {
      // Si algo falló a medio camino, se suelta la conexión para no
      // dejar el wearable "pensando" que sigue conectado.
      try {
        await dispositivo.disconnect();
      } catch (_) {
        // si ni siquiera se puede desconectar, no hay nada más que hacer
      }
      _dispositivo = null;
      rethrow;
    }
  }

  void _alDesconectarse() {
    _registro = null;
    _subDatos?.cancel();
    _subDatos = null;
    datos.value = null;
    estado.value = EstadoConexion.desconectado;
    _programarReintento();
  }

  void _programarReintento() {
    if (!_activo) return;
    _temporizadorReintento?.cancel();
    _temporizadorReintento = Timer(esperaEntreReintentos, () {
      iniciar();
    });
  }
}
