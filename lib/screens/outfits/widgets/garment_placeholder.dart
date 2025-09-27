import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:armariovirtual/config/app_theme.dart';

class GarmentPlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  // Hacemos los iconos opcionales
  final IconData? icon;
  final String? imagePath;
  final double iconSize;

  const GarmentPlaceholder({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.iconSize = 70,
  }) : assert(
         icon != null || imagePath != null,
         'Debes proporcionar un icon o un imagePath',
       );

  @override
  Widget build(BuildContext context) {
    // Decide qué widget mostrar: una imagen o un icono
    Widget displayWidget;
    if (imagePath != null) {
      displayWidget = Image.asset(
        imagePath!,
        height: iconSize,
        // Damos un color gris al icono para que coincida con el estilo
        color: AppTheme.colorPrimario,
      );
    } else {
      displayWidget = Icon(icon!, size: iconSize, color: Colors.grey.shade500);
    }

    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              displayWidget, // <-- Usamos el widget que decidimos antes
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
