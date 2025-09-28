// lib/features/outfits/screen/outfits_screen.dart

import 'package:armariovirtual/features/outfits/screen/create_outfit_screen.dart';
import 'package:armariovirtual/features/outfits/widgets/outfit_card.dart';
import 'package:armariovirtual/shared/widgets/app_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});

  /// Función para cargar los datos de una prenda a partir de su ID.
  Future<DocumentSnapshot> _getGarmentData(String garmentId) {
    final user = FirebaseAuth.instance.currentUser!;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(garmentId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos la colección de outfits del usuario
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('outfits')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los outfits.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes outfits guardados.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final outfits = snapshot.data!.docs;

          // Usamos un GridView para mostrar las tarjetas de outfit
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio:
                  0.7, // Ajustamos el aspect ratio para 3 imágenes
            ),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfitData = outfits[index].data() as Map<String, dynamic>;

              // Usamos un FutureBuilder para cargar los datos de las 3 prendas
              return FutureBuilder(
                // Future.wait nos permite ejecutar las 3 cargas en paralelo
                future: Future.wait([
                  _getGarmentData(outfitData['topGarmentId']),
                  _getGarmentData(outfitData['bottomGarmentId']),
                  _getGarmentData(outfitData['shoesGarmentId']),
                ]),
                builder:
                    (
                      context,
                      AsyncSnapshot<List<DocumentSnapshot>> garmentSnapshots,
                    ) {
                      if (garmentSnapshots.connectionState ==
                          ConnectionState.waiting) {
                        return const Card(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (garmentSnapshots.hasError ||
                          !garmentSnapshots.hasData ||
                          garmentSnapshots.data!.length < 3) {
                        return const Card(
                          child: Center(child: Icon(Icons.error)),
                        );
                      }

                      // Extraemos los datos de cada prenda
                      final topData =
                          garmentSnapshots.data![0].data()
                              as Map<String, dynamic>;
                      final bottomData =
                          garmentSnapshots.data![1].data()
                              as Map<String, dynamic>;
                      final shoesData =
                          garmentSnapshots.data![2].data()
                              as Map<String, dynamic>;

                      return OutfitCard(
                        topData: topData,
                        bottomData: bottomData,
                        shoesData: shoesData,
                      );
                    },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const CreateOutfitScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
