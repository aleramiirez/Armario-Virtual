import 'dart:math';
import 'package:flutter/material.dart';

class ColorNamer {
  // Mapa con colores básicos y su valor RGB
  static const Map<String, Color> colorMap = {
    'Negro': Color.fromARGB(255, 0, 0, 0),
    'Blanco': Color.fromARGB(255, 255, 255, 255),
    'Gris': Color.fromARGB(255, 128, 128, 128),
    'Rojo': Color.fromARGB(255, 255, 0, 0),
    'Azul': Color.fromARGB(255, 0, 0, 255),
    'Verde': Color.fromARGB(255, 0, 128, 0),
    'Amarillo': Color.fromARGB(255, 255, 255, 0),
    'Rosa': Color.fromARGB(255, 255, 192, 203),
    'Morado': Color.fromARGB(255, 128, 0, 128),
    'Naranja': Color.fromARGB(255, 255, 165, 0),
    'Marrón': Color.fromARGB(255, 165, 42, 42),
    'Beige': Color.fromARGB(255, 245, 245, 220),
  };

  // Función que encuentra el nombre del color más cercano
  static String getClosestColorName(String rgbString) {
    try {
      final parts = rgbString.split('_').map(int.parse).toList();
      final color = Color.fromARGB(255, parts[0], parts[1], parts[2]);
      
      String closestColorName = '';
      double minDistance = double.infinity;

      colorMap.forEach((name, value) {
        final distance = sqrt(pow(color.red - value.red, 2) +
            pow(color.green - value.green, 2) +
            pow(color.blue - value.blue, 2));
        if (distance < minDistance) {
          minDistance = distance;
          closestColorName = name;
        }
      });
      return closestColorName;
    } catch (e) {
      return 'Color'; // Devuelve un valor por defecto si el formato es incorrecto
    }
  }
}