// ============================================================
// capitulo_screen.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// Un CAPÍTULO de la historia, viñeta por viñeta (modelos/historia.dart):
//  - Arriba, el escenario del lugar con Sóma (y el animal cuando aparece).
//  - Abajo, lo que dice Sóma y los botones.
//  - "¡Ayúdame!": Sóma se tambalea intentando la postura. El botón
//    "Ayudar a Sóma" abre la actividad del capítulo; si el niño logra la
//    postura del animal, gana su FOTO y la historia sigue sola. También
//    puede "seguir leyendo" sin jugar (la foto queda pendiente).
//  - "La foto": si la tiene, se ve la foto (polaroid) del animal.
//  - Al terminar: el capítulo queda visto y suma experiencia (una vez).
//
// No hay sonido: el investigador o el apoderado lee los textos en voz
// alta a los niños que todavía no leen.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/historia.dart';
import '../../servicios/registro_uso.dart';
import '../../servicios/servicio_progreso.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';
import '../../widgets/escenario.dart';
import '../../widgets/icono_animal.dart';
import 'ejecucion_screen.dart';

class CapituloScreen extends StatefulWidget {
  final Capitulo capitulo;
  const CapituloScreen({super.key, required this.capitulo});

  @override
  State<CapituloScreen> createState() => _CapituloScreenState();
}

class _CapituloScreenState extends State<CapituloScreen> {
  int _indice = 0;

  Capitulo get _c => widget.capitulo;
  Escena get _escena => _c.escenas[_indice];
  bool get _ultima => _indice == _c.escenas.length - 1;
  bool get _tieneFoto => _c.animal != null && ServicioProgreso.instancia.actual.fotos.contains(_c.animal!.id);

  void _siguiente() {
    if (_ultima) {
      _terminar();
    } else {
      setState(() => _indice++);
    }
  }

  Future<void> _ayudar() async {
    final juego = _c.juego;
    if (juego == null) return;
    RegistroUso.anotar('historia_ayudar', dato: _c.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EjecucionScreen(juego: juego, fotoDe: _c.animal)),
    );
    if (!mounted) return;
    // Si consiguió la foto, la historia sigue sola hasta la foto.
    if (_tieneFoto) setState(() => _indice++);
  }

  Future<void> _terminar() async {
    final xp = await ServicioProgreso.instancia.capituloVisto(_c);
    if (!mounted) return;
    if (xp > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Capítulo terminado! +$xp XP de explorador')),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final esFoto = _escena.tipo == TipoEscena.foto;
    return Scaffold(
      backgroundColor: Colores.arena,
      appBar: AppBar(
        backgroundColor: Colores.arena,
        title: Text('${_c.etiqueta} · ${_c.titulo}', overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- La viñeta ---
                  Expanded(
                    child: GestureDetector(
                      // Tocar la imagen también avanza (menos en "¡Ayúdame!").
                      onTap: _escena.tipo == TipoEscena.ayudame ? null : _siguiente,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: esFoto && _tieneFoto
                            ? _foto()
                            : Escenario(
                                lugar: _c.lugar,
                                animal: _escena.conAnimal ? _c.animal : null,
                                somaTambalea: _escena.tipo == TipoEscena.ayudame,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _puntos(),
                  const SizedBox(height: 12),
                  // --- Lo que dice Sóma ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colores.tarjeta,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colores.linea),
                    ),
                    child: Text(_escena.texto,
                        style: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w600, color: Colores.azul)),
                  ),
                  if (esFoto && !_tieneFoto && _c.animal != null) ...[
                    const SizedBox(height: 8),
                    Text('La foto de ${_c.animal!.conArticulo} se consigue ayudando a Sóma.',
                        textAlign: TextAlign.center, style: Textos.secundario),
                  ],
                  const SizedBox(height: 14),
                  ..._botones(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _botones() {
    if (_escena.tipo == TipoEscena.ayudame) {
      return [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
          icon: const Icon(Icons.accessibility_new_rounded),
          label: const Text('Ayudar a Sóma'),
          onPressed: _ayudar,
        ),
        TextButton(onPressed: _siguiente, child: const Text('Seguir leyendo')),
      ];
    }
    return [
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
        onPressed: _siguiente,
        child: Text(_ultima ? (_c.numero == 0 ? '¡Vamos!' : 'Terminar capítulo') : 'Siguiente'),
      ),
    ];
  }

  Widget _puntos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _c.escenas.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i <= _indice ? Colores.bosque : Colores.linea),
          ),
      ],
    );
  }

  /// La foto del animal, como una polaroid sobre el escenario.
  Widget _foto() {
    final animal = _c.animal!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Escenario(lugar: _c.lugar, mostrarSoma: false),
        Center(
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: Colores.tarjeta,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    color: animal.fondo,
                    alignment: Alignment.center,
                    child: IconoAnimal(animal: animal, tamano: 130),
                  ),
                  const SizedBox(height: 10),
                  Text(animal.nombre,
                      style: const TextStyle(
                          fontFamily: fuenteTitulos, fontSize: 20, fontWeight: FontWeight.w700, color: Colores.azul)),
                  Text(_c.lugar.nombre, style: Textos.secundario.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
