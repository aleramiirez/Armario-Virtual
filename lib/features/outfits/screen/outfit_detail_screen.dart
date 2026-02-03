import 'package:armariovirtual/features/outfits/services/outfit_service.dart';
import 'package:armariovirtual/features/outfits/widgets/outfit_canvas.dart';
import 'package:armariovirtual/shared/utils/app_alerts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OutfitDetailScreen extends StatefulWidget {
  final String outfitId;
  final Map<String, dynamic> outfitData;

  const OutfitDetailScreen({
    super.key,
    required this.outfitId,
    required this.outfitData,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  bool _isLoading = false;
  late List<String> _tags;
  bool _isEditingLayout = false;
  Map<String, dynamic>? _currentLayout;
  final OutfitService _outfitService = OutfitService();

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.outfitData['tags'] ?? []);
    if (widget.outfitData['layout'] != null) {
      _currentLayout = Map<String, dynamic>.from(widget.outfitData['layout']);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingLayout = !_isEditingLayout;
      // Reset layout if cancelling
      if (!_isEditingLayout) {
        if (widget.outfitData['layout'] != null) {
          _currentLayout = Map<String, dynamic>.from(
            widget.outfitData['layout'],
          );
        } else {
          _currentLayout = null;
        }
      }
    });
  }

  Future<void> _saveLayout() async {
    if (_currentLayout == null) return;

    setState(() => _isLoading = true);

    try {
      await _outfitService.updateOutfitLayout(widget.outfitId, _currentLayout!);

      // Update local data
      widget.outfitData['layout'] = _currentLayout;

      if (mounted) {
        setState(() {
          _isEditingLayout = false;
          _isLoading = false;
        });
        AppAlerts.showFloatingSnackBar(context, 'Diseño guardado con éxito');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al guardar el diseño',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteOutfit() async {
    final wantsToDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este outfit?',
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('outfits')
          .doc(widget.outfitId)
          .delete();

      if (mounted) {
        Navigator.of(context).pop(); // Close detail screen
        AppAlerts.showFloatingSnackBar(context, 'Outfit eliminado con éxito');
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al eliminar el outfit',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topData = widget.outfitData['topGarment'] as Map<String, dynamic>;
    final bottomData =
        widget.outfitData['bottomGarment'] as Map<String, dynamic>;
    final shoesData = widget.outfitData['shoesGarment'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Outfit'),
        actions: [
          if (_isEditingLayout) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditMode,
              tooltip: 'Cancelar',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveLayout,
              tooltip: 'Guardar Diseño',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _toggleEditMode,
              tooltip: 'Editar Diseño',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteOutfit,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imágenes agrupadas en el centro
                  // Imágenes agrupadas en el centro
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      height: 500, // Altura fija para el canvas
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: _isEditingLayout
                              ? BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: (_currentLayout != null || _isEditingLayout)
                            ? OutfitCanvas(
                                topData: topData,
                                bottomData: bottomData,
                                shoesData: shoesData,
                                initialLayout: _currentLayout,
                                isEditing: _isEditingLayout,
                                onLayoutChanged: (newLayout) {
                                  _currentLayout = newLayout;
                                },
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CachedNetworkImage(
                                        imageUrl: topData['imageUrl'],
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CachedNetworkImage(
                                        imageUrl: bottomData['imageUrl'],
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CachedNetworkImage(
                                        imageUrl: shoesData['imageUrl'],
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _LiveOutfitTagsEditor(
                    outfitId: widget.outfitId,
                    initialTags: _tags,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CompactGarmentImage extends StatelessWidget {
  final String imageUrl;

  const _CompactGarmentImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Altura fija para uniformidad
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }
}

// --- WIDGET EDITOR DE ETIQUETAS "EN VIVO" ---
class _LiveOutfitTagsEditor extends StatefulWidget {
  final String outfitId;
  final List<String> initialTags;

  const _LiveOutfitTagsEditor({
    required this.outfitId,
    required this.initialTags,
  });

  @override
  State<_LiveOutfitTagsEditor> createState() => _LiveOutfitTagsEditorState();
}

class _LiveOutfitTagsEditorState extends State<_LiveOutfitTagsEditor> {
  late List<String> _tags;
  final _tagController = TextEditingController();

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
    final outfitRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('outfits')
        .doc(widget.outfitId);
    await outfitRef.update({
      'tags': FieldValue.arrayUnion([newTag]),
    });
  }

  Future<void> _deleteTag(String tag) async {
    setState(() {
      _tags.remove(tag);
    });

    final user = FirebaseAuth.instance.currentUser!;
    final outfitRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('outfits')
        .doc(widget.outfitId);
    await outfitRef.update({
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
          decoration: const InputDecoration(hintText: 'Ej: Verano, Trabajo...'),
          onSubmitted: (value) {
            _addTag(value);
            Navigator.of(ctx).pop();
          },
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Etiquetas', style: Theme.of(context).textTheme.titleMedium),
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
