import 'dart:io';
import 'package:armario_virtual/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:armario_virtual/widgets/garment_tags_manager.dart';
import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>> _decodeImage(String imagePath) async {
  final imageBytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    return {'file': File(imagePath), 'aspectRatio': 1.0};
  }
  return {'file': File(imagePath), 'aspectRatio': image.width / image.height};
}

class AddGarmentForm extends StatefulWidget {
  const AddGarmentForm({super.key});

  @override
  State<AddGarmentForm> createState() => _AddGarmentFormState();
}

class _AddGarmentFormState extends State<AddGarmentForm> {
  final String _removeBgApiKey = 'tYhEo95Y3WK6BstT1NbhJKzs';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _selectedImage;
  double? _imageAspectRatio;
  bool _isLoading = false;
  String _loadingMessage = '';
  List<String> _currentTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Imagen'),
        content: const Text('¿Cómo quieres añadir la imagen de tu prenda?'),
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
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedImage == null) return;
    _processImage(pickedImage.path);
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
        await _processImage(tempPath);
      } else {
        throw Exception('No se pudo descargar la imagen.');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener la imagen: ${e.toString()}'),
          ),
        );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Procesando imagen...';
    });
    try {
      final imageDetails = await compute(_decodeImage, imagePath);
      setState(() {
        _selectedImage = imageDetails['file'] as File;
        _imageAspectRatio = imageDetails['aspectRatio'] as double;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: ${e.toString()}'),
          ),
        );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
    }
  }

  Future<File?> _removeBackground(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );
    request.headers['X-Api-Key'] = _removeBgApiKey;
    request.files.add(
      await http.MultipartFile.fromPath('image_file', imageFile.path),
    );
    final response = await request.send();
    if (response.statusCode == 200) {
      final imageBytes = await response.stream.toBytes();
      return await imageFile.writeAsBytes(imageBytes);
    } else {
      debugPrint(
        'Error de Remove.bg: ${await response.stream.bytesToString()}',
      );
      throw Exception('Error al quitar el fondo de la imagen.');
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Por favor, completa todos los campos y selecciona una imagen.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Quitando el fondo...';
    });
    try {
      final imageWithoutBg = await _removeBackground(_selectedImage!);
      if (imageWithoutBg == null) return;
      setState(() {
        _loadingMessage = 'Subiendo imagen...';
      });
      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('garment_images')
          .child('${user.uid}_${DateTime.now().toIso8601String()}.png');
      await storageRef.putFile(imageWithoutBg);
      final imageUrl = await storageRef.getDownloadURL();
      setState(() {
        _loadingMessage = 'Guardando datos...';
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('garments')
          .add({
            'name': _nameController.text.trim(),
            'imageUrl': imageUrl,
            'createdAt': Timestamp.now(),
            'tags': _currentTags,
          });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prenda guardada con éxito'),
            backgroundColor: AppTheme.colorExito,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _showImageSourceDialog,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isLoading && _selectedImage == null
                    ? SizedBox(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(_loadingMessage),
                          ],
                        ),
                      )
                    : _selectedImage != null
                    ? AspectRatio(
                        aspectRatio: _imageAspectRatio ?? 1.0,
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const SizedBox(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text('Pulsa para añadir una foto'),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la prenda (ej: Camiseta blanca)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, introduce un nombre.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          GarmentTagsManager(
            initialTags: _currentTags,
            onTagsUpdated: (updatedTags) {
              setState(() {
                _currentTags = updatedTags;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 24),
                      Text(_loadingMessage),
                    ],
                  )
                : const Text('GUARDAR PRENDA'),
          ),
        ],
      ),
    );
  }
}
