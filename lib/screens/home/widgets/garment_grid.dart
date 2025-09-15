import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:armario_virtual/screens/garment_detail/garment_detail_screen.dart';

/// Widget que muestra una lista de prendas en una cuadrícula.
///
/// Es 'Stateless' porque solo se encarga de presentar los datos que recibe,
/// sin gestionar ningún estado interno.
class GarmentGrid extends StatelessWidget {
  /// La lista de documentos de prendas que vienen de Firestore.
  final List<QueryDocumentSnapshot> garments;

  const GarmentGrid({super.key, required this.garments});

  @override
  Widget build(BuildContext context) {
    // GridView.builder es una forma eficiente de construir cuadrículas,
    // ya que solo renderiza los elementos que son visibles en pantalla.
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Muestra 2 columnas.
        crossAxisSpacing: 10, // Espacio horizontal entre tarjetas.
        mainAxisSpacing: 10, // Espacio vertical entre tarjetas.
        childAspectRatio: 0.8, // Proporción de cada tarjeta (ancho / alto).
      ),
      itemCount: garments.length,
      itemBuilder: (context, index) {
        final garmentDoc = garments[index];
        final garmentData = garmentDoc.data() as Map<String, dynamic>;

        // GestureDetector hace que la tarjeta sea pulsable.
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => GarmentDetailScreen(
                  garmentId: garmentDoc.id,
                  garmentData: garmentData,
                ),
              ),
            );
          },
          // Delega la construcción de la tarjeta al widget especializado.
          child: _GarmentCard(garmentData: garmentData),
        );
      },
    );
  }
}

/// Un widget privado que representa una única tarjeta de prenda.
///
/// Se mantiene en este archivo porque su diseño es específico para [GarmentGrid].
class _GarmentCard extends StatelessWidget {
  final Map<String, dynamic> garmentData;

  const _GarmentCard({required this.garmentData});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior:
          Clip.antiAlias, // Recorta la imagen a los bordes redondeados.
      // La forma y elevación se heredan del `cardTheme` en `app_theme.dart`.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expanded asegura que la imagen ocupe todo el espacio vertical disponible.
          Expanded(
            child: CachedNetworkImage(
              imageUrl: garmentData['imageUrl'],
              fit: BoxFit
                  .cover, // Llena el espacio disponible, recortando si es necesario.
              alignment: Alignment.center,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const Padding(padding: EdgeInsets.all(2.0)),
          const Divider(height: 1, thickness: 1, indent: 8, endIndent: 8),
          // El nombre de la prenda en la parte inferior de la tarjeta.
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              garmentData['name'],
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
