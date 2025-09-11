import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedImage == null) return;
    final imageDetails = await compute(_decodeImage, pickedImage.path);
    setState(() {
      _selectedImage = imageDetails['file'] as File;
      _imageAspectRatio = imageDetails['aspectRatio'] as double;
    });
  }
  
  Future<File?> _removeBackground(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );
    request.headers['X-Api-Key'] = _removeBgApiKey;
    request.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));
    
    final response = await request.send();

    if (response.statusCode == 200) {
      final imageBytes = await response.stream.toBytes();
      final newFile = await imageFile.writeAsBytes(imageBytes);
      return newFile;
    } else {
      throw Exception('Error al quitar el fondo de la imagen.');
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, completa todos los campos y selecciona una imagen.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

      setState(() { _loadingMessage = 'Subiendo imagen...'; });

      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('garment_images')
          .child('${user.uid}_${DateTime.now().toIso8601String()}.png');

      await storageRef.putFile(imageWithoutBg);
      final imageUrl = await storageRef.getDownloadURL();
      
      setState(() { _loadingMessage = 'Guardando datos...'; });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('garments').add({
        'name': _nameController.text,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prenda guardada con éxito'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _selectedImage != null
                    ? AspectRatio(
                        aspectRatio: _imageAspectRatio ?? 1.0,
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const SizedBox(
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
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
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, introduce un nombre.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(width: 24),
                      Text(_loadingMessage),
                    ],
                  )
                : const Text('GUARDAR PRENDA', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}