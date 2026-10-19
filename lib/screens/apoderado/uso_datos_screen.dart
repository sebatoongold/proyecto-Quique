// ============================================================
// uso_datos_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F4 (modo desarrollador)
//
// Herramienta del INVESTIGADOR (Configuración → Datos de prueba: uso
// de la app): el registro de uso del participante activo, del más
// reciente al más antiguo, con un resumen arriba que responde lo que
// importa para el testeo:
//  - cuántas veces se abrió el Historial y desde dónde;
//  - cómo navegó la línea de tiempo: desplazando con el foco o tocando
//    las horas;
//  - intentos de la puerta parental (y cuántos fallaron).
// ============================================================

import 'package:flutter/material.dart';

import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class UsoDatosScreen extends StatelessWidget {
  const UsoDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final codigo = ServicioParticipantes.instancia.activo.value?.codigo;
    final eventos = RegistroUso.de(codigo).reversed.toList();
    int cuenta(String tipo, [String? dato]) =>
        eventos.where((e) => e.tipo == tipo && (dato == null || e.dato == dato)).length;

    return Scaffold(
      appBar: AppBar(title: Text('Uso de la app · ${codigo ?? 'sin participante'}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colores.tarjeta, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen', style: Textos.tituloTarjeta),
                    const SizedBox(height: 6),
                    Text(
                      'Historial abierto: ${eventos.where((e) => e.tipo == 'historial' && (e.dato ?? '').contains('desde')).length} '
                      'veces · desde el Resumen de hoy: ${eventos.where((e) => (e.dato ?? '').contains('resumen_hoy')).length}',
                      style: Textos.cuerpo,
                    ),
                    Text(
                      'Línea de tiempo: desplazó ${cuenta('linea_tiempo', 'desplazo')} · '
                      'tocó horas ${cuenta('linea_tiempo', 'toco_hora')} · '
                      'cambió de día ${cuenta('linea_tiempo', 'cambio_dia')} · '
                      'abrió el mes ${cuenta('linea_tiempo', 'abrio_mes')}',
                      style: Textos.cuerpo,
                    ),
                    Text(
                      'Puerta parental: ${cuenta('puerta_intento', 'ok')} entradas · '
                      '${cuenta('puerta_intento', 'corto')} toques cortos · '
                      '${cuenta('puerta_intento', 'soltada')} soltadas antes',
                      style: Textos.cuerpo,
                    ),
                    Text(
                      'Juegos abiertos por el niño ("Jugar"): ${cuenta('juego_desde', 'boton_jugar')} · '
                      'al mundo del niño desde la actividad sugerida: ${cuenta('mundo', 'nino_por_actividad_sugerida')}',
                      style: Textos.cuerpo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (eventos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no hay eventos para este participante.',
                      textAlign: TextAlign.center, style: Textos.secundario),
                )
              else
                for (final e in eventos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    child: Text(
                      '${_fechaHora(e.hora)}  ${e.tipo}${e.dato == null ? '' : ' · ${e.dato}'}',
                      style: Textos.secundario.copyWith(color: Colores.azul),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fechaHora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}-${dos(d.month)} ${dos(d.hour)}:${dos(d.minute)}:${dos(d.second)}';
  }
}
