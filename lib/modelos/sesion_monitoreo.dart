// ============================================================
// sesion_monitoreo.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F5 (monitoreo en vivo)
//
// Una SESIÓN DE MONITOREO es un rato en que el niño usa el cinturón
// mientras hace lo suyo (en el testeo: los 20–30 minutos del inicio).
// La app guarda CADA lectura que llega del cinturón (~3 por segundo),
// para poder calcular después los episodios con dos criterios:
//  - FIJO: el del firmware (sus umbrales, iguales para todos);
//  - CALIBRADO: los mismos umbrales, pero medidos desde la postura
//    neutral calibrada del niño (paso F3).
//
// Las lecturas se guardan en listas compactas (no un objeto por
// lectura) para que 30 minutos ocupen poco: t (ms desde el inicio),
// x = difXs, y = difYs (con signo, tal como llegan) y m = 1 si el
// firmware marcó mala postura.
//
// También guarda la ESTIMACIÓN del apoderado ("¿cuántas veces crees
// que…?"), que se pregunta al terminar, ANTES de mostrar el resultado.
// ============================================================

// ---------- PARÁMETROS AJUSTABLES ----------
// Opciones de la pregunta al apoderado (en rangos: más fácil de
// responder que un número exacto, y comparable entre apoderados).
const List<String> opcionesEstimacion = [
  'Ninguna',
  '1 a 3',
  '4 a 6',
  '7 a 10',
  'Más de 10',
  'No sé',
];

class SesionMonitoreo {
  final String? participante; // código (P01…); null = sin participante
  final DateTime inicio;
  DateTime? fin;
  bool interrumpida = false; // la app se cerró antes de terminarla
  String? estimacionApoderado; // una de opcionesEstimacion, o null si no se preguntó

  // Calibración del niño al momento de la sesión (para el criterio
  // calibrado). null = no tenía.
  double? calibracionDifXs;
  double? calibracionDifYs;

  // Lecturas.
  final List<int> t = []; // ms desde el inicio
  final List<int> x = []; // difXs
  final List<int> y = []; // difYs
  final List<int> m = []; // 1 = el firmware marcó mala postura

  SesionMonitoreo({required this.participante, required this.inicio});

  int get lecturas => t.length;

  Duration get duracion => (fin ?? DateTime.now()).difference(inicio);

  void agregar(DateTime cuando, int difXs, int difYs, bool mala) {
    t.add(cuando.difference(inicio).inMilliseconds);
    x.add(difXs);
    y.add(difYs);
    m.add(mala ? 1 : 0);
  }

  Map<String, dynamic> toJson({bool conLecturas = true}) => {
        'participante': participante,
        'inicio': inicio.toIso8601String(),
        'fin': fin?.toIso8601String(),
        'interrumpida': interrumpida,
        'estimacionApoderado': estimacionApoderado,
        'calibracionDifXs': calibracionDifXs,
        'calibracionDifYs': calibracionDifYs,
        'lecturas': lecturas,
        if (conLecturas) ...{'t': t, 'x': x, 'y': y, 'm': m},
      };

  factory SesionMonitoreo.desdeJson(Map<String, dynamic> j) {
    final s = SesionMonitoreo(
      participante: j['participante'] as String?,
      inicio: DateTime.tryParse(j['inicio'] as String? ?? '') ?? DateTime(2000),
    );
    final fin = j['fin'] as String?;
    s.fin = fin == null ? null : DateTime.tryParse(fin);
    s.interrumpida = j['interrumpida'] == true;
    s.estimacionApoderado = j['estimacionApoderado'] as String?;
    s.calibracionDifXs = (j['calibracionDifXs'] as num?)?.toDouble();
    s.calibracionDifYs = (j['calibracionDifYs'] as num?)?.toDouble();
    List<int> enteros(String k) {
      final v = j[k];
      return v is List ? v.map((e) => (e as num).toInt()).toList() : <int>[];
    }

    final tt = enteros('t'), xx = enteros('x'), yy = enteros('y'), mm = enteros('m');
    // Solo se cargan si las cuatro listas calzan (si no, datos dañados).
    if (tt.length == xx.length && tt.length == yy.length && tt.length == mm.length) {
      s.t.addAll(tt);
      s.x.addAll(xx);
      s.y.addAll(yy);
      s.m.addAll(mm);
    }
    return s;
  }
}
