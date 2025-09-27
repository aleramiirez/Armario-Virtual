import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:armariovirtual/screens/add_garment/add_garment_screen.dart';
import 'widgets/garment_grid.dart';
import 'package:armariovirtual/config/app_theme.dart';
import 'package:armariovirtual/screens/outfits/outfits_screen.dart';
import 'package:armariovirtual/widgets/app_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
      drawer: const AppDrawer(),
      body: GestureDetector(
        onTap: () {
          // Oculta el teclado al tocar fuera del buscador
          _searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            Padding(
              // He restaurado el padding que te gustaba para que sea menos ancho
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false, // <-- LA SOLUCIÓN PRINCIPAL ESTÁ AQUÍ
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o etiqueta...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            // También quitamos el foco al limpiar
                            _searchFocusNode.unfocus();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 12.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('garments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Ocurrió un error al cargar las prendas.'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tu armario está vacío. ¡Añade tu primera prenda!',
                      ),
                    );
                  }

                  final allGarments = snapshot.data!.docs;

                  final filteredGarments = _searchQuery.isEmpty
                      ? allGarments
                      : allGarments.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] as String? ?? '')
                              .toLowerCase();
                          final tags = List<String>.from(
                            data['tags'] ?? [],
                          ).map((tag) => tag.toLowerCase()).toList();
                          final query = _searchQuery.toLowerCase();

                          return name.contains(query) ||
                              tags.any((tag) => tag.contains(query));
                        }).toList();

                  if (filteredGarments.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron prendas para "$_searchQuery"',
                      ),
                    );
                  }

                  return GarmentGrid(garments: filteredGarments);
                },
              ),
            ),
          ],
        ),
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
