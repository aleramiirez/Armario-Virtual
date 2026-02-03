import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:armariovirtual/features/home/widgets/garment_grid.dart';

class GarmentSelectorSheet extends StatelessWidget {
  final String category;

  const GarmentSelectorSheet({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('garments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('Error al cargar las prendas.'),
                      );
                    }

                    final allGarments = snapshot.data!.docs;

                    final filteredGarments = allGarments.where((garmentDoc) {
                      final garmentData =
                          garmentDoc.data() as Map<String, dynamic>;

                      // 1. Check explicit category
                      if (garmentData['category'] == category) {
                        return true;
                      }

                      // 2. Fallback: Check tags if category is missing or doesn't match
                      // (Only if the garment doesn't have a category set, to avoid misclassification)
                      if (garmentData['category'] != null) {
                        return false;
                      }

                      final garmentTags = List<String>.from(
                        garmentData['tags'] ?? [],
                      );

                      // Define fallback tags for each category
                      final fallbackTags = _getFallbackTags(category);

                      return garmentTags.any(
                        (garmentTag) => fallbackTags.any(
                          (tag) => garmentTag.toLowerCase().contains(tag),
                        ),
                      );
                    }).toList();

                    if (filteredGarments.isEmpty) {
                      return const Center(
                        child: Text('No tienes prendas en esta categoría.'),
                      );
                    }

                    return GarmentGrid(
                      garments: filteredGarments,
                      onGarmentTap: (selectedGarment) {
                        Navigator.of(context).pop(selectedGarment);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getFallbackTags(String category) {
    switch (category) {
      case 'top':
        return [
          'camiseta',
          'camisa',
          'polo',
          'sudadera',
          'jersey',
          'top',
          'blusa',
          'chaqueta',
          'abrigo',
          'chaleco',
        ];
      case 'bottom':
        return ['pantalón', 'vaquero', 'falda', 'malla', 'bermuda', 'bañador'];
      case 'footwear':
        return [
          'zapato',
          'zapatilla',
          'bota',
          'sandalia',
          'tacón',
          'mocasín',
          'chancla',
        ];
      default:
        return [];
    }
  }
}
