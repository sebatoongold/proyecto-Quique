// ============================================================
// inicio_nino.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v8 — paso G3 (historia y experiencia)
//
// CAMBIOS v8 respecto a la v7:
//  - Es el INICIO DEL NIÑO con historia (lamina_mundo_nino_v1):
//      · arriba, Sóma en el escenario del último lugar abierto del viaje,
//        con un globo que lo invita a seguir, y la barra de experiencia;
//      · abajo, tres tarjetas: ACTIVIDADES (los dos juegos, ahora en su
//        propia pantalla), HISTORIA (el viaje) y LOGROS (el álbum).
//  - Si todavía no vio el prólogo, Sóma se presenta y la tarjeta Historia
//    dice "¡Empieza aquí!". Si hay un capítulo nuevo sin ver, Sóma lo
//    anuncia; tocar el escenario lleva a la Historia.
//  - Cada tarjeta se anota en el registro de uso ('menu_nino').
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/historia.dart';
import '../../modelos/participante.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_parametros.dart';
import '../../servicios/servicio_participantes.dart';
import '../../servicios/servicio_progreso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/barra_experiencia.dart';
import '../../widgets/barra_mundos.dart';
import '../../widgets/escenario.dart';
import 'actividades_screen.dart';
import 'historia_screen.dart';
import 'logros_screen.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Parte de la pantalla que ocupa el escenario de Sóma (el resto, las tarjetas).
const int flexEscenarioInicio = 5;
const int flexTarjetasInicio = 5;

class InicioNino extends StatelessWidget {
  const InicioNino({super.key});

  @override
  Widget build(BuildContext context) {
    // Se redibuja si cambia el participante, su progreso o los parámetros.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ServicioParticipantes.instancia.activo,
        ServicioProgreso.instancia.cambios,
        ServicioParametros.instancia.actual,
      ]),
      builder: (context, _) => _contenido(context, ServicioParticipantes.instancia.activo.value),
    );
  }

  Widget _contenido(BuildContext context, Participante? activo) {
    final progreso = ServicioProgreso.instancia.actual;
    final par = ServicioParametros.instancia.actual.value;
    final abiertos = [
      for (final c in capitulosHistoria)
        if (!c.proximamente && progreso.xp >= c.xpNecesaria(par)) c,
    ];
    final ultimo = abiertos.isEmpty ? capitulosHistoria.first : abiertos.last;
    final vioPrologo = progreso.capitulosVistos.contains('prologo');
    Capitulo? nuevo; // primer capítulo abierto que todavía no ve
    for (final c in abiertos) {
      if (!progreso.capitulosVistos.contains(c.id)) {
        nuevo = c;
        break;
      }
    }

    // Lo que dice Sóma en el inicio.
    final String frase;
    if (!vioPrologo) {
      frase = '¡Hola! Soy Sóma. ¿Me acompañas en mi viaje?';
    } else if (nuevo != null) {
      frase = '¡Llegamos a ${nuevo.lugar.nombre}! ¿Vemos qué hay?';
    } else {
      frase = activo == null ? '¡Hola! ¿Seguimos el viaje?' : '¡Hola, ${activo.nombreVisible}! ¿Seguimos el viaje?';
    }

    return Container(
      color: Colores.arena,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Arriba: Sóma en su escenario ---
              Expanded(
                flex: flexEscenarioInicio,
                child: GestureDetector(
                  onTap: () => _abrir(context, 'historia', const HistoriaScreen()),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Escenario(lugar: ultimo.lugar),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _globo(frase),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                decoration: BoxDecoration(
                                  color: Colores.tarjeta.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const BarraExperiencia(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- Abajo: las tres tarjetas ---
              Expanded(
                flex: flexTarjetasInicio,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, espacioBajoEsquinas - 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: _tarjeta(
                          context,
                          titulo: 'Actividades',
                          subtitulo: 'Ayuda a Sóma con las posturas',
                          icono: Icons.accessibility_new_rounded,
                          principal: true,
                          alTocar: () => _abrir(context, 'actividades', const ActividadesScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _tarjeta(
                          context,
                          titulo: 'Historia',
                          subtitulo: vioPrologo ? 'El viaje de Sóma por Chile' : '¡Empieza aquí!',
                          icono: Icons.route_rounded,
                          destacada: !vioPrologo || nuevo != null,
                          alTocar: () => _abrir(context, 'historia', const HistoriaScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _tarjeta(
                          context,
                          titulo: 'Logros',
                          subtitulo: 'Tu álbum de explorador',
                          icono: Icons.photo_album_rounded,
                          alTocar: () => _abrir(context, 'logros', const LogrosScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _abrir(BuildContext context, String cual, Widget pantalla) {
    RegistroUso.anotar('menu_nino', dato: cual);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  static Widget _globo(String frase) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colores.tarjeta,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(frase, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colores.azul)),
      ),
    );
  }

  static Widget _tarjeta(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback alTocar,
    bool principal = false,
    bool destacada = false,
  }) {
    final fondo = principal ? Colores.bosque : Colores.tarjeta;
    final texto = principal ? Colores.tarjeta : Colores.azul;
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: destacada ? Colores.ambar : (principal ? fondo : Colores.linea),
              width: destacada ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: principal ? Colores.tarjeta : Colores.fondo,
                child: Icon(icono, color: principal ? Colores.bosque : Colores.azul),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontFamily: fuenteTitulos, fontSize: 18, fontWeight: FontWeight.w700, color: texto)),
                    Text(subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: principal ? Colores.base : Colores.textoSecundario)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: texto, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
