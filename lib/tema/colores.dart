// ============================================================
// colores.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Quique
// Versión: v1 — paleta de la guía de marca + extensión del mundo niño
//
// Todos los colores de la app viven aquí. Si un color cambia en la
// guía de marca, se cambia SOLO en este archivo y se actualiza en
// todas las pantallas.
// ============================================================

import 'package:flutter/material.dart';

class Colores {
  Colores._(); // no se instancia: solo agrupa constantes

  // ---------- GUÍA DE MARCA (definida por Sebastián) ----------
  static const Color azul = Color(0xFF243851); // dominante: títulos, números, texto principal
  static const Color bosque = Color(0xFF4A5224); // acción principal (botones importantes)
  static const Color calido = Color(0xFF522824); // RESERVADO: se lee como rojo/alarma, evitar
  static const Color base = Color(0xFFD6CCBC); // beige
  static const Color neutro = Color(0xFF8192A7); // gris azulado: líneas e íconos.
  // OJO: "neutro" sobre beige tiene poco contraste (~2:1). No usarlo
  // para texto pequeño; para eso está "textoSecundario".

  // ---------- DERIVADOS (propuesta, a validar) ----------
  static const Color fondo = Color(0xFFEFEAE1); // fondo general (base aclarado)
  static const Color tarjeta = Color(0xFFFBF9F5); // tarjetas sobre el fondo
  static const Color textoSecundario = Color(0xFF56637A); // neutro oscurecido, contraste suficiente
  static const Color linea = Color(0xFFE2D9CA); // bordes suaves y divisores

  // Categorías del monitoreo (adelante / al lado / ambos):
  // tres niveles de luminosidad distintos para que se diferencien
  // incluso con daltonismo. Siempre acompañarlos con texto o ícono.
  static const Color categoriaAdelante = azul;
  static const Color categoriaLateral = neutro;
  static const Color categoriaAmbos = Color(0xFFC4B396);

  // ---------- MUNDO NIÑO (versiones más vivas de la guía) ----------
  static const Color cielo = Color(0xFFD3E6EF);
  static const Color rio = Color(0xFF5E93BD);
  static const Color rioClaro = Color(0xFF8DB7D6);
  static const Color colina = Color(0xFFA9B85E);
  static const Color bosqueClaro = Color(0xFF7D8C3C);
  static const Color arena = Color(0xFFEFE6D3);
  static const Color quique = Color(0xFF6B4A32); // café de Quique (provisorio)
  static const Color quiqueClaro = Color(0xFFD2AE85);
  static const Color ambar = Color(0xFFE3A73B);

  // ---------- COMODIDAD DE QUIQUE (estados de la postura) ----------
  // Nunca se usa rojo: Quique se siente incómodo, el niño no está "mal".
  static const Color comodo = Color(0xFF6E9A4E); // dentro de la zona
  static const Color pocoIncomodo = ambar; // cerca del límite
  static const Color incomodo = Color(0xFF9AA3AE); // fuera de la zona
  static const Color silueta = Color(0xFFC3CFDC); // silueta de la pose objetivo
}
