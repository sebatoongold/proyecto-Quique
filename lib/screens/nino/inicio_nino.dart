// ============================================================
// inicio_nino.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v10 — paso G5
//
// CAMBIOS v10 respecto a la v9:
//  - La barra de mundos ya no va encima de la pantalla: se quita el
//    espacio extra que se dejaba abajo para las esquinas.
//  - La frase de Sóma usa el estilo Textos.fraseSoma; otros textos,
//    estilos con nombre de tema_app.dart.
//
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
import '../../widgets/escenario.dart';
import 'actividades_screen.dart';
import 'historia_screen.dart';
import 'logros_screen.dart';

// ---------- PARÁMETROS AJUSTABLES ----------
// Alto de la tarjeta Actividades (la principal).
const double altoTarjetaActividades = 104;
// Alto de las tarjetas Historia y Logros (lado a lado).
const double altoTarjetasPequenas = 92;

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
              // --- Arriba: solo Sóma en su escenario ---
              Expanded(
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
                          child: Align(alignment: Alignment.topLeft, child: _globo(frase)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- Abajo: experiencia, Actividades y, debajo, Historia | Logros ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BarraExperiencia(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: altoTarjetaActividades,
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
                    SizedBox(
                      height: altoTarjetasPequenas,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _tarjetaPequena(
                              titulo: 'Historia',
                              subtitulo: vioPrologo ? 'El viaje' : '¡Empieza aquí!',
                              icono: Icons.route_rounded,
                              destacada: !vioPrologo || nuevo != null,
                              alTocar: () => _abrir(context, 'historia', const HistoriaScreen()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _tarjetaPequena(
                              titulo: 'Logros',
                              subtitulo: 'Tu álbum',
                              icono: Icons.photo_album_rounded,
                              alTocar: () => _abrir(context, 'logros', const LogrosScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// G4: tarjeta de media columna (Historia, Logros): ícono arriba, título
  /// y una palabra debajo.
  static Widget _tarjetaPequena({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback alTocar,
    bool destacada = false,
  }) {
    return Material(
      color: Colores.tarjeta,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: destacada ? Colores.ambar : Colores.linea, width: destacada ? 2.5 : 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colores.fondo,
                child: Icon(icono, color: Colores.azul, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: fuenteTitulos, fontSize: 17, fontWeight: FontWeight.w700, color: Colores.azul)),
                    Text(subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Textos.pequeno),
                  ],
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
        child: Text(frase, style: Textos.fraseSoma),
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
                radius: principal ? 30 : 22,
                backgroundColor: principal ? Colores.tarjeta : Colores.fondo,
                child: Icon(icono, color: principal ? Colores.bosque : Colores.azul, size: principal ? 32 : 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontFamily: fuenteTitulos,
                            fontSize: principal ? 21 : 18,
                            fontWeight: FontWeight.w700,
                            color: texto)),
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
