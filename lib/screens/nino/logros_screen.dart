// ============================================================
// logros_screen.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// LOGROS: el álbum de explorador, en tres pestañas.
//  - FOTOS: una por animal, se gana ayudando a Sóma en su capítulo.
//    Las que faltan se ven grises con "?" y dicen dónde conseguirlas.
//  - POSTALES: una por lugar, al terminar de ver su capítulo.
//  - INSIGNIAS: por hitos de uso (modelos/historia.dart).
// Todo se consigue haciendo algo concreto: nada al azar.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/historia.dart';
import '../../servicios/servicio_progreso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/escenario.dart';
import '../../widgets/icono_animal.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progreso = ServicioProgreso.instancia.actual;
    final conFoto = [for (final c in capitulosHistoria) if (c.animal != null && !c.proximamente) c];
    final lugares = conFoto; // una postal por cada capítulo con lugar
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colores.arena,
        appBar: AppBar(
          backgroundColor: Colores.arena,
          title: Text('Álbum de explorador · ${progreso.xp} XP'),
          bottom: const TabBar(
            labelColor: Colores.azul,
            indicatorColor: Colores.ambar,
            tabs: [Tab(text: 'Fotos'), Tab(text: 'Postales'), Tab(text: 'Insignias')],
          ),
        ),
        body: TabBarView(
          children: [
            _grilla([
              for (final c in conFoto)
                _polaroid(
                  tiene: progreso.fotos.contains(c.animal!.id),
                  imagen: Container(
                    color: c.animal!.fondo,
                    alignment: Alignment.center,
                    child: IconoAnimal(animal: c.animal!, tamano: 96),
                  ),
                  titulo: c.animal!.nombre,
                  pie: c.lugar.nombre,
                  falta: 'Ayuda a Sóma en ${c.lugar.nombre}',
                ),
            ], '${progreso.fotos.length} de ${conFoto.length} fotos'),
            _grilla([
              for (final c in lugares)
                _polaroid(
                  tiene: progreso.postales.contains(c.lugar.name),
                  imagen: Escenario(lugar: c.lugar, mostrarSoma: false),
                  titulo: c.lugar.nombre,
                  pie: c.titulo,
                  falta: 'Mira el capítulo ${c.numero}',
                ),
            ], '${progreso.postales.length} de ${lugares.length} postales'),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final i in insigniasExplorador) _insignia(i, progreso.insignias.contains(i.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _grilla(List<Widget> hijos, String resumen) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(resumen, style: Textos.secundario),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
          children: hijos,
        ),
      ],
    );
  }

  /// Una foto tipo polaroid. Si no la tiene: gris, con "?" y dónde se consigue.
  Widget _polaroid({
    required bool tiene,
    required Widget imagen,
    required String titulo,
    required String pie,
    required String falta,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colores.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: tiene
                  ? imagen
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(opacity: 0.2, child: imagen),
                        const Center(
                          child: Text('?',
                              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: Colores.neutro)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(tiene ? titulo : '¿?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: fuenteTitulos,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tiene ? Colores.azul : Colores.neutro)),
          Text(tiene ? pie : falta,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Textos.secundario.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _insignia(Insignia i, bool tiene) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tiene ? Colores.tarjeta : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tiene ? Colores.ambar : Colores.linea, width: tiene ? 2 : 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: tiene ? Colores.ambar : Colores.fondo,
            child: Icon(tiene ? Icons.military_tech_rounded : Icons.lock_rounded,
                color: tiene ? Colores.azul : Colores.neutro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.nombre,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: tiene ? Colores.azul : Colores.neutro)),
                Text(i.como, style: Textos.secundario.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
