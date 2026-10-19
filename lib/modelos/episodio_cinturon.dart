// ============================================================
// episodio_cinturon.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paso F7.2 (lectura de la cola del firmware)
//
// Un episodio de mala postura tal como lo REGISTRÓ EL CINTURÓN (su cola
// persistente), leído por la app con el protocolo de tandas + ACK.
// A diferencia de los episodios que calcula la app en vivo (F5), estos
// existen aunque el teléfono no haya estado conectado.
//
//  - id: único y creciente (lo asigna el firmware; sirve para no
//    guardar dos veces el mismo episodio).
//  - horaInicio: hora real, calculada por el teléfono al leerlo:
//      hora = hora del teléfono − (millis "ahora" − millis de inicio)
//    Solo se puede si el episodio es del mismo encendido (bootId) que
//    la lectura; si no, queda null ("hora no disponible").
//  - dsAdelante / dsLateral / dsAmbos: décimas de segundo en cada
//    dirección (duración total = la suma).
//  - idCal: con qué calibración se midió (0 = umbral fijo, sin calibrar).
//  - participante: a quién se le atribuyó al leerlo (ver
//    servicio_cinturon.dart).
// ============================================================

class EpisodioCinturon {
  final int id;
  final int boot;
  final int millisInicio;
  final DateTime? horaInicio; // null = hora no disponible
  final int dsAdelante;
  final int dsLateral;
  final int dsAmbos;
  final int idCal;
  final String? participante;
  final DateTime recibido; // cuándo lo leyó la app

  const EpisodioCinturon({
    required this.id,
    required this.boot,
    required this.millisInicio,
    required this.horaInicio,
    required this.dsAdelante,
    required this.dsLateral,
    required this.dsAmbos,
    required this.idCal,
    required this.participante,
    required this.recibido,
  });

  int get msDuracion => (dsAdelante + dsLateral + dsAmbos) * 100;

  /// true si se midió con una calibración (no con el umbral fijo).
  bool get calibrado => idCal != 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'boot': boot,
        'millisInicio': millisInicio,
        'horaInicio': horaInicio?.toIso8601String(),
        'dsAdelante': dsAdelante,
        'dsLateral': dsLateral,
        'dsAmbos': dsAmbos,
        'idCal': idCal,
        'participante': participante,
        'recibido': recibido.toIso8601String(),
      };

  factory EpisodioCinturon.desdeJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    final hora = j['horaInicio'] as String?;
    return EpisodioCinturon(
      id: n('id'),
      boot: n('boot'),
      millisInicio: n('millisInicio'),
      horaInicio: hora == null ? null : DateTime.tryParse(hora),
      dsAdelante: n('dsAdelante'),
      dsLateral: n('dsLateral'),
      dsAmbos: n('dsAmbos'),
      idCal: n('idCal'),
      participante: j['participante'] as String?,
      recibido: DateTime.tryParse(j['recibido'] as String? ?? '') ?? DateTime(2000),
    );
  }
}

/// La configuración que el cinturón informó tener cargada (cabecera de
/// la lectura del registro, firmware v8).
class ConfigCinturon {
  final int idCal;
  final double neutroX;
  final double neutroY;
  final double umbralAdelante;
  final double umbralLateral;
  final int pendientes;
  final DateTime leida;

  const ConfigCinturon({
    required this.idCal,
    required this.neutroX,
    required this.neutroY,
    required this.umbralAdelante,
    required this.umbralLateral,
    required this.pendientes,
    required this.leida,
  });
}
