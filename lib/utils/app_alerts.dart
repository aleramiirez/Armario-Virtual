import 'package:flutter/material.dart';
import 'package:armariovirtual/config/app_theme.dart';

/// Una clase de utilidad para mostrar alertas y SnackBars estandarizados en la app.
class AppAlerts {
  /// Muestra un SnackBar flotante y redondeado.
  ///
  /// [context] es el BuildContext de la pantalla.
  /// [message] es el texto que se mostrará.
  /// Si [isError] es true, se mostrará con el color de error.
  static void showFloatingSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Cambia el color dependiendo de si es un error o un mensaje de éxito
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : AppTheme.colorExito,
        // Este es el estilo que querías, ahora centralizado
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  // Aquí podrías añadir otros tipos de alertas en el futuro, como diálogos, etc.
}
