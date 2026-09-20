// ============================================================
// postura_screen.dart
// Pantalla que se conecta al ESP32 sensor por BLE, escucha las
// notificaciones del ángulo (X e Y), y las muestra en pantalla.
// Este es el paso previo a dibujar el avatar - primero hay que
// tener el dato llegando de forma confiable.
// ============================================================

import 'dart:convert'; // jsonDecode() - viene incluido en Dart, no hay que agregarlo a pubspec.yaml
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Deben ser IDÉNTICOS a los que definiste en el .ino ---
// (mayúsculas/minúsculas no importan en UUIDs, pero los números sí)
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String NOMBRE_DISPOSITIVO = "ESP32_Sensor_Postura";

class PosturaScreen extends StatefulWidget {
  const PosturaScreen({super.key});

  @override
  State<PosturaScreen> createState() => _PosturaScreenState();
}

class _PosturaScreenState extends State<PosturaScreen> {
  // Variables de estado: cada vez que cambian y llamamos a setState(),
  // Flutter vuelve a dibujar la pantalla automáticamente.
  String estadoConexion = "Desconectado";
  int anguloX = 90; // valor neutro inicial, antes de recibir el primer dato real
  int anguloY = 90;

  BluetoothDevice? dispositivoConectado;

  @override
  void initState() {
    super.initState();
    _iniciarProceso();
  }

  // Es importante cerrar la conexión BLE si el usuario sale de esta
  // pantalla, o el ESP32 puede quedar "pensando" que sigue conectado.
  @override
  void dispose() {
    dispositivoConectado?.disconnect();
    super.dispose();
  }

  Future<void> _iniciarProceso() async {
    await _pedirPermisos();
    await _escanearYConectar();
  }

  Future<void> _pedirPermisos() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _escanearYConectar() async {
    setState(() => estadoConexion = "Buscando ESP32_Sensor_Postura...");

    // withNames filtra el escaneo para que solo nos avise de
    // dispositivos con ese nombre exacto - evita procesar de más
    // si hay otros dispositivos BLE cerca (audífonos, etc.)
    FlutterBluePlus.startScan(
      withNames: [NOMBRE_DISPOSITIVO],
      timeout: const Duration(seconds: 8),
    );

    // scanResults es un "Stream" - una especie de cañería de datos
    // que va entregando resultados a medida que aparecen, no todos
    // de una vez. listen() se ejecuta cada vez que hay resultados nuevos.
    FlutterBluePlus.scanResults.listen((resultados) async {
      for (ScanResult r in resultados) {
        if (r.device.platformName == NOMBRE_DISPOSITIVO) {
          await FlutterBluePlus.stopScan(); // ya lo encontramos, dejamos de buscar
          await _conectar(r.device);
          break;
        }
      }
    });
  }

  Future<void> _conectar(BluetoothDevice device) async {
    setState(() => estadoConexion = "Conectando...");

    try {
      await device.connect();
      dispositivoConectado = device;

      // discoverServices() le pregunta al ESP32 "¿qué servicios y
      // características tienes?" - es el equivalente en código a lo
      // que veías visualmente en la app nRF Connect.
      List<BluetoothService> servicios = await device.discoverServices();

      for (BluetoothService servicio in servicios) {
        // Comparamos en minúsculas porque a veces un lado entrega
        // el UUID en mayúsculas y el otro en minúsculas - son el
        // mismo UUID, pero la comparación de texto es sensible a eso.
        if (servicio.uuid.toString().toLowerCase() == SERVICE_UUID) {
          for (BluetoothCharacteristic caracteristica
              in servicio.characteristics) {
            if (caracteristica.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID) {
              await _suscribirseANotificaciones(caracteristica);
            }
          }
        }
      }
    } catch (e) {
      setState(() => estadoConexion = "Error al conectar: $e");
    }
  }

  Future<void> _suscribirseANotificaciones(
      BluetoothCharacteristic caracteristica) async {
    // Esto es el equivalente en código al ícono de "tres flechas"
    // que tocaste en nRF Connect - activa las notificaciones.
    await caracteristica.setNotifyValue(true);

    setState(() => estadoConexion = "Conectado ✔");

    // lastValueStream también es un Stream: cada vez que el ESP32
    // manda un notify(), un valor nuevo aparece aquí automáticamente.
    caracteristica.lastValueStream.listen((valor) {
      // 'valor' llega como una lista de bytes (List<int>), igual que
      // viste en nRF Connect el "0x7B-22-78-22..." en hexadecimal.
      // utf8.decode() lo convierte de vuelta a texto legible.
      String textoRecibido = utf8.decode(valor);

      try {
        // Convertimos el texto '{"x":87,"y":102}' en un Map de Dart
        // que podemos leer como si fuera un diccionario.
        Map<String, dynamic> datos = jsonDecode(textoRecibido);

        setState(() {
          anguloX = datos['x'];
          anguloY = datos['y'];
        });
      } catch (e) {
        // Si llega un dato incompleto o corrupto (puede pasar
        // ocasionalmente con BLE), lo ignoramos en vez de que la
        // app se caiga - simplemente esperamos el próximo valor.
        debugPrint("Dato BLE no se pudo interpretar: $textoRecibido");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postura en vivo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              estadoConexion,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Text(
              'Ángulo X: $anguloX°',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Ángulo Y: $anguloY°',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}