// ============================================================
// configuracion_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v5 — paso F3
//
// CAMBIOS v5 respecto a la v4:
//  - Nueva opción "Calibrar postura" del participante activo (muestra
//    si ya está calibrado y con qué frase).
//  - El resumen de la variante dice si el juego usa el cero calibrado.
//
// Sección "Testeo": participante activo (crear, elegir, exportar).
//
// Se abre desde el engranaje del inicio del apoderado. Reúne las
// herramientas de prueba:
//  - Datos del sensor: los valores en vivo del cinturón (calibrar).
//  - Datos de prueba: juegos (métricas crudas, para el diseñador y el
//    análisis del testeo; el apoderado ve el Historial).
// Más adelante: vinculación, recalibrar, editar perfil y ayuda.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/parametros_juego.dart';
import '../../modelos/participante.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../postura_screen.dart';
import 'calibracion_screen.dart';
import 'parametros_screen.dart';
import 'participantes_screen.dart';
import 'registro_juegos_screen.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Testeo', style: Textos.secundario),
              ),
              // Participante activo: se actualiza solo al cambiarlo.
              ValueListenableBuilder<Participante?>(
                valueListenable: ServicioParticipantes.instancia.activo,
                builder: (context, activo, _) => _opcion(
                  context,
                  icono: Icons.badge_rounded,
                  titulo: activo == null ? 'Sin participante' : 'Participante ${activo.codigo}',
                  subtitulo: activo == null
                      ? 'Elige o crea uno antes de que juegue'
                      : '${activo.nombreVisible} · ${activo.edadTexto} · cambiar o exportar',
                  destino: const ParticipantesScreen(),
                ),
              ),
              const SizedBox(height: 10),
              // Calibración del participante activo.
              ValueListenableBuilder<Participante?>(
                valueListenable: ServicioParticipantes.instancia.activo,
                builder: (context, activo, _) {
                  final cal = activo?.calibracion;
                  return _opcion(
                    context,
                    icono: Icons.accessibility_new_rounded,
                    titulo: 'Calibrar postura',
                    subtitulo: activo == null
                        ? 'Primero elige un participante'
                        : (cal == null
                            ? '${activo.codigo}: todavía sin calibrar'
                            : '${activo.codigo}: calibrado con «${cal.instruccion}» · repetir'),
                    destino: activo == null
                        ? const ParticipantesScreen()
                        : CalibracionScreen(participante: activo),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Parámetros del juego: avisa si hay una variante modificada.
              ValueListenableBuilder<ParametrosJuego>(
                valueListenable: ServicioParametros.instancia.actual,
                builder: (context, p, _) => _opcion(
                  context,
                  icono: Icons.tune_rounded,
                  titulo: 'Parámetros del juego',
                  subtitulo: p.esPorDefecto
                      ? 'Valores por defecto'
                      : 'Variante modificada · ángulo ${p.anguloLateral.round()}, '
                          'margen ${p.margenLateral.round()}, ${p.segundosMantener.round()} s'
                          '${p.espejo ? '' : ', sin espejo'}'
                          '${p.ceroCalibrado ? ', cero calibrado' : ''}',
                  destino: const ParametrosScreen(),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Herramientas de prueba', style: Textos.secundario),
              ),
              _opcion(
                context,
                icono: Icons.sensors_rounded,
                titulo: 'Datos del sensor',
                subtitulo: 'Valores en vivo del cinturón',
                destino: const PosturaScreen(),
              ),
              const SizedBox(height: 10),
              _opcion(
                context,
                icono: Icons.list_alt_rounded,
                titulo: 'Datos de prueba: juegos',
                subtitulo: 'Métricas crudas del participante activo',
                destino: const RegistroJuegosScreen(),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Próximamente: vinculación del cinturón, recalibrar, editar perfil y ayuda.',
                  style: Textos.secundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icono, color: Colores.azul),
        title: Text(titulo, style: Textos.cuerpoDestacado),
        subtitle: Text(subtitulo, style: Textos.secundario),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colores.azul),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino)),
      ),
    );
  }
}
