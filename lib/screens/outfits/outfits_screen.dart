import 'package:armariovirtual/screens/outfits/create_outfit_screen.dart';
import 'package:armariovirtual/widgets/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const Center(
        // Aquí mostraremos la lista de outfits guardados en el futuro
        child: Text(
          'Aún no tienes outfits guardados.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      // --- BOTÓN FLOTANTE AÑADIDO ---
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
