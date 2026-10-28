import 'package:flutter/material.dart';

class BumandColores {
  // 1. Primarios Institucionales (Manual Diaconía FRIF-IFD Pág. 24-27)
  static const Color azulMarinoProfundo = Color(0xFF007BBE);
  static const Color azulCieloSuave = Color(0xFF00ABBD);
  static const Color amarilloRadiante = Color(0xFFFFB600);

  // 2. Secundarios Institucionales (Manual Diaconía FRIF-IFD Pág. 29-33)
  static const Color azulMarinoSecundario = Color(0xFF035683);
  static const Color azulPetroleo = Color(0xFF00808E);

  // 3. Escala Monocromática y Neutros (Manual Diaconía FRIF-IFD Pág. 35-39)
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color negro = Color(0xFF1A1A1A);
  static const Color grisMedio = Color(0xFF808080);
  static const Color grisClaro = Color(0xFFE5E7EB);
  static const Color fondo = Color(0xFFF8FAFC);

  // Tokens descriptivos institucionales
  static const Color textoPrincipal = negro;
  static const Color textoSecundario = grisMedio;
  static const Color bordeNeutro = grisClaro;
  static const Color blancoPuro = blanco;
  static const Color fondoPantalla = fondo;

  // Compatibilidad camelCase retrocompatible
  static const Color azulDiaconia = azulMarinoProfundo;
  static const Color turquesaDiaconia = azulCieloSuave;
  static const Color naranja = amarilloRadiante;
  static const Color naranjaOscuro = amarilloRadiante;

  // Compatibilidad UPPER_SNAKE_CASE retrocompatible
  static const Color AZUL_DIACONIA = azulMarinoProfundo;
  static const Color TURQUESA_DIACONIA = azulCieloSuave;
  static const Color AZUL_MARINO_PROFUNDO = azulMarinoProfundo;
  static const Color AZUL_CIELO_SUAVE = azulCieloSuave;
  static const Color AMARILLO_RADIANTE = amarilloRadiante;
  static const Color AZUL_MARINO_SECUNDARIO = azulMarinoSecundario;
  static const Color AZUL_PETROLEO = azulPetroleo;
  static const Color NARANJA = amarilloRadiante;
  static const Color NARANJA_OSCURO = amarilloRadiante;
  static const Color NEGRO = negro;
  static const Color FONDO = fondo;
  static const Color BLANCO = blanco;
}
