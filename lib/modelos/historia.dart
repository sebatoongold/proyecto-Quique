// ============================================================
// historia.dart
// Fecha: 23-11-2026
// Proyecto: "La espalda no espera" — app Sóma
// Versión: v1 — paso G3 (historia y experiencia)
//
// EL VIAJE DE SÓMA: la historia del mundo niño (ver el documento
// "Guion — El viaje de Sóma"). Sóma, un quique explorador, recorre un
// Chile de fantasía de norte a sur y conoce animales que usan su cuerpo
// de formas distintas. El niño lo ayuda a imitarlos.
//
// La historia es LINEAL: prólogo + 4 capítulos + 1 "próximamente". Cada
// capítulo se abre al alcanzar cierta EXPERIENCIA de explorador (los
// umbrales están en el panel: Parámetros → Historia y experiencia).
//
// Cada capítulo son ESCENAS (viñetas que se pasan tocando):
//   llegada → encuentro → ¡ayúdame! → la foto
// En "¡Ayúdame!" un botón lleva a la actividad donde se practica la
// postura del animal; si el niño la logra, gana la FOTO del animal.
//
// Para cambiar un texto de Sóma, se edita aquí (cada línea es una
// viñeta). Para cambiar un escenario, ver widgets/escenario.dart.
// ============================================================

import 'animal_postura.dart';
import 'juego.dart';
import 'parametros_juego.dart';

/// Los lugares del viaje (cada uno tiene su paisaje dibujado).
enum Lugar {
  madriguera('La madriguera de Sóma'),
  altiplano('Altiplano'),
  desierto('Desierto de Atacama'),
  costa('Costa'),
  lagos('Lagos del sur'),
  patagonia('Patagonia');

  final String nombre;
  const Lugar(this.nombre);
}

/// Qué tipo de viñeta es (cambia lo que se dibuja y los botones).
enum TipoEscena { normal, ayudame, foto }

class Escena {
  final String texto; // lo que dice Sóma
  final bool conAnimal; // el animal aparece en el escenario
  final TipoEscena tipo;
  const Escena(this.texto, {this.conAnimal = false, this.tipo = TipoEscena.normal});
}

class Capitulo {
  final String id; // queda en el progreso y la exportación
  final int numero; // 0 = prólogo
  final String titulo;
  final Lugar lugar;
  final AnimalPostura? animal; // el de la foto (null en el prólogo)
  final Juego? juego; // dónde se practica su postura
  final List<Escena> escenas;
  final bool proximamente; // visible pero todavía no existe

  const Capitulo({
    required this.id,
    required this.numero,
    required this.titulo,
    required this.lugar,
    this.animal,
    this.juego,
    this.escenas = const [],
    this.proximamente = false,
  });

  String get etiqueta => proximamente
      ? 'Próximamente'
      : numero == 0
          ? 'Prólogo'
          : 'Capítulo $numero';

  /// Experiencia que pide para abrirse (con los números del panel).
  int xpNecesaria(ParametrosJuego p) => switch (numero) {
        0 => 0,
        1 => p.xpCapitulo1.round(),
        2 => p.xpCapitulo2.round(),
        3 => p.xpCapitulo3.round(),
        4 => p.xpCapitulo4.round(),
        _ => 1 << 30, // próximamente: nunca
      };
}

// ---------- LA HISTORIA (editar aquí los textos) ----------
const List<Capitulo> capitulosHistoria = [
  Capitulo(
    id: 'prologo',
    numero: 0,
    titulo: 'La mochila de Sóma',
    lugar: Lugar.madriguera,
    escenas: [
      Escena('¡Hola! Soy Sóma, un quique explorador. Mi nombre significa «cuerpo».'),
      Escena('He oído que en este país viven animales que usan su cuerpo de formas increíbles.'),
      Escena('Quiero conocerlos a todos, sacarles una foto y aprender sus posturas.'),
      Escena('Pero imitarlos es difícil… ¡necesito un compañero que me muestre cómo!'),
      Escena('¿Me acompañas? Tú haces la postura y yo te sigo. ¡Vamos al norte!'),
    ],
  ),
  Capitulo(
    id: 'cap1_altiplano',
    numero: 1,
    titulo: 'El quirquincho',
    lugar: Lugar.altiplano,
    animal: AnimalPostura.armadillo,
    juego: juegoDeLoAltoALoBajo,
    escenas: [
      Escena('¡Brrr! En el altiplano las noches son muy frías. Aquí hay que saber guardar el calor.'),
      Escena('¡Mira! Es un quirquincho. Cuando hace frío, se enrolla como una bolita y abraza su calor.',
          conAnimal: true),
      Escena('Yo no me puedo enrollar tan bien… ¿Me muestras cómo? Abraza tus rodillas, ¡yo te sigo!',
          conAnimal: true, tipo: TipoEscena.ayudame),
      Escena('¡Lo logramos! Pero ojo: hacerse bolita sirve un ratito, para descansar. Después, ¡a estirarse otra vez!',
          conAnimal: true, tipo: TipoEscena.foto),
    ],
  ),
  Capitulo(
    id: 'cap2_desierto',
    numero: 2,
    titulo: 'La jirafa de las estrellas',
    lugar: Lugar.desierto,
    animal: AnimalPostura.jirafa,
    juego: juegoDeLoAltoALoBajo,
    escenas: [
      Escena('Este es el desierto de Atacama. Dicen que aquí está el cielo más limpio del mundo.'),
      Escena('¡Una jirafa! Estira todo su cuello y su espalda para ver las estrellas más de cerca.',
          conAnimal: true),
      Escena('Yo me encorvo y no alcanzo a ver nada… ¿Me enseñas a sentarme muy alto, como ella?',
          conAnimal: true, tipo: TipoEscena.ayudame),
      Escena('¡Mira cuántas estrellas se ven cuando nos estiramos!', conAnimal: true, tipo: TipoEscena.foto),
    ],
  ),
  Capitulo(
    id: 'cap3_costa',
    numero: 3,
    titulo: 'El pingüino de Humboldt',
    lugar: Lugar.costa,
    animal: AnimalPostura.pinguino,
    juego: juegoImitaAQuique,
    escenas: [
      Escena('¡Huele a mar! Llegamos a la costa. Aquí las rocas son resbalosas.'),
      Escena('Es un pingüino de Humboldt. Se balancea de un lado a otro para caminar sin caerse.',
          conAnimal: true),
      Escena('Yo me resbalo… ¿Me muestras cómo inclinarse hacia los lados?',
          conAnimal: true, tipo: TipoEscena.ayudame),
      Escena('¡Ya no nos caemos! Despacito hacia un lado, y luego hacia el otro.',
          conAnimal: true, tipo: TipoEscena.foto),
    ],
  ),
  Capitulo(
    id: 'cap4_lagos',
    numero: 4,
    titulo: 'La tortuga sabia',
    lugar: Lugar.lagos,
    animal: AnimalPostura.tortuga,
    juego: juegoDeLoAltoALoBajo,
    escenas: [
      Escena('Los lagos del sur son muy tranquilos. Aquí nadie anda apurado.'),
      Escena('Ella es la tortuga sabia. Dice que no hay que estar ni muy derecho ni muy curvado: el punto medio.',
          conAnimal: true),
      Escena('¿Me ayudas a encontrar el medio camino?', conAnimal: true, tipo: TipoEscena.ayudame),
      Escena('La tortuga dice que lo hicimos muy bien. ¿Quién vivirá más al sur?',
          conAnimal: true, tipo: TipoEscena.foto),
    ],
  ),
  Capitulo(
    id: 'cap5_patagonia',
    numero: 5,
    titulo: '¿Quién vivirá más al sur?',
    lugar: Lugar.patagonia,
    proximamente: true,
  ),
];

Capitulo? capituloPorId(String id) {
  for (final c in capitulosHistoria) {
    if (c.id == id) return c;
  }
  return null;
}

// ---------- INSIGNIAS ----------
class Insignia {
  final String id;
  final String nombre;
  final String como; // cómo se consigue (se muestra mientras falta)
  const Insignia(this.id, this.nombre, this.como);
}

const List<Insignia> insigniasExplorador = [
  Insignia('primera_exploracion', 'Primera exploración', 'Termina tu primera actividad'),
  Insignia('todas_las_poses', 'Todas las posturas', 'Logra todas las posturas de una actividad'),
  Insignia('tres_dias', 'Explorador constante', 'Explora 3 días en una misma semana'),
  Insignia('viaje_completo', 'Gran viaje', 'Mira los 4 capítulos del viaje'),
];
