import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Definimos todos los colores base aquí
  static const Color colorPrimario = Color.fromARGB(255, 232, 215, 132);
  static const Color colorFondo = Color(0xFFF5F5F5);
  static const Color colorSuperficie = Color(0xFFFFFFFF);
  static const Color colorTextoPrincipal = Color(0xFF333333);
  static const Color colorTextoSecundario = Color(0xFF828282);
  static const Color colorError = Color(0xFFE57373);
  static const Color colorExito = Color(0xFF27AE60);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // 1. Esquema de Colores
    colorScheme: ColorScheme.fromSeed(
      seedColor: colorPrimario,
      background: colorFondo,
      surface: colorSuperficie,
      primary: colorPrimario,
      onPrimary: Colors.white,
      onSurface: colorTextoPrincipal,
      error: colorError,
      onError: Colors.white,
    ),

    // 2. Tipografía
    textTheme: GoogleFonts.poppinsTextTheme(),

    chipTheme: ChipThemeData(
      backgroundColor: colorPrimario.withOpacity(0.15),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: colorTextoPrincipal,
        fontWeight: FontWeight.w600, 
      ),
      deleteIconColor: colorTextoPrincipal,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // 3. Estilos de Widgets
    appBarTheme: const AppBarTheme(
      backgroundColor: colorSuperficie,
      foregroundColor: colorTextoPrincipal,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: colorTextoPrincipal,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorSuperficie,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: colorPrimario, width: 2.0),
      ),
      prefixIconColor: colorTextoPrincipal,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorPrimario),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: colorSuperficie,
      color: colorSuperficie,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: colorPrimario,
      foregroundColor: Colors.white,
    ),
  );
}
