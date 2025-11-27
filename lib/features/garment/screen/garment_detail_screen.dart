// lib/features/garment/screen/garment_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:armariovirtual/features/garment/services/garment_service.dart';
import 'package:armariovirtual/shared/utils/color_namer.dart';
import 'package:armariovirtual/shared/utils/app_alerts.dart';
import 'package:translator/translator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Imports para la selección de imagen (ya no se necesita image_cropper)
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// --- WIDGET PRINCIPAL (GESTOR DE ESTADO GENERAL) ---
class GarmentDetailScreen extends StatefulWidget {
  final String garmentId;
  final Map<String, dynamic> garmentData;

  const GarmentDetailScreen({
    super.key,
    required this.garmentId,
    required this.garmentData,
  });

  @override
  State<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends State<GarmentDetailScreen> {
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String _loadingMessage = '';

  final GarmentService _garmentService = GarmentService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.garmentData['name']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE EDICIÓN DE IMAGEN (SIMPLIFICADA) ---

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Imagen'),
        content: const Text('Elige una nueva imagen para la prenda.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImageFromGallery();
            },
            child: const Text('Desde Galería'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImageFromUrl();
            },
            child: const Text('Desde URL'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null) return;
    // Llamamos directamente a actualizar, sin recortar
    await _updateImage(File(pickedImage.path));
  }

  Future<void> _pickImageFromUrl() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pegar URL de la imagen'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(urlController.text),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (url == null || url.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Descargando imagen...';
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/${DateTime.now().toIso8601String()}.jpg';
        final file = File(tempPath);
        await file.writeAsBytes(response.bodyBytes);
        // Llamamos directamente a actualizar, sin recortar
        await _updateImage(file);
      } else {
        throw Exception(
          'No se pudo descargar la imagen. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al obtener la imagen',
          isError: true,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateImage(File newImageFile) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Actualizando imagen...';
    });
    try {
      final newImageUrl = await _garmentService.updateGarmentImage(
        garmentId: widget.garmentId,
        oldImageUrl: widget.garmentData['imageUrl'],
        newImageFile: newImageFile,
      );

      if (mounted) {
        setState(() {
          widget.garmentData['imageUrl'] = newImageUrl;
        });
        AppAlerts.showFloatingSnackBar(context, 'Imagen actualizada');
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al actualizar',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  Future<void> _deleteGarment() async {
    final wantsToDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta prenda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (wantsToDelete == null || !wantsToDelete) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseStorage.instance
          .refFromURL(widget.garmentData['imageUrl'])
          .delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('garments')
          .doc(widget.garmentId)
          .delete();

      if (mounted) {
        Navigator.of(context).pop();
        AppAlerts.showFloatingSnackBar(context, 'Prenda eliminada con éxito');
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al eliminar la prenda',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNameChange(String newName) async {
    if (newName.trim().isEmpty ||
        newName.trim() == widget.garmentData['name']) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('garments')
          .doc(widget.garmentId)
          .update({'name': newName.trim()});
      setState(() {
        widget.garmentData['name'] = newName.trim();
        _nameController.text = newName.trim();
      });
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al guardar el nombre',
          isError: true,
        );
      }
    }
  }

  Future<void> _findSimilarItems() async {
    setState(() => _isLoading = true);
    try {
      final manualTags = List<String>.from(widget.garmentData['tags'] ?? []);
      final aiLabels = List<String>.from(widget.garmentData['aiLabels'] ?? []);
      final allTags = {...manualTags, ...aiLabels}.toList();

      if (allTags.isEmpty) {
        AppAlerts.showFloatingSnackBar(context, 'No hay etiquetas para buscar');
        setState(() => _isLoading = false);
        return;
      }

      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('find_similar_products');
      final results = await callable.call({'tags': allTags});

      final data = results.data as Map;
      final products = (data['products'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => _SearchResultsSheet(products: products),
        );
      }
    } catch (e) {
      debugPrint('Error finding similar items: $e');
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Ha ocurrido un error inesperado: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nameController.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Buscar prendas similares',
            onPressed: _isLoading ? null : _findSimilarItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isLoading ? null : _deleteGarment,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              ),
            )
          : _GarmentDetailView(
              garmentId: widget.garmentId,
              garmentData: widget.garmentData,
              onNameSaved: _saveNameChange,
              onImageTap: _showImageSourceDialog,
            ),
    );
  }
}

// --- WIDGET DE LA VISTA (SOLO MUESTRA LA UI) ---
class _GarmentDetailView extends StatelessWidget {
  final String garmentId;
  final Map<String, dynamic> garmentData;
  final Function(String newName) onNameSaved;
  final VoidCallback onImageTap;

  const _GarmentDetailView({
    required this.garmentId,
    required this.garmentData,
    required this.onNameSaved,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: garmentData['imageUrl'],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const AspectRatio(
                      aspectRatio: 1.0,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const AspectRatio(
                      aspectRatio: 1.0,
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton.small(
                    onPressed: onImageTap,
                    tooltip: 'Cambiar imagen',
                    child: const Icon(Icons.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _GarmentNameDisplay(
              initialName: garmentData['name'],
              onNameSaved: onNameSaved,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _LiveGarmentTagsEditor(
              garmentId: garmentId,
              initialTags: List<String>.from(garmentData['tags'] ?? []),
              garmentData: garmentData,
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET EDITOR DE ETIQUETAS "EN VIVO" ---
class _LiveGarmentTagsEditor extends StatefulWidget {
  final String garmentId;
  final List<String> initialTags;
  final Map<String, dynamic> garmentData;

  const _LiveGarmentTagsEditor({
    required this.garmentId,
    required this.initialTags,
    required this.garmentData,
  });

  @override
  State<_LiveGarmentTagsEditor> createState() => _LiveGarmentTagsEditorState();
}

class _LiveGarmentTagsEditorState extends State<_LiveGarmentTagsEditor> {
  late List<String> _tags;
  bool _isLoadingAi = false;
  final _tagController = TextEditingController();

  final Map<String, String> _customTranslations = {
    'camisa activa': 'camisa deportiva',
    'pantalones cortos activos': 'pantalones cortos deportivos',
    'chaqueta de sport': 'chaqueta de deporte',
  };

  @override
  void initState() {
    super.initState();
    _tags = widget.initialTags;
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _addTag(String tag) async {
    final newTag = tag.trim().toLowerCase();
    final existingTagsLower = _tags.map((t) => t.toLowerCase()).toList();

    if (newTag.isEmpty || existingTagsLower.contains(newTag)) {
      _tagController.clear();
      return;
    }

    setState(() {
      _tags.add(newTag);
    });
    _tagController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final garmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(widget.garmentId);
    await garmentRef.update({
      'tags': FieldValue.arrayUnion([newTag]),
    });
  }

  Future<void> _deleteTag(String tag) async {
    setState(() {
      _tags.remove(tag);
    });

    final user = FirebaseAuth.instance.currentUser!;
    final garmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(widget.garmentId);
    await garmentRef.update({
      'tags': FieldValue.arrayRemove([tag]),
    });
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Etiqueta'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej: Casual, Verano...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              _addTag(_tagController.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAiTags() async {
    setState(() => _isLoadingAi = true);
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('get_ai_tags_for_garment');
      final results = await callable.call<Map<String, dynamic>>({
        'garmentId': widget.garmentId,
      });

      final translator = GoogleTranslator();
      final aiLabels = List<String>.from(results.data['aiLabels'] ?? []);
      final aiColors = List<String>.from(results.data['aiColors'] ?? []);

      List<String> processedAiTags = [];
      for (final label in aiLabels) {
        final translation = await translator.translate(
          label,
          from: 'en',
          to: 'es',
        );
        String translatedText = translation.text.toLowerCase();
        if (_customTranslations.containsKey(translatedText)) {
          translatedText = _customTranslations[translatedText]!;
        }
        processedAiTags.add(translatedText);
      }
      processedAiTags.addAll(
        aiColors.map(
          (colorHex) => ColorNamer.getClosestColorName(colorHex).toLowerCase(),
        ),
      );

      final existingTagsLower = _tags.map((t) => t.toLowerCase()).toSet();
      final uniqueNewTags = processedAiTags
          .where((tag) => !existingTagsLower.contains(tag))
          .toList();

      if (uniqueNewTags.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser!;
        final garmentRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('garments')
            .doc(widget.garmentId);
        await garmentRef.update({'tags': FieldValue.arrayUnion(uniqueNewTags)});
        setState(() => _tags.addAll(uniqueNewTags));
      }
    } catch (e) {
      if (mounted)
        AppAlerts.showFloatingSnackBar(
          context,
          'Ha ocurrido un error inesperado',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Etiquetas', style: Theme.of(context).textTheme.titleMedium),
            if (_isLoadingAi)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Generar etiquetas con IA',
                onPressed: _fetchAiTags,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._tags.map(
              (tag) => Chip(label: Text(tag), onDeleted: () => _deleteTag(tag)),
            ),
            InkWell(
              onTap: _showAddTagDialog,
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                radius: 18,
                child: Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- WIDGET DEL NOMBRE (CON ESTADO Y EDICIÓN AL PULSAR) ---
class _GarmentNameDisplay extends StatefulWidget {
  final String initialName;
  final Function(String newName) onNameSaved;

  const _GarmentNameDisplay({
    required this.initialName,
    required this.onNameSaved,
  });

  @override
  State<_GarmentNameDisplay> createState() => _GarmentNameDisplayState();
}

class _GarmentNameDisplayState extends State<_GarmentNameDisplay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (mounted) {
      widget.onNameSaved(_controller.text.trim());
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre de la prenda'),
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
        onFieldSubmitted: (_) => _save(),
      );
    } else {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _isEditing = true);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _focusNode.requestFocus(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _controller.text,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}

// --- WIDGET PARA MOSTRAR LOS RESULTADOS DE BÚSQUEDA ---
class _SearchResultsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const _SearchResultsSheet({required this.products});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Manejar error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No se encontraron prendas similares.')),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: product['imageUrl'] != null
                  ? Image.network(
                      product['imageUrl'],
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(product['title'] ?? 'Sin título'),
              subtitle: Text(
                product['link']?.split('/')[2] ?? 'Fuente desconocida',
              ),
              onTap: product['link'] != null
                  ? () => _launchUrl(product['link'])
                  : null,
            );
          },
        );
      },
    );
  }
}
