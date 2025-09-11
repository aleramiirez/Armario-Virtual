import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:armario_virtual/theme/app_theme.dart';

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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prenda eliminada')));
      }
    } catch (e) {
      throw Exception(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges(String newName) async {
    if (newName.trim().isEmpty || newName.trim() == widget.garmentData['name'])
      return;

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('garments')
          .doc(widget.garmentId)
          .update({'name': newName.trim()});
          .update({'name': _nameController.text.trim()});
      setState(() {
        widget.garmentData['name'] = newName.trim();
        _nameController.text = newName.trim();
      });
    } catch (e) {
      // Manejar error...
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
          if (_isEditing)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges)
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
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
              imageUrl: widget.garmentData['imageUrl'],
              initialName: widget.garmentData['name'],
              initialTags: List<String>.from(widget.garmentData['tags'] ?? []),
              onNameSaved: _saveChanges,
            ),
    );
  }
}

class _GarmentDetailView extends StatelessWidget {
  final String garmentId;
  final String imageUrl;
  final String initialName;
  final List<String> initialTags;
  final Function(String newName) onNameSaved;

  const _GarmentDetailView({
    required this.garmentId,
    required this.imageUrl,
    required this.initialName,
    required this.initialTags,
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
              child: Image.network(imageUrl),
            ),
            const SizedBox(height: 24),
            _GarmentNameDisplay(
              initialName: initialName,
              onNameSaved: onNameSaved,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _LiveGarmentTagsEditor(
              garmentId: garmentId,
              initialTags: initialTags,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveGarmentTagsEditor extends StatefulWidget {
  final String garmentId;
  final List<String> initialTags;

  const _LiveGarmentTagsEditor({
    required this.garmentId,
    required this.initialTags,
  });

  @override
  State<_LiveGarmentTagsEditor> createState() => _LiveGarmentTagsEditorState();
}

class _LiveGarmentTagsEditorState extends State<_LiveGarmentTagsEditor> {
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
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty || _tags.contains(trimmedTag)) {
      _tagController.clear();
      return;
    }
    ;

    setState(() {
      _tags.add(trimmedTag);
    }); // Actualiza UI al instante
    final user = FirebaseAuth.instance.currentUser!;
    final garmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(widget.garmentId);
    await garmentRef.update({
      'tags': FieldValue.arrayUnion([trimmedTag]),
    });
    _tagController.clear();
  }

  Future<void> _deleteTag(String tag) async {
    setState(() {
      _tags.remove(tag);
    }); // Actualiza UI al instante
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

class _GarmentNameDisplay extends StatefulWidget {
  final String initialName;
  final Function(String newName) onNameSaved;
              isEditing: isEditing,
              nameController: nameController,
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentNameDisplay extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;

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
