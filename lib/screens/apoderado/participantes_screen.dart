// ============================================================
// participantes_screen.dart
// Fecha: 18-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v2 — paso F1b
//
// CAMBIOS v2 respecto a la v1:
//  - Al crear un participante se elige la EDAD EXACTA (botones de 4 a
//    14 años, ver edadMinima/edadMaxima en participante.dart) en vez
//    del grupo de edad. No hay edad por defecto: hay que elegirla, para
//    que no quede registrada una edad equivocada por descuido.
//  - La lista muestra la edad de cada participante.
//
// Herramienta del INVESTIGADOR (se abre desde Configuración):
//  - Crear un participante (código P01, P02…, nombre opcional, grupo
//    de edad). Al crearlo queda ACTIVO.
//  - Tocar un participante lo deja activo: los juegos que se jueguen
//    desde ahora quedan a su nombre.
//  - "Sin participante": para probar la app sin ensuciar los datos de
//    ningún niño.
//  - Por participante: copiar sus datos al portapapeles, o eliminarlo
//    (borra también sus juegos).
//  - Arriba a la derecha: copiar los datos de TODOS.
// ============================================================

import 'package:flutter/material.dart';

import '../../modelos/participante.dart';
import '../../servicios/almacenamiento_juegos.dart';
import '../../servicios/exportar_datos.dart';
import '../../servicios/servicio_participantes.dart';
import '../../tema/colores.dart';
import '../../tema/tema_app.dart';

class ParticipantesScreen extends StatefulWidget {
  const ParticipantesScreen({super.key});

  @override
  State<ParticipantesScreen> createState() => _ParticipantesScreenState();
}

class _ParticipantesScreenState extends State<ParticipantesScreen> {
  final _servicio = ServicioParticipantes.instancia;

  // Cuántos juegos tiene cada código (null = sin participante).
  Map<String?, int> _juegosPorCodigo = const {};

  @override
  void initState() {
    super.initState();
    _contarJuegos();
  }

  Future<void> _contarJuegos() async {
    final todos = await AlmacenamientoJuegos.cargar();
    final conteo = <String?, int>{};
    for (final r in todos) {
      conteo[r.participante] = (conteo[r.participante] ?? 0) + 1;
    }
    if (mounted) setState(() => _juegosPorCodigo = conteo);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------------- Acciones ----------------

  Future<void> _nuevo() async {
    final p = await showDialog<Participante>(
      context: context,
      builder: (_) => _DialogoNuevo(codigoSugerido: _servicio.siguienteCodigo()),
    );
    if (p == null) return;
    await _servicio.crear(p);
    _aviso('${p.codigo} creado y activo');
  }

  Future<void> _copiar(Participante p) async {
    final texto = await ExportarDatos.textoDe(p);
    await ExportarDatos.copiar(texto);
    _aviso('Datos de ${p.codigo} copiados (${_juegosPorCodigo[p.codigo] ?? 0} juegos)');
  }

  Future<void> _copiarTodos() async {
    final texto = await ExportarDatos.textoDeTodos();
    await ExportarDatos.copiar(texto);
    _aviso('Datos de todos los participantes copiados');
  }

  Future<void> _eliminar(Participante p) async {
    final n = _juegosPorCodigo[p.codigo] ?? 0;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar a ${p.codigo}?'),
        content: Text(
          'Se borrarán su perfil y sus $n juegos. Esto no se puede deshacer. '
          'Si los necesitas, copia sus datos antes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    await AlmacenamientoJuegos.borrarDe(p.codigo);
    await _servicio.eliminar(p);
    await _contarJuegos();
    _aviso('${p.codigo} eliminado');
  }

  // ---------------- Pantalla ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes'),
        actions: [
          IconButton(
            tooltip: 'Copiar datos de todos',
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: _copiarTodos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colores.bosque,
        foregroundColor: Colores.tarjeta,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nuevo participante'),
        onPressed: _nuevo,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ValueListenableBuilder<List<Participante>>(
            valueListenable: _servicio.lista,
            builder: (context, lista, _) => ValueListenableBuilder<Participante?>(
              valueListenable: _servicio.activo,
              builder: (context, activo, _) => ListView(
                // Espacio abajo para que el botón flotante no tape la lista.
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Los juegos quedan a nombre del participante activo. '
                      'Elige o crea el perfil antes de que juegue cada niño.',
                      style: Textos.secundario,
                    ),
                  ),
                  for (final p in lista) ...[
                    _fila(p, activo?.codigo == p.codigo),
                    const SizedBox(height: 10),
                  ],
                  _filaSinParticipante(activo == null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fila(Participante p, bool esActivo) {
    final n = _juegosPorCodigo[p.codigo] ?? 0;
    final nombre = p.nombre.trim().isEmpty ? '' : ' · ${p.nombre.trim()}';
    return Material(
      color: esActivo ? Colores.bosque.withValues(alpha: 0.10) : Colores.tarjeta,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: esActivo ? Colores.bosque : Colores.linea, width: esActivo ? 2 : 1),
        ),
        leading: Icon(
          esActivo ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
          color: esActivo ? Colores.bosque : Colores.neutro,
        ),
        title: Text('${p.codigo}$nombre', style: Textos.cuerpoDestacado),
        subtitle: Text(
          '${p.edadTexto} · $n ${n == 1 ? 'juego' : 'juegos'}${esActivo ? ' · activo' : ''}',
          style: Textos.secundario,
        ),
        onTap: () => _servicio.activar(p),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colores.azul),
          onSelected: (accion) {
            if (accion == 'copiar') _copiar(p);
            if (accion == 'eliminar') _eliminar(p);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copiar', child: Text('Copiar sus datos')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  Widget _filaSinParticipante(bool esActivo) {
    final n = _juegosPorCodigo[null] ?? 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: esActivo ? Colores.bosque : Colores.linea, width: esActivo ? 2 : 1),
      ),
      leading: Icon(
        esActivo ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: esActivo ? Colores.bosque : Colores.neutro,
      ),
      title: const Text('Sin participante', style: Textos.cuerpo),
      subtitle: Text('Para probar la app · $n ${n == 1 ? 'juego' : 'juegos'}', style: Textos.secundario),
      onTap: () => _servicio.activar(null),
    );
  }
}

/// Diálogo para crear un participante. Devuelve el Participante o null.
class _DialogoNuevo extends StatefulWidget {
  final String codigoSugerido;

  const _DialogoNuevo({required this.codigoSugerido});

  @override
  State<_DialogoNuevo> createState() => _DialogoNuevoState();
}

class _DialogoNuevoState extends State<_DialogoNuevo> {
  late final _codigo = TextEditingController(text: widget.codigoSugerido);
  final _nombre = TextEditingController();
  int? _edad; // sin valor por defecto: hay que elegirla
  String? _error;
  String? _errorEdad;

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    super.dispose();
  }

  void _crear() {
    final codigo = _codigo.text.trim().toUpperCase();
    if (codigo.isEmpty) {
      setState(() => _error = 'Escribe un código');
      return;
    }
    if (ServicioParticipantes.instancia.existeCodigo(codigo)) {
      setState(() => _error = 'Ese código ya existe');
      return;
    }
    if (_edad == null) {
      setState(() {
        _error = null;
        _errorEdad = 'Elige su edad';
      });
      return;
    }
    Navigator.of(context).pop(Participante(
      codigo: codigo,
      nombre: _nombre.text.trim(),
      edad: _edad,
      creado: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo participante'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _codigo,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'Código', errorText: _error),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre (opcional)',
                helperText: 'Solo para saludarlo en la app',
              ),
            ),
            const SizedBox(height: 18),
            const Text('Edad (años cumplidos)', style: Textos.secundario),
            const SizedBox(height: 8),
            // Un botón por edad: más rápido y claro que escribirla.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var e = edadMinima; e <= edadMaxima; e++)
                  ChoiceChip(
                    label: Text('$e'),
                    selected: _edad == e,
                    showCheckmark: false,
                    selectedColor: Colores.bosque,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _edad == e ? Colores.tarjeta : Colores.azul,
                    ),
                    onSelected: (_) => setState(() {
                      _edad = e;
                      _errorEdad = null;
                    }),
                  ),
              ],
            ),
            if (_errorEdad != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorEdad!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _crear, child: const Text('Crear')),
      ],
    );
  }
}
