import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:armario_virtual/theme/app_theme.dart';
import 'package:armario_virtual/utils/color_namer.dart';
import 'package:translator/translator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

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

    setState(() {
      _isLoading = true;
    });

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
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Prenda eliminada con éxito'),
            backgroundColor: AppTheme.colorExito,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la prenda: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNameChange(String newName) async {
    if (newName.trim().isEmpty || newName.trim() == widget.garmentData['name'])
      return;

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
      // Manejar error si es necesario
    }
  }

  Future<void> _findSimilarItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final manualTags = List<String>.from(widget.garmentData['tags'] ?? []);
      final aiLabels = List<String>.from(widget.garmentData['aiLabels'] ?? []);
      final allTags = {...manualTags, ...aiLabels}.toList();

      if (allTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay etiquetas para buscar.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('findSimilarProducts');
      final results = await callable.call<Map<String, dynamic>>({
        'tags': allTags,
      });
      final products = List<Map<String, dynamic>>.from(
        results.data['products'] ?? [],
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => _SearchResultsSheet(products: products),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de búsqueda: ${e.message}')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ha ocurrido un error inesperado.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            onPressed: _findSimilarItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteGarment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _GarmentDetailView(
              garmentId: widget.garmentId,
              garmentData: widget.garmentData,
              onNameSaved: _saveNameChange,
            ),
    );
  }
}

// --- WIDGET DE LA VISTA (SOLO MUESTRA LA UI) ---
class _GarmentDetailView extends StatelessWidget {
  final String garmentId;
  final Map<String, dynamic> garmentData;
  final Function(String newName) onNameSaved;

  const _GarmentDetailView({
    required this.garmentId,
    required this.garmentData,
    required this.onNameSaved,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(garmentData['imageUrl']),
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
  final Map<String, dynamic>
  garmentData; // Necesario para obtener las etiquetas de IA

  const _LiveGarmentTagsEditor({
    required this.garmentId,
    required this.initialTags,
    required this.garmentData,
  });

  @override
  State<_LiveGarmentTagsEditor> createState() => _LiveGarmentTagsEditorState();
}

class _LiveGarmentTagsEditorState extends State<_LiveGarmentTagsEditor> {
  List<String> _displayTags = [];
  bool _isLoadingTags = false;
  final _tagController = TextEditingController();

  final Map<String, String> _customTranslations = {
    'camisa activa': 'camisa deportiva',
  };

  @override
  void initState() {
    super.initState();
    _processAndSetTags();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _processAndSetTags() async {
    setStateIfMounted(() => _isLoadingTags = true);
    final translator = GoogleTranslator();

    final manualTags = List<String>.from(widget.garmentData['tags'] ?? []);
    final aiLabels = List<String>.from(widget.garmentData['aiLabels'] ?? []);
    final aiColors = List<String>.from(widget.garmentData['aiColors'] ?? []);

    List<String> translatedLabels = [];
    if (aiLabels.isNotEmpty) {
      for (final label in aiLabels) {
        try {
          final translation = await translator.translate(
            label,
            from: 'en',
            to: 'es',
          );
          String translatedText = translation.text.toLowerCase();
          if (_customTranslations.containsKey(translatedText)) {
            translatedText = _customTranslations[translatedText]!;
          }
          translatedLabels.add(translatedText);
        } catch (e) {
          translatedLabels.add(label);
        }
      }
    }

    final colorNames = aiColors
        .map(ColorNamer.getClosestColorName)
        .toSet()
        .toList();

    setStateIfMounted(() {
      _displayTags = {
        ...manualTags,
        ...translatedLabels,
        ...colorNames,
      }.toList();
      _isLoadingTags = false;
    });
  }

  Future<void> _addTag(String tag) async {
    final trimmedTag = tag.trim().toLowerCase();
    final existingTagsLower = (widget.garmentData['tags'] ?? [])
        .map((t) => t.toLowerCase())
        .toList();
    if (trimmedTag.isEmpty || existingTagsLower.contains(trimmedTag)) {
      _tagController.clear();
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final garmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(widget.garmentId);
    await garmentRef.update({
      'tags': FieldValue.arrayUnion([trimmedTag]),
    });

    setState(() {
      (widget.garmentData['tags'] as List).add(trimmedTag);
      _processAndSetTags();
    });
    _tagController.clear();
  }

  Future<void> _deleteTag(String tag) async {
    final user = FirebaseAuth.instance.currentUser!;
    final garmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(widget.garmentId);

    await garmentRef.update({
      'tags': FieldValue.arrayRemove([tag]),
    });

    setState(() {
      (widget.garmentData['tags'] as List).remove(tag);
      _processAndSetTags();
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
    setStateIfMounted(() => _isLoadingTags = true);
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('get_ai_tags_for_garment');
      final results = await callable.call<Map<String, dynamic>>({
        'garmentId': widget.garmentId,
      });

      final newAiLabels = List<String>.from(results.data['aiLabels'] ?? []);
      final newAiColors = List<String>.from(results.data['aiColors'] ?? []);

      setStateIfMounted(() {
        widget.garmentData['aiLabels'] = {
          ...List<String>.from(widget.garmentData['aiLabels'] ?? []),
          ...newAiLabels,
        }.toList();
        widget.garmentData['aiColors'] = {
          ...List<String>.from(widget.garmentData['aiColors'] ?? []),
          ...newAiColors,
        }.toList();
      });

      await _processAndSetTags();
    } on FirebaseFunctionsException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de IA: ${e.message}')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ha ocurrido un error inesperado.')),
        );
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoadingTags = false);
      }
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoadingTags) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Procesando etiquetas...'),
            ],
          ),
        ),
      );
    }

    final manualTags = List<String>.from(widget.garmentData['tags'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Etiquetas', style: Theme.of(context).textTheme.titleMedium),
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
            ..._displayTags.map(
              (tag) => Chip(
                label: Text(tag),
                onDeleted: manualTags.contains(tag)
                    ? () => _deleteTag(tag)
                    : null,
              ),
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
      if (!_focusNode.hasFocus && _isEditing) {
        _save();
      }
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
      setState(() {
        _isEditing = false;
      });
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
          setState(() {
            _isEditing = true;
          });
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
