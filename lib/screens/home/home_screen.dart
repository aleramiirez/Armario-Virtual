import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:armario_virtual/screens/add_garment/add_garment_screen.dart';
import 'widgets/garment_grid.dart';

/// Pantalla principal de la aplicación.
///
/// Muestra el armario del usuario y gestiona el estado de los datos
/// (cargando, vacío, error o con datos) a través de un [StreamBuilder]
/// que escucha en tiempo real la colección de prendas en Firestore.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Obtiene el usuario actualmente autenticado para construir la consulta de Firestore.
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Armario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // StreamBuilder se reconstruye automáticamente cada vez que hay un cambio 
      // en la colección 'garments' de Firestore.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('garments')
            .orderBy('createdAt', descending: true) // Muestra las prendas más nuevas primero.
            .snapshots(),
        builder: (context, snapshot) {
          // Muestra un indicador de carga mientras se obtienen los datos.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Muestra un mensaje si ocurre un error.
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ocurrió un error al cargar las prendas.'),
            );
          }
          // Muestra un mensaje si el armario está vacío.
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Tu armario está vacío. ¡Añade tu primera prenda!'),
            );
          }

          // Si hay datos, delega la construcción de la 
          // cuadrícula al widget [GarmentGrid].
          return GarmentGrid(garments: snapshot.data!.docs);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddGarmentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
