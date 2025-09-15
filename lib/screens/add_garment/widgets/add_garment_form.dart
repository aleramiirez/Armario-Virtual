import 'dart:io';
import 'package:armario_virtual/config/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';

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
      imageQuality: 80,
    );
    if (pickedImage == null) return;

    // Llama a la nueva función de recorte
    _cropImage(pickedImage.path);
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar Imagen',
          toolbarColor:
              AppTheme.colorPrimario, // Color de la barra superior del recorte
          toolbarWidgetColor:
              Colors.white, // Color de los iconos (incluye el tick)
          statusBarColor: AppTheme
              .colorPrimario, // Color de la barra de estado del teléfono durante el recorte
          activeControlsWidgetColor: AppTheme
              .colorPrimario, // Color de las líneas de recorte y de los botones activos
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Recortar Imagen',
          aspectRatioLockEnabled: false,
          // Y también aquí para iOS
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile == null) return;

    _processImage(croppedFile.path);
  }

  // En _AddGarmentFormState dentro de add_garment_form.dart

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

        // --- AHORA LLAMAMOS A _cropImage TAMBIÉN AQUÍ ---
        await _cropImage(tempPath);
      } else {
        throw Exception(
          'No se pudo descargar la imagen. Código: ${response.statusCode}',
        );
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
    // 1. Lee la imagen como bytes
    final imageBytes = await imageFile.readAsBytes();

    // 2. Llama a la Cloud Function que creamos para esto
    final callable = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('remove_background_from_image');

    final results = await callable.call<Map<String, dynamic>>({
      'imageBytes': imageBytes,
    });

    // 3. Recibe la imagen sin fondo y la guarda en el archivo temporal
    final processedImageBytes = results.data['imageBytes'] as List<int>;
    return await imageFile.writeAsBytes(
      Uint8List.fromList(processedImageBytes),
    );
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedImage == null) {
      // ... (Mostrar SnackBar de error)
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Procesando imagen...';
    });

    try {
      final imageWithoutBg = await _removeBackground(_selectedImage!);
      if (imageWithoutBg == null) throw Exception('Error al quitar fondo');

      final user = FirebaseAuth.instance.currentUser!;
      // Usamos el ID del usuario y la fecha para un nombre de archivo único
      final fileName = '${user.uid}_${DateTime.now().toIso8601String()}.png';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('garment_images')
          .child(user.uid)
          .child(fileName);

      await storageRef.putFile(imageWithoutBg);
      final imageUrl = await storageRef.getDownloadURL();

      // La lógica ahora es un simple '.add()'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('garments')
          .add({
            'name': _nameController.text.trim(),
            'imageUrl': imageUrl,
            'createdAt': Timestamp.now(),
            'tags': [], // Se crea una lista de etiquetas manuales vacía
          });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prenda guardada con éxito.'),
            backgroundColor: AppTheme.colorExito /*...*/,
          ),
        );
      }
    } catch (error) {
      // ... (manejo de errores)
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
            decoration: const InputDecoration(labelText: 'Nombre de la prenda'),
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
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20, // Ajusta el tamaño según veas
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
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
