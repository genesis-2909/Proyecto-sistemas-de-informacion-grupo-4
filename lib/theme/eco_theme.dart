import 'package:flutter/material.dart';

class EcoTheme {
  // Colores de la paleta Premium de Figma
  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color darkForest = Color(0xFF0C2E0E);
  static const Color warmCream = Color(0xFFFCFAF2);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color ecoGold = Color(0xFFD4AF37);
  static const Color softGray = Color(0xFF9E9E9E);

  static ThemeData get luxuryTheme {
    return ThemeData(
      scaffoldBackgroundColor: warmCream,
      primaryColor: forestGreen,
      colorScheme: const ColorScheme.light(
        primary: forestGreen,
        secondary: ecoGold,
        background: warmCream,
        surface: pureWhite,
      ),
      
      // Configuración de Textos Premium
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: darkForest,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(color: darkForest, fontSize: 16),
        bodyMedium: TextStyle(color: softGray, fontSize: 14),
      ),

      // Curvas Orgánicas para Inputs (Campos de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0), // Curva orgánica suave
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide(color: forestGreen.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: forestGreen, fontWeight: FontWeight.w500),
      ),

      // Curvas Orgánicas para Botones Principales
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: pureWhite,
          minimumSize: const Size(double.infinity, 56), // Botones más altos y cómodos
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Curva máxima de lujo
          ),
          elevation: 4,
          shadowColor: forestGreen.withOpacity(0.3),
        ),
      ),
    );
  }

  // Contenedor con Jerarquía Visual (Sombra Suave Premium)
  static BoxDecoration luxuryCard() {
    return BoxDecoration(
      color: pureWhite,
      borderRadius: BorderRadius.circular(30.0), // Curvas orgánicas en tarjetas
      boxShadow: [
        BoxShadow(
          color: darkForest.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 10), // Sombra hacia abajo para dar elevación
        ),
      ],
    );
  }
}