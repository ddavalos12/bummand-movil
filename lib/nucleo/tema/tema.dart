import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colores.dart';

class BumandTema {
  static ThemeData get temaClaro {
    final base_theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: BumandColores.azulMarinoProfundo,
      scaffoldBackgroundColor: BumandColores.fondo,
      colorScheme: const ColorScheme.light(
        primary: BumandColores.azulMarinoProfundo,
        onPrimary: BumandColores.blanco,
        secondary: BumandColores.azulCieloSuave,
        onSecondary: BumandColores.blanco,
        tertiary: BumandColores.amarilloRadiante,
        onTertiary: BumandColores.negro,
        surface: BumandColores.blanco,
        onSurface: BumandColores.negro,
        error: Color(0xFFDC2626),
        onError: BumandColores.blanco,
      ),
    );

    // Tipografía institucional: Montserrat principal, Poppins para botones y números
    final texto_montserrat = GoogleFonts.montserratTextTheme(base_theme.textTheme).apply(
      bodyColor: BumandColores.negro,
      displayColor: BumandColores.negro,
    );

    return base_theme.copyWith(
      textTheme: texto_montserrat.copyWith(
        titleLarge: texto_montserrat.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: BumandColores.azulMarinoSecundario,
        ),
        titleMedium: texto_montserrat.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: BumandColores.negro,
        ),
        bodyLarge: texto_montserrat.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: BumandColores.negro,
        ),
        bodyMedium: texto_montserrat.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: BumandColores.textoSecundario,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BumandColores.blanco,
        foregroundColor: BumandColores.azulMarinoProfundo,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BumandColores.azulMarinoProfundo,
        ),
      ),
      cardTheme: const CardThemeData(
        color: BumandColores.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: BumandColores.grisClaro, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BumandColores.azulMarinoProfundo,
          foregroundColor: BumandColores.blanco,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BumandColores.azulMarinoProfundo,
          side: const BorderSide(color: BumandColores.azulMarinoProfundo, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BumandColores.blanco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: GoogleFonts.montserrat(
          color: BumandColores.grisMedio,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BumandColores.grisClaro, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BumandColores.grisClaro, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BumandColores.azulMarinoProfundo, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BumandColores.fondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BumandColores.grisClaro),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: BumandColores.negro,
        ),
      ),
    );
  }
}
