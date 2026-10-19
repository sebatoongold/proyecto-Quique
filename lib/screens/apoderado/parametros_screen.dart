// ============================================================
// parametros_screen.dart
// Fecha: 19-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v6 — paso F4
//
// CAMBIOS v6 respecto a la v5:
//  - Nueva sección "Análisis de recorridos": los tres umbrales con que
//    se leen los recorridos en Datos de prueba. No cambian el juego, y
//    se aplican también a los juegos ya jugados.
//
// Herramienta del INVESTIGADOR (Configuración → Parámetros del juego):
// cambia cómo se comporta el juego sin recompilar, para probar
// variantes en el testeo (p. ej. ángulo 18 vs. 28, espejo sí vs. no).
//
//  - Los cambios se guardan solos al soltar cada deslizador o
//    interruptor, y se aplican DESDE EL PRÓXIMO JUEGO.
//  - Cada juego guarda los parámetros con que se jugó: en "Datos de
//    prueba" y en los datos exportados se ve qué variante fue.
//  - "Restaurar" vuelve a los valores por defecto (los de antes de F2).
//
// Los valores por defecto y los rangos de cada deslizador están en
// modelos/parametros_juego.dart.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../modelos/parametros_juego.dart';
import '../../servicios/servicio_parametros.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

typedef _Rango = ({double min, double max, double paso});

class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  final _servicio = ServicioParametros.instancia;
  late ParametrosJuego _p = _servicio.actual.value;

  /// Unidades del sensor -> grados aproximados (unidades ≈ 90 × seno).
  static String _grados(double u) {
    final g = math.asin((u / 90).clamp(-1.0, 1.0)) * 180 / math.pi;
    return '≈ ${g.round()}°';
  }

  void _cambiar(ParametrosJuego nuevos, {bool guardar = false}) {
    setState(() => _p = nuevos);
    if (guardar) _servicio.cambiar(nuevos);
  }

  Future<void> _restaurar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Volver a los valores por defecto?'),
        content: const Text('Se aplicarán desde el próximo juego.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    await _servicio.restaurar();
    setState(() => _p = _servicio.actual.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parámetros del juego'),
        actions: [
          TextButton(onPressed: _restaurar, child: const Text('Restaurar')),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _estado(),
              const SizedBox(height: 20),

              _seccion('Postura cero'),
              _interruptor(
                titulo: 'Usar la calibración del participante',
                ayuda: _p.ceroCalibrado
                    ? 'Sí: el juego parte desde su postura neutral calibrada y se salta '
                        '"siéntate derecho". Si no tiene calibración, usa el automático.'
                    : 'No (automático): al empezar cada juego, 2 s quieto y sin mala postura.',
                valor: _p.ceroCalibrado,
                alCambiar: (v) => _cambiar(_p.copyWith(ceroCalibrado: v), guardar: true),
              ),

              _seccion('Poses'),
              _deslizador(
                titulo: 'Cuánto inclinarse (poses de lado)',
                ayuda: 'Más alto = la pose pide inclinarse más.',
                valor: _p.anguloLateral,
                rango: rangoAnguloLateral,
                texto: '${_p.anguloLateral.round()} u ${_grados(_p.anguloLateral)}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(anguloLateral: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Margen hacia los lados',
                ayuda: 'Cuánto puede desviarse y que igual cuente. Más alto = más fácil.',
                valor: _p.margenLateral,
                rango: rangoMargenLateral,
                texto: '± ${_p.margenLateral.round()} u ${_grados(_p.margenLateral)}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(margenLateral: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Margen adelante/atrás (poses de lado)',
                ayuda: 'Amplio a propósito: al inclinarse de lado uno se encorva un poco.',
                valor: _p.margenAdelante,
                rango: rangoMargenAdelante,
                texto: '± ${_p.margenAdelante.round()} u ${_grados(_p.margenAdelante)}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(margenAdelante: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Margen adelante/atrás (pose del centro)',
                ayuda: 'En "bien derecho" sí importa no encorvarse.',
                valor: _p.margenAdelanteCentro,
                rango: rangoMargenAdelanteCentro,
                texto: '± ${_p.margenAdelanteCentro.round()} u ${_grados(_p.margenAdelanteCentro)}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(margenAdelanteCentro: v), guardar: g),
              ),

              _seccion('Tiempos'),
              _deslizador(
                titulo: 'Segundos para mantener cada pose',
                valor: _p.segundosMantener,
                rango: rangoSegundosMantener,
                texto: '${_p.segundosMantener.round()} s',
                alCambiar: (v, g) => _cambiar(_p.copyWith(segundosMantener: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Segundos sin avanzar hasta la pista',
                valor: _p.segundosPista,
                rango: rangoSegundosPista,
                texto: '${_p.segundosPista.round()} s',
                alCambiar: (v, g) => _cambiar(_p.copyWith(segundosPista: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Segundos hasta que Quique ofrece ayuda',
                valor: _p.segundosAyuda,
                rango: rangoSegundosAyuda,
                texto: '${_p.segundosAyuda.round()} s',
                alCambiar: (v, g) => _cambiar(_p.copyWith(segundosAyuda: v), guardar: g),
              ),

              _seccion('Figura'),
              _interruptor(
                titulo: 'Modo espejo',
                ayuda: _p.espejo
                    ? 'Sí: si se inclina a SU izquierda, la figura va a la izquierda de la pantalla.'
                    : 'No: la figura se mueve al revés que un espejo.',
                valor: _p.espejo,
                alCambiar: (v) => _cambiar(_p.copyWith(espejo: v), guardar: true),
              ),
              _deslizador(
                titulo: 'Exageración de la inclinación en pantalla',
                ayuda: '×1,0 = ángulo real. No cambia lo que cuenta, solo cuánto se nota.',
                valor: _p.amplificacion,
                rango: rangoAmplificacion,
                texto: '× ${_p.amplificacion.toStringAsFixed(1).replaceAll('.', ',')}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(amplificacion: v), guardar: g),
              ),

              _seccion('Cinturón'),
              _interruptor(
                titulo: 'El cinturón registra con la calibración',
                ayuda: _p.cinturonCalibrado
                    ? 'Sí: al elegir un participante calibrado, se le envía su postura neutral al '
                        'cinturón, que registra sus episodios desde ahí. Es lo que ve el apoderado.'
                    : 'No: el cinturón registra siempre con el umbral fijo. Es lo que ve el apoderado.',
                valor: _p.cinturonCalibrado,
                alCambiar: (v) => _cambiar(_p.copyWith(cinturonCalibrado: v), guardar: true),
              ),

              _seccion('Análisis de recorridos'),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  'Solo cambian cómo se LEEN los recorridos en Datos de prueba: juegos y en la '
                  'exportación. No cambian el juego, y se aplican también a los juegos ya jugados.',
                  style: Textos.secundario,
                ),
              ),
              _deslizador(
                titulo: 'Cuánto moverse para que cuente',
                ayuda: '"Primer movimiento": la primera vez que se aleja de donde partió más que '
                    'esto (¿hacia la pose o al revés?). También: cuánto tiene que acercarse '
                    'después de una pista para decir que la pista sirvió.',
                valor: _p.umbralMovimiento,
                rango: rangoUmbralMovimiento,
                texto: '${_p.umbralMovimiento.round()} u ${_grados(_p.umbralMovimiento)}',
                alCambiar: (v, g) => _cambiar(_p.copyWith(umbralMovimiento: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Qué es "llegó cerca"',
                ayuda: '"Llegó cerca sin entrar": nunca entró a la zona, pero estuvo a menos de '
                    'este múltiplo del margen de la pose (×1,5 con margen 9 = a menos de 13,5 u).',
                valor: _p.factorCercaAnalisis,
                rango: rangoFactorCercaAnalisis,
                texto: '× ${_p.factorCercaAnalisis.toStringAsFixed(1).replaceAll('.', ',')} el margen',
                alCambiar: (v, g) => _cambiar(_p.copyWith(factorCercaAnalisis: v), guardar: g),
              ),
              _deslizador(
                titulo: 'Segundos para ver si la pista sirvió',
                ayuda: 'Después de que aparece la pista, cuántos segundos se miran para ver si '
                    'se acercó a la pose.',
                valor: _p.segundosVentanaPista,
                rango: rangoSegundosVentanaPista,
                texto: '${_p.segundosVentanaPista.round()} s',
                alCambiar: (v, g) => _cambiar(_p.copyWith(segundosVentanaPista: v), guardar: g),
              ),

              _seccion('Investigador'),
              _interruptor(
                titulo: 'Números de prueba sobre la figura',
                ayuda: 'Apágalo antes de jugar con los niños.',
                valor: _p.mostrarNumeros,
                alCambiar: (v) => _cambiar(_p.copyWith(mostrarNumeros: v), guardar: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estado() {
    final defecto = _p.esPorDefecto;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: defecto ? Colores.tarjeta : Colores.ambar.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: defecto ? Colores.linea : Colores.ambar),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(defecto ? Icons.check_circle_rounded : Icons.tune_rounded,
              color: defecto ? Colores.comodo : Colores.ambar),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (defecto ? 'Valores por defecto. ' : 'Variante modificada. ') +
                  'Los cambios se aplican desde el próximo juego, y cada juego '
                      'guarda con qué parámetros se jugó.',
              style: Textos.secundario,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _seccion(String texto) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(texto, style: Textos.tituloTarjeta),
      );

  /// Deslizador con su valor. `alCambiar(valor, guardar)`: guardar es
  /// true al soltarlo (para no escribir en el teléfono a cada píxel).
  Widget _deslizador({
    required String titulo,
    String? ayuda,
    required double valor,
    required _Rango rango,
    required String texto,
    required void Function(double valor, bool guardar) alCambiar,
  }) {
    final divisiones = ((rango.max - rango.min) / rango.paso).round();
    final v = valor.clamp(rango.min, rango.max).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: Textos.cuerpoDestacado)),
              Text(texto, style: Textos.cuerpoDestacado.copyWith(color: Colores.bosque)),
            ],
          ),
          if (ayuda != null) ...[
            const SizedBox(height: 2),
            Text(ayuda, style: Textos.secundario),
          ],
          Slider(
            value: v,
            min: rango.min,
            max: rango.max,
            divisions: divisiones,
            activeColor: Colores.bosque,
            onChanged: (x) => alCambiar(x, false),
            onChangeEnd: (x) => alCambiar(x, true),
          ),
        ],
      ),
    );
  }

  Widget _interruptor({
    required String titulo,
    required String ayuda,
    required bool valor,
    required ValueChanged<bool> alCambiar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colores.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(titulo, style: Textos.cuerpoDestacado),
        subtitle: Text(ayuda, style: Textos.secundario),
        value: valor,
        onChanged: alCambiar,
      ),
    );
  }
}
