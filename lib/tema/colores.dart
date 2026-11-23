// ============================================================
// colores.dart
// Fecha: 11-10-2026
// Proyecto: "La espalda no espera" — app Kineo Sóma
// Versión: v2 — paso G5 (paleta ajustada)
//
// CAMBIOS v2 respecto a la v1:
//  - Se aplica la PALETA AJUSTADA (lamina_paleta_ajustada_v2), en tres
//    capas: identidad (del quique), escenario (de su hábitat) y estados
//    de Sóma (de la función). Se agregan tres colores de paisaje, Cielo,
//    Agua y Ocre, solo para las ilustraciones de la historia.
//  - Los NOMBRES que ya usaba el código se mantienen (azul, fondo,
//    tarjeta…) para no tocar todas las pantallas; cada uno apunta ahora
//    al color de la paleta que le corresponde (ver la tabla de abajo).
//    En código nuevo, preferir los nombres de la paleta.
//
// Todos los colores de la app viven aquí. Si un color cambia, se cambia
// SOLO en este archivo y se actualiza en todas las pantallas.
// ============================================================

import 'package:flutter/material.dart';

class Colores {
  Colores._(); // no se instancia: solo agrupa constantes

  // ================= PALETA AJUSTADA =================
  // ---------- Capa 1 · Identidad (del quique) ----------
  static const Color azulNoche = Color(0xFF243851); // texto principal, fondos de portada (10,1:1)
  static const Color grisPizarra = Color(0xFF55524C); // texto secundario; estado "incómodo" (6,6:1)
  static const Color grisLomo = Color(0xFF9C988F); // líneas, ejes, divisores — NUNCA texto (2,4:1)
  static const Color cremaBanda = Color(0xFFFBF7EE); // tarjetas y superficies elevadas

  // ---------- Capa 2 · Escenario (de su hábitat) ----------
  static const Color tierraSeca = Color(0xFFF2EBDD); // fondo de páginas y pantallas
  static const Color arenaPaleta = Color(0xFFD6CCBC); // bloques y zonas secundarias (no texto)
  static const Color bosque = Color(0xFF4A5224); // acento de marca y botones principales (7,0:1)
  static const Color matorral = Color(0xFFA7B05C); // relleno claro en gráficos (eje aprendizaje)
  static const Color tierra = Color(0xFFA65F3B); // relleno medio en gráficos (eje salud)
  // Paisaje (solo ilustraciones de la historia, nunca interfaz):
  static const Color cielo = Color(0xFFD3E6EF);
  static const Color agua = Color(0xFF5E93BD);
  static const Color ocre = Color(0xFFC9A46B); // desierto de Atacama

  // ---------- Capa 3 · Estados de Sóma (de la función) ----------
  // Siempre van con la pose de Sóma y una palabra: el color nunca
  // comunica solo. NUNCA rojo para la postura.
  static const Color comodo = Color(0xFF6F8A3A); // Sóma está cómodo
  static const Color pocoIncomodo = Color(0xFFE3A73B); // Sóma sugiere un ajuste
  static const Color incomodo = grisPizarra; // Sóma se apaga, pide ayuda
  static const Color error = Color(0xFFB3261E); // SOLO fallas del polerón o la conexión

  // ================= NOMBRES QUE USA EL CÓDIGO =================
  // (cada uno apunta a un color de la paleta)
  static const Color azul = azulNoche;
  static const Color fondo = tierraSeca;
  static const Color tarjeta = cremaBanda;
  static const Color textoSecundario = grisPizarra;
  static const Color linea = arenaPaleta; // bordes suaves de tarjetas
  static const Color neutro = grisLomo; // íconos y líneas (no texto pequeño)
  static const Color base = arenaPaleta;
  static const Color ambar = pocoIncomodo;
  static const Color calido = error; // reservado: fallas del sistema
  static const Color colina = matorral;
  static const Color bosqueClaro = comodo;
  static const Color rio = agua;
  static const Color rioClaro = cielo;
  // El mundo niño usa el mismo fondo que el apoderado.
  static const Color arena = tierraSeca;
  // Marcador provisorio de Sóma (cuando falta su imagen): sus colores.
  static const Color quique = grisPizarra;
  static const Color quiqueClaro = cremaBanda;
  // Silueta de la pose objetivo, sobre las tarjetas crema.
  static const Color silueta = arenaPaleta;

  // Categorías del monitoreo (adelante / al lado / ambos): tres niveles
  // de luminosidad distintos (se diferencian incluso con daltonismo).
  // Siempre acompañarlos con texto o ícono.
  static const Color categoriaAdelante = azulNoche;
  static const Color categoriaLateral = tierra;
  static const Color categoriaAmbos = matorral;
}
