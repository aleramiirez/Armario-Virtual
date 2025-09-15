import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Definimos todos los colores base aquí
  static const Color colorPrimario = Color(0xFFA084E8);
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
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      labelStyle: TextStyle(
        color: colorTextoPrincipal,
        fontWeight: FontWeight.w500,
      ),
      deleteIconColor: colorTextoSecundario,
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
        borderSide: BorderSide.none,
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
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: colorPrimario,
      foregroundColor: Colors.white,
    ),
  );
}
