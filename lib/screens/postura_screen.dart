// ============================================================
// postura_screen.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso C2 (usa el servicio de Bluetooth)
//
// CAMBIOS v2 respecto a la v1:
//  - Ya no se conecta por su cuenta: usa ServicioBle
//    (servicios/servicio_ble.dart). Toda la lógica de Bluetooth salió
//    de este archivo.
//  - Al salir de la pantalla NO se desconecta: la conexión vive en el
//    servicio y sigue activa para las demás pantallas.
//  - Muestra todos los datos del firmware v7: ángulos del cuello,
//    inclinación hacia adelante/atrás y hacia los lados con su
//    dirección, y si hay mala postura.
//
// Para qué sirve ahora: es una pantalla de PRUEBA ("datos del
// sensor"), útil para verificar la conexión y calibrar. Más adelante
// quedará dentro de Configuración, en el mundo del apoderado.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/datos_postura.dart';
import '../servicios/servicio_ble.dart';
import '../tema/colores.dart';
import '../tema/tema_app.dart';

class PosturaScreen extends StatefulWidget {
  const PosturaScreen({super.key});

  @override
  State<PosturaScreen> createState() => _PosturaScreenState();
}

class _PosturaScreenState extends State<PosturaScreen> {
  final ServicioBle ble = ServicioBle.instancia;

  @override
  void initState() {
    super.initState();
    ble.iniciar(); // si ya estaba conectado, no hace nada
  }

  String _textoEstado(EstadoConexion e) {
    switch (e) {
      case EstadoConexion.desconectado:
        return 'Desconectado. Reintentando…';
      case EstadoConexion.buscando:
        return 'Buscando el wearable…';
      case EstadoConexion.conectando:
        return 'Conectando…';
      case EstadoConexion.conectado:
        return 'Conectado ✔';
      case EstadoConexion.error:
        return 'No se pudo conectar. Reintentando…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del sensor')),
      // ListenableBuilder redibuja esta parte cada vez que cambia el
      // estado de la conexión o llega un dato nuevo.
      body: ListenableBuilder(
        listenable: Listenable.merge([ble.estado, ble.datos]),
        builder: (context, _) {
          final DatosPostura? d = ble.datos.value;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              // Responsive: en tablet el contenido no se estira de lado a lado.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _textoEstado(ble.estado.value),
                      textAlign: TextAlign.center,
                      style: Textos.secundario,
                    ),
                    if (ble.ultimoError != null &&
                        ble.estado.value == EstadoConexion.error) ...[
                      const SizedBox(height: 8),
                      Text(
                        ble.ultimoError!,
                        textAlign: TextAlign.center,
                        style: Textos.secundario.copyWith(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (d == null)
                      const Text(
                        'Esperando datos…',
                        textAlign: TextAlign.center,
                        style: Textos.cuerpo,
                      )
                    else ...[
                      _tarjeta(
                        'Mala postura',
                        d.malaPostura ? 'Sí' : 'No',
                        color: d.malaPostura ? Colores.ambar : Colores.comodo,
                      ),
                      _tarjeta(
                        'Adelante / atrás',
                        _conDireccion(d.adelante, 'adelante', 'atrás'),
                      ),
                      _tarjeta(
                        'Hacia los lados',
                        _conDireccion(d.lateral, 'derecha', 'izquierda'),
                      ),
                      _tarjeta('Cuello X / Y', '${d.x} / ${d.y}'),
                      if (!d.conDireccion)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'El wearable tiene un firmware anterior a v7: no envía la dirección.',
                            textAlign: TextAlign.center,
                            style: Textos.secundario,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ej.: 12 -> "12 hacia adelante", -5 -> "5 hacia atrás", 0 -> "0 (centro)".
  String _conDireccion(int valor, String positivo, String negativo) {
    if (valor == 0) return '0 (centro)';
    return valor > 0 ? '$valor hacia $positivo' : '${-valor} hacia $negativo';
  }

  Widget _tarjeta(String titulo, String valor, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color ?? Colores.linea, width: color == null ? 1 : 2),
      ),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: Textos.secundario)),
          Text(valor, style: Textos.cuerpoDestacado.copyWith(fontSize: 18)),
        ],
      ),
    );
  }
}
