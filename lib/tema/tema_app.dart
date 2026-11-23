// ============================================================
// tema_app.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v2b — paso G5b (corrección)
//
// CAMBIOS v2b respecto a la v2:
//  - Se recuperan los estilos `subtitulo` y `nota`, que usan el
//    historial, el registro de juegos y la pantalla de postura (la v2
//    los había dejado fuera y la app no compilaba).
//
// (Cambios de la v2, para referencia: Lexend + Fraunces, AppBar en
//  Fraunces, estilos tituloPantalla, fraseSoma, etiqueta, pequeno.)
//
// CAMBIOS v2 respecto a la v1:
//  - TIPOGRAFÍAS de la memoria (7.4), ambas con licencia libre (OFL):
//      · LEXEND para el texto continuo (toda la app por defecto);
//      · FRAUNCES para titulares y textos particulares (`fuenteTitulos`).
//    Van como archivos dentro de la app (assets/fonts), así funcionan
//    sin internet. Se declaran en pubspec.yaml (ver el paso G5).
//  - La barra superior (AppBar) usa el fondo de la app y su título va
//    en Fraunces.
//  - Nuevos estilos de texto con nombre en `Textos` (tituloPantalla,
//    fraseSoma, etiqueta, pequeno). Cambiar un tamaño aquí lo cambia en
//    todas las pantallas que lo usen.
//
// Define cómo se ven por defecto los elementos de Flutter (fondos,
// textos, botones) usando los colores de colores.dart.
// ============================================================

import 'package:flutter/material.dart';

import 'colores.dart';

// Nombres de las familias tal como se declaran en pubspec.yaml.
const String fuenteTitulos = 'Fraunces';
const String fuenteTexto = 'Lexend';

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
      error: Colores.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Colores.fondo,
      fontFamily: fuenteTexto,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fuenteTexto,
        bodyColor: Colores.azul,
        displayColor: Colores.azul,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colores.fondo,
        foregroundColor: Colores.azul,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fuenteTitulos,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: Colores.azul,
        ),
      ),
      // Botón principal (FilledButton): verde bosque, forma de píldora,
      // alto mínimo de 52 para que un niño lo toque sin problema.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colores.bosque,
          foregroundColor: Colores.tarjeta,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: fuenteTexto, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------- ESTILOS DE TEXTO ("estilos de párrafo") ----------
// Cambiar un tamaño aquí lo cambia en todas las pantallas que lo usen.
// Fraunces = titulares; Lexend (por defecto) = todo lo demás.
class Textos {
  Textos._();

  // Fraunces
  static const TextStyle titulo = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: Colores.azul,
  );

  static const TextStyle tituloPantalla = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: Colores.azul,
  );

  static const TextStyle tituloTarjeta = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Colores.azul,
  );

  /// Subtítulos dentro de una pantalla (Fraunces, más chico que el título).
  static const TextStyle subtitulo = TextStyle(
    fontFamily: fuenteTitulos,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: Colores.azul,
  );

  // Lexend
  static const TextStyle cuerpo = TextStyle(
    fontSize: 15,
    height: 1.35,
    color: Colores.azul,
  );

  static const TextStyle cuerpoDestacado = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Colores.azul,
  );

  /// Lo que dice Sóma (globos y viñetas).
  static const TextStyle fraseSoma = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Colores.azul,
  );

  static const TextStyle secundario = TextStyle(
    fontSize: 13.5,
    height: 1.3,
    color: Colores.textoSecundario,
  );

  /// Rótulos cortos sobre datos o en mayúsculas ("CAPÍTULO 1").
  static const TextStyle etiqueta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: Colores.textoSecundario,
  );

  /// Notas y aclaraciones al pie (Lexend, chico, gris pizarra).
  static const TextStyle nota = TextStyle(
    fontSize: 12,
    height: 1.3,
    color: Colores.textoSecundario,
  );

  static const TextStyle pequeno = TextStyle(
    fontSize: 11.5,
    height: 1.3,
    color: Colores.textoSecundario,
  );

  static const TextStyle dato = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: Colores.azul,
  );
}
