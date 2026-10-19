// ============================================================
// parametros_juego.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v8 — paso F8
//
// CAMBIOS v8 respecto a la v7:
//  - Parámetros de PISTA Y CELEBRACIÓN (para alternar variantes entre
//    participantes y comparar):
//      pistaAnimada         la pista se muestra con una flecha que late
//                           sobre la figura grande (no = solo la miniatura)
//      vibrarPista          el teléfono vibra una vez cuando aparece la
//                           pista (apagado por defecto)
//      celebracionAnimada   saltito de la figura + confeti, y cierre con
//                           las poses (no = la celebración sencilla de antes)
//      segundosCelebracion  cuánto dura la celebración de cada pose
//
// Los parámetros del juego que se pueden cambiar DESDE LA APP
// (Configuración → Parámetros del juego), sin recompilar. Sirven para
// probar variantes en el mismo testeo y justificar cuál queda.
//
// Cada juego guarda los parámetros con que se jugó (en su registro),
// así al analizar se sabe qué variante tuvo cada niño.
//
// Los VALORES POR DEFECTO de abajo son los mismos que tenía el código
// antes de F2: si no se toca el panel, el juego se comporta igual.
//
// Unidades del sensor ≈ 90 × seno(ángulo):
//   9 u ≈ 6°, 10 u ≈ 6,5°, 18 u ≈ 11,5°, 20 u ≈ 13°, 28 u ≈ 18°.
// ============================================================

// ---------- VALORES POR DEFECTO ----------
// Cuánto hay que inclinarse a cada lado en las poses de lado.
const double defectoAnguloLateral = 18;
// Cuánto puede desviarse hacia los lados y que igual cuente.
const double defectoMargenLateral = 9;
// Hacia adelante/atrás en las poses de lado (amplio a propósito: al
// inclinarse de lado el cuerpo se encorva un poco de forma natural).
const double defectoMargenAdelante = 20;
// Hacia adelante/atrás en la pose del centro ("bien derecho").
const double defectoMargenAdelanteCentro = 10;
// Segundos que hay que mantener cada pose.
const double defectoSegundosMantener = 10;
// Segundos sin avanzar hasta que aparece la pista.
const double defectoSegundosPista = 20;
// Segundos en una pose hasta que Quique ofrece ayuda.
const double defectoSegundosAyuda = 60;
// La figura se mueve como un espejo (ver figura_tu.dart).
const bool defectoEspejo = true;
// Exageración de la inclinación en pantalla (1.0 = ángulo real).
const double defectoAmplificacion = 1.5;
// Números de prueba sobre la figura (apagar con niños).
const bool defectoMostrarNumeros = true;
// Cero del juego: false = automático (2 s quieto al empezar cada juego);
// true = la calibración del participante (si no tiene, usa el automático).
const bool defectoCeroCalibrado = false;
// El cinturón registra con la calibración del participante (ver arriba).
const bool defectoCinturonCalibrado = true;
// Análisis de recorridos (ver arriba). 4 u ≈ 2,5°.
const double defectoUmbralMovimiento = 4;
const double defectoFactorCercaAnalisis = 1.5;
const double defectoSegundosVentanaPista = 5;
// Juego frontal (ver arriba). 15 u ≈ 9,6°; 30 u ≈ 19,5°.
const double defectoAltoHasta = 5;
const double defectoAnguloMedio = 15;
const double defectoMargenMedio = 6;
const double defectoBolitaDesde = 30;
const double defectoSegundosBolita = 5;
const String defectoCeroFrontal = 'fijo'; // 'fijo' | 'calibrado' | 'automatico'
const List<String> opcionesCeroFrontal = ['fijo', 'calibrado', 'automatico'];
// Pista y celebración (ver arriba).
const bool defectoPistaAnimada = true;
const bool defectoVibrarPista = false;
const bool defectoCelebracionAnimada = true;
const double defectoSegundosCelebracion = 2.5;

// ---------- RANGOS DE LOS DESLIZADORES DEL PANEL ----------
// (mínimo, máximo, paso). Cambiarlos aquí cambia el panel.
const rangoAnguloLateral = (min: 8.0, max: 40.0, paso: 1.0);
const rangoMargenLateral = (min: 3.0, max: 20.0, paso: 1.0);
const rangoMargenAdelante = (min: 5.0, max: 40.0, paso: 1.0);
const rangoMargenAdelanteCentro = (min: 3.0, max: 30.0, paso: 1.0);
const rangoSegundosMantener = (min: 3.0, max: 20.0, paso: 1.0);
const rangoSegundosPista = (min: 5.0, max: 60.0, paso: 5.0);
const rangoSegundosAyuda = (min: 30.0, max: 180.0, paso: 10.0);
const rangoAmplificacion = (min: 1.0, max: 2.5, paso: 0.1);
const rangoUmbralMovimiento = (min: 1.0, max: 12.0, paso: 1.0);
const rangoFactorCercaAnalisis = (min: 1.1, max: 3.0, paso: 0.1);
const rangoSegundosVentanaPista = (min: 2.0, max: 15.0, paso: 1.0);
const rangoAltoHasta = (min: -5.0, max: 15.0, paso: 1.0);
const rangoAnguloMedio = (min: 6.0, max: 30.0, paso: 1.0);
const rangoMargenMedio = (min: 2.0, max: 12.0, paso: 1.0);
const rangoBolitaDesde = (min: 15.0, max: 60.0, paso: 1.0);
const rangoSegundosBolita = (min: 2.0, max: 15.0, paso: 1.0);
const rangoSegundosCelebracion = (min: 1.0, max: 5.0, paso: 0.5);

class ParametrosJuego {
  final double anguloLateral;
  final double margenLateral;
  final double margenAdelante;
  final double margenAdelanteCentro;
  final double segundosMantener;
  final double segundosPista;
  final double segundosAyuda;
  final bool espejo;
  final double amplificacion;
  final bool mostrarNumeros;
  final bool ceroCalibrado;
  final bool cinturonCalibrado;
  final double umbralMovimiento;
  final double factorCercaAnalisis;
  final double segundosVentanaPista;
  final double altoHasta;
  final double anguloMedio;
  final double margenMedio;
  final double bolitaDesde;
  final double segundosBolita;
  final String ceroFrontal;
  final bool pistaAnimada;
  final bool vibrarPista;
  final bool celebracionAnimada;
  final double segundosCelebracion;

  const ParametrosJuego({
    this.anguloLateral = defectoAnguloLateral,
    this.margenLateral = defectoMargenLateral,
    this.margenAdelante = defectoMargenAdelante,
    this.margenAdelanteCentro = defectoMargenAdelanteCentro,
    this.segundosMantener = defectoSegundosMantener,
    this.segundosPista = defectoSegundosPista,
    this.segundosAyuda = defectoSegundosAyuda,
    this.espejo = defectoEspejo,
    this.amplificacion = defectoAmplificacion,
    this.mostrarNumeros = defectoMostrarNumeros,
    this.ceroCalibrado = defectoCeroCalibrado,
    this.cinturonCalibrado = defectoCinturonCalibrado,
    this.umbralMovimiento = defectoUmbralMovimiento,
    this.factorCercaAnalisis = defectoFactorCercaAnalisis,
    this.segundosVentanaPista = defectoSegundosVentanaPista,
    this.altoHasta = defectoAltoHasta,
    this.anguloMedio = defectoAnguloMedio,
    this.margenMedio = defectoMargenMedio,
    this.bolitaDesde = defectoBolitaDesde,
    this.segundosBolita = defectoSegundosBolita,
    this.ceroFrontal = defectoCeroFrontal,
    this.pistaAnimada = defectoPistaAnimada,
    this.vibrarPista = defectoVibrarPista,
    this.celebracionAnimada = defectoCelebracionAnimada,
    this.segundosCelebracion = defectoSegundosCelebracion,
  });

  /// true si todo está en los valores por defecto.
  bool get esPorDefecto => toJson().toString() == const ParametrosJuego().toJson().toString();

  ParametrosJuego copyWith({
    double? anguloLateral,
    double? margenLateral,
    double? margenAdelante,
    double? margenAdelanteCentro,
    double? segundosMantener,
    double? segundosPista,
    double? segundosAyuda,
    bool? espejo,
    double? amplificacion,
    bool? mostrarNumeros,
    bool? ceroCalibrado,
    bool? cinturonCalibrado,
    double? umbralMovimiento,
    double? factorCercaAnalisis,
    double? segundosVentanaPista,
    double? altoHasta,
    double? anguloMedio,
    double? margenMedio,
    double? bolitaDesde,
    double? segundosBolita,
    String? ceroFrontal,
    bool? pistaAnimada,
    bool? vibrarPista,
    bool? celebracionAnimada,
    double? segundosCelebracion,
  }) =>
      ParametrosJuego(
        anguloLateral: anguloLateral ?? this.anguloLateral,
        margenLateral: margenLateral ?? this.margenLateral,
        margenAdelante: margenAdelante ?? this.margenAdelante,
        margenAdelanteCentro: margenAdelanteCentro ?? this.margenAdelanteCentro,
        segundosMantener: segundosMantener ?? this.segundosMantener,
        segundosPista: segundosPista ?? this.segundosPista,
        segundosAyuda: segundosAyuda ?? this.segundosAyuda,
        espejo: espejo ?? this.espejo,
        amplificacion: amplificacion ?? this.amplificacion,
        mostrarNumeros: mostrarNumeros ?? this.mostrarNumeros,
        ceroCalibrado: ceroCalibrado ?? this.ceroCalibrado,
        cinturonCalibrado: cinturonCalibrado ?? this.cinturonCalibrado,
        umbralMovimiento: umbralMovimiento ?? this.umbralMovimiento,
        factorCercaAnalisis: factorCercaAnalisis ?? this.factorCercaAnalisis,
        segundosVentanaPista: segundosVentanaPista ?? this.segundosVentanaPista,
        altoHasta: altoHasta ?? this.altoHasta,
        anguloMedio: anguloMedio ?? this.anguloMedio,
        margenMedio: margenMedio ?? this.margenMedio,
        bolitaDesde: bolitaDesde ?? this.bolitaDesde,
        segundosBolita: segundosBolita ?? this.segundosBolita,
        ceroFrontal: ceroFrontal ?? this.ceroFrontal,
        pistaAnimada: pistaAnimada ?? this.pistaAnimada,
        vibrarPista: vibrarPista ?? this.vibrarPista,
        celebracionAnimada: celebracionAnimada ?? this.celebracionAnimada,
        segundosCelebracion: segundosCelebracion ?? this.segundosCelebracion,
      );

  Map<String, dynamic> toJson() => {
        'anguloLateral': anguloLateral,
        'margenLateral': margenLateral,
        'margenAdelante': margenAdelante,
        'margenAdelanteCentro': margenAdelanteCentro,
        'segundosMantener': segundosMantener,
        'segundosPista': segundosPista,
        'segundosAyuda': segundosAyuda,
        'espejo': espejo,
        'amplificacion': amplificacion,
        'mostrarNumeros': mostrarNumeros,
        'ceroCalibrado': ceroCalibrado,
        'cinturonCalibrado': cinturonCalibrado,
        'umbralMovimiento': umbralMovimiento,
        'factorCercaAnalisis': factorCercaAnalisis,
        'segundosVentanaPista': segundosVentanaPista,
        'altoHasta': altoHasta,
        'anguloMedio': anguloMedio,
        'margenMedio': margenMedio,
        'bolitaDesde': bolitaDesde,
        'segundosBolita': segundosBolita,
        'ceroFrontal': ceroFrontal,
        'pistaAnimada': pistaAnimada,
        'vibrarPista': vibrarPista,
        'celebracionAnimada': celebracionAnimada,
        'segundosCelebracion': segundosCelebracion,
      };

  /// Lee lo guardado; lo que falte o esté mal queda en su valor por defecto.
  factory ParametrosJuego.desdeJson(Map<String, dynamic> j) {
    double n(String k, double d) => (j[k] as num?)?.toDouble() ?? d;
    bool b(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    return ParametrosJuego(
      anguloLateral: n('anguloLateral', defectoAnguloLateral),
      margenLateral: n('margenLateral', defectoMargenLateral),
      margenAdelante: n('margenAdelante', defectoMargenAdelante),
      margenAdelanteCentro: n('margenAdelanteCentro', defectoMargenAdelanteCentro),
      segundosMantener: n('segundosMantener', defectoSegundosMantener),
      segundosPista: n('segundosPista', defectoSegundosPista),
      segundosAyuda: n('segundosAyuda', defectoSegundosAyuda),
      espejo: b('espejo', defectoEspejo),
      amplificacion: n('amplificacion', defectoAmplificacion),
      mostrarNumeros: b('mostrarNumeros', defectoMostrarNumeros),
      ceroCalibrado: b('ceroCalibrado', defectoCeroCalibrado),
      cinturonCalibrado: b('cinturonCalibrado', defectoCinturonCalibrado),
      umbralMovimiento: n('umbralMovimiento', defectoUmbralMovimiento),
      factorCercaAnalisis: n('factorCercaAnalisis', defectoFactorCercaAnalisis),
      segundosVentanaPista: n('segundosVentanaPista', defectoSegundosVentanaPista),
      altoHasta: n('altoHasta', defectoAltoHasta),
      anguloMedio: n('anguloMedio', defectoAnguloMedio),
      margenMedio: n('margenMedio', defectoMargenMedio),
      bolitaDesde: n('bolitaDesde', defectoBolitaDesde),
      segundosBolita: n('segundosBolita', defectoSegundosBolita),
      ceroFrontal: opcionesCeroFrontal.contains(j['ceroFrontal']) ? j['ceroFrontal'] as String : defectoCeroFrontal,
      pistaAnimada: b('pistaAnimada', defectoPistaAnimada),
      vibrarPista: b('vibrarPista', defectoVibrarPista),
      celebracionAnimada: b('celebracionAnimada', defectoCelebracionAnimada),
      segundosCelebracion: n('segundosCelebracion', defectoSegundosCelebracion),
    );
  }
}
