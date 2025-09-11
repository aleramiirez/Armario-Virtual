import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isEditing = false;
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
          .update({'name': _nameController.text.trim()});
      setState(() {
        widget.garmentData['name'] = _nameController.text.trim();
        _isEditing = false;
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
        title: Text(_isEditing ? 'Editar Prenda' : widget.garmentData['name']),
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
              imageUrl: widget.garmentData['imageUrl'],
              nameController: _nameController,
              isEditing: _isEditing,
            ),
    );
  }
}

class _GarmentDetailView extends StatelessWidget {
  final String imageUrl;
  final TextEditingController nameController;
  final bool isEditing;

  const _GarmentDetailView({
    required this.imageUrl,
    required this.nameController,
    required this.isEditing,
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
    required this.isEditing,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return TextFormField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'Nombre de la prenda',
          border: OutlineInputBorder(),
        ),
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        nameController.text,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      );
    }
  }
}
