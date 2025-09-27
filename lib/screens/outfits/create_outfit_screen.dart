import 'package:armariovirtual/screens/outfits/widgets/garment_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Outfit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () {
              // Lógica para guardar el outfit (se implementará en el futuro)
            },
            tooltip: 'Guardar Outfit',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GarmentPlaceholder(
                label: 'Parte Superior',
                imagePath: 'assets/icons/polo.png',
                onTap: () {
                  // Lógica para seleccionar prenda superior (Fase 2)
                  print('Seleccionar parte superior');
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GarmentPlaceholder(
                label: 'Parte Inferior',
                imagePath: 'assets/icons/vaqueros.png',
                onTap: () {
                  // Lógica para seleccionar prenda inferior (Fase 2)
                  print('Seleccionar parte inferior');
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GarmentPlaceholder(
                label: 'Calzado',
                imagePath: 'assets/icons/zapatos.png',
                onTap: () {
                  // Lógica para seleccionar calzado (Fase 2)
                  print('Seleccionar calzado');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
