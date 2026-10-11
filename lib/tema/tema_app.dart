// ============================================================
// tema_app.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — tema general y estilos de texto
//
// Define cómo se ven por defecto los elementos de Flutter (fondos,
// textos, botones) usando los colores de colores.dart.
//
// TIPOGRAFÍA: por ahora se usa la fuente por defecto de Flutter, a
// propósito (agregar fuentes implica "assets", y se hará después,
// una familia a la vez). Cuando se agreguen Fraunces y Barlow/D-DIN,
// basta con completar las dos constantes de abajo.
// ============================================================

import 'package:flutter/material.dart';

import 'colores.dart';

// Dejar en null mientras no estén agregadas como assets.
const String? fuenteTitulos = null; // futuro: 'Fraunces'
const String? fuenteTexto = null; // futuro: 'Barlow' o 'D-DIN'

class TemaApp {
  TemaApp._();

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: Colores.azul,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colores.azul,
      onPrimary: Colores.tarjeta,
      secondary: Colores.bosque,
      onSecondary: Colores.tarjeta,
      surface: Colores.tarjeta,
      onSurface: Colores.azul,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Colores.fondo,
      fontFamily: fuenteTexto,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colores.azul,
        displayColor: Colores.azul,
      ),
      // Botón principal (FilledButton): verde bosque, forma de píldora,
      // alto mínimo de 52 para que un niño lo toque sin problema.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colores.bosque,
          foregroundColor: Colores.tarjeta,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// Estilos de texto reutilizables. Cambiar un tamaño aquí lo cambia en
// todas las pantallas que lo usen.
class Textos {
  Textos._();

  static const TextStyle titulo = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: Colores.azul,
  );

  static const TextStyle tituloTarjeta = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colores.azul,
  );

  static const TextStyle cuerpo = TextStyle(
    fontSize: 16,
    color: Colores.azul,
  );

  static const TextStyle cuerpoDestacado = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colores.azul,
  );

  static const TextStyle secundario = TextStyle(
    fontSize: 14,
    color: Colores.textoSecundario,
  );

  static const TextStyle dato = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: Colores.azul,
  );
}
