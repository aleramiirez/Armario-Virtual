import 'package:flutter/material.dart';

class GarmentTagsManager extends StatefulWidget {
  final List<String> initialTags;
  final Function(List<String> updatedTags) onTagsUpdated;

  const GarmentTagsManager({
    super.key,
    required this.initialTags,
    required this.onTagsUpdated,
  });

  @override
  State<GarmentTagsManager> createState() => _GarmentTagsManagerState();
}

class _GarmentTagsManagerState extends State<GarmentTagsManager> {
  late List<String> _tags;
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty || _tags.contains(trimmedTag)) {
      _tagController.clear();
      return;
    }

    setState(() {
      _tags.add(trimmedTag);
    });
    widget.onTagsUpdated(_tags); // Notifica al widget padre del cambio
    _tagController.clear();
  }

  void _deleteTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onTagsUpdated(_tags); // Notifica al widget padre del cambio
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
