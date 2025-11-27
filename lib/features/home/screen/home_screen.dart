import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:armariovirtual/features/garment/screen/add_garment_screen.dart';
import '../widgets/garment_grid.dart';
import 'package:armariovirtual/shared/widgets/app_drawer.dart';

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

  // Filtros activos: clave -> valor (ej: 'category_top' -> 'top', 'tag_verano' -> 'verano')
  final Map<String, String> _activeFilters = {};

  /// Normaliza el texto: minúsculas y sin tildes
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  void _addFilter(String type, String value) {
    setState(() {
      if (type == 'category') {
        _activeFilters['category_$value'] = value;
      } else {
        // Normalizamos la etiqueta al añadirla para asegurar consistencia
        final normalizedValue = _normalize(value);
        _activeFilters['tag_$normalizedValue'] = normalizedValue;
      }
    });
  }

  void _removeFilter(String key) {
    setState(() {
      _activeFilters.remove(key);
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Filtro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Por Categoría'),
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryFilterDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Por Etiqueta'),
              onTap: () {
                Navigator.pop(ctx);
                _showTagFilterDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryFilterDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Parte Superior'),
              onTap: () {
                _addFilter('category', 'top');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Parte Inferior'),
              onTap: () {
                _addFilter('category', 'bottom');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Calzado'),
              onTap: () {
                _addFilter('category', 'footwear');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTagFilterDialog() async {
    final tagController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escribe una etiqueta'),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej: casual, verano...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (tagController.text.trim().isNotEmpty) {
                _addFilter('tag', tagController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String key, String value) {
    if (key.startsWith('category')) {
      switch (value) {
        case 'top':
          return 'Superior';
        case 'bottom':
          return 'Inferior';
        case 'footwear':
          return 'Calzado';
        default:
          return value;
      }
    }
    return value; // Para etiquetas
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
          _searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.filter_list, size: 16),
                          label: const Text('Añadir Filtro'),
                          onPressed: _showFilterDialog,
                        ),
                        const SizedBox(width: 8),
                        ..._activeFilters.entries.map((entry) {
                          final isCategory = entry.key.startsWith('category');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              avatar: Icon(
                                isCategory ? Icons.category : Icons.label,
                                size: 16,
                              ),
                              label: Text(
                                _getFilterLabel(entry.key, entry.value),
                              ),
                              onDeleted: () => _removeFilter(entry.key),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
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
                    debugPrint('Error cargando prendas: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
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

                  final filteredGarments = allGarments.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Normalización para búsqueda y filtrado
                    final name = _normalize(data['name'] as String? ?? '');
                    final tags = List<String>.from(
                      data['tags'] ?? [],
                    ).map((tag) => _normalize(tag)).toList();
                    final query = _normalize(_searchQuery);

                    // 1. Filtro de búsqueda de texto
                    final matchesSearch =
                        query.isEmpty ||
                        name.contains(query) ||
                        tags.any((tag) => tag.contains(query));

                    if (!matchesSearch) return false;

                    // 2. Filtros activos
                    final selectedCategories = <String>[];
                    final selectedTags = <String>[];

                    for (var entry in _activeFilters.entries) {
                      if (entry.key.startsWith('category')) {
                        selectedCategories.add(entry.value);
                      } else if (entry.key.startsWith('tag')) {
                        // Ya están normalizadas al añadirse
                        selectedTags.add(entry.value);
                      }
                    }

                    // Chequeo de categorías (OR)
                    if (selectedCategories.isNotEmpty) {
                      if (!selectedCategories.contains(data['category'])) {
                        return false;
                      }
                    }

                    // Chequeo de etiquetas (AND)
                    for (final tag in selectedTags) {
                      if (!tags.contains(tag)) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filteredGarments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron prendas con estos filtros.',
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
