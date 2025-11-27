import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:armariovirtual/features/garment/screen/garment_detail_screen.dart';

class GarmentGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> garments;
  // --- PROPIEDAD NUEVA AÑADIDA ---
  // Una función opcional que se ejecutará al pulsar una prenda.
  final Function(QueryDocumentSnapshot)? onGarmentTap;

  const GarmentGrid({
    super.key,
    required this.garments,
    this.onGarmentTap, // La hacemos opcional
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: garments.length,
      itemBuilder: (context, index) {
        final garmentDoc = garments[index];
        final garmentData = garmentDoc.data() as Map<String, dynamic>;

        return GestureDetector(
          onTap: () {
            // --- LÓGICA MODIFICADA ---
            // Si nos han pasado una función personalizada, la usamos.
            if (onGarmentTap != null) {
              onGarmentTap!(garmentDoc);
            } else {
              // Si no, hacemos lo de siempre: ir a la pantalla de detalles.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => GarmentDetailScreen(
                    garmentId: garmentDoc.id,
                    garmentData: garmentData,
                  ),
                ),
              );
            }
          },
          child: _GarmentCard(garmentData: garmentData),
        );
      },
    );
  }
}

// El widget _GarmentCard no necesita cambios.
class _GarmentCard extends StatelessWidget {
  final Map<String, dynamic> garmentData;
  const _GarmentCard({required this.garmentData});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: garmentData['imageUrl'],
              imageBuilder: (context, imageProvider) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const Padding(padding: EdgeInsets.all(2.0)),
          const Divider(height: 1, thickness: 1, indent: 8, endIndent: 8),
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
