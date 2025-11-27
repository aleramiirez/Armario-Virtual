import 'dart:async';
import 'dart:io';
import 'package:armariovirtual/features/garment/services/garment_service.dart';
import 'package:armariovirtual/shared/utils/app_alerts.dart';
import 'package:flutter/material.dart';
import 'package:armariovirtual/config/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// El formulario completo para añadir una nueva prenda.
class AddGarmentForm extends StatefulWidget {
  const AddGarmentForm({super.key});

  @override
  State<AddGarmentForm> createState() => _AddGarmentFormState();
}

class _AddGarmentFormState extends State<AddGarmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final GarmentService _garmentService = GarmentService();

  File? _selectedImage;
  double? _imageAspectRatio;
  bool _isLoading = false;
  String _loadingMessage = '';
  String? _selectedCategory;
  bool _formSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Muestra un diálogo para que el usuario elija la fuente de la imagen.
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
            child: const Text(
              'Desde Galería',
              style: TextStyle(color: AppTheme.colorTextoSecundario),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImageFromUrl();
            },
            child: const Text(
              'Desde URL (Recomendado)',
              style: TextStyle(color: AppTheme.colorTextoSecundario),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre la galería del dispositivo para seleccionar una imagen.
  Future<void> _pickImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedImage == null) return;
    await _processImage(pickedImage.path);
  }

  /// Muestra un diálogo para que el usuario pegue una URL de imagen.
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
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.colorTextoSecundario),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(urlController.text),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppTheme.colorTextoSecundario),
            ),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Procesa la imagen seleccionada para mostrarla en la UI.
  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Quitando fondo y procesando...';
    });
    try {
      // 1. Procesamos la imagen (resize + background removal)
      final processedFile = await _garmentService.processImage(File(imagePath));

      // 2. Obtenemos el aspect ratio de la imagen YA procesada
      final aspectRatio = await _garmentService.getImageAspectRatio(
        processedFile.path,
      );
      if (mounted) {
        setState(() {
          _selectedImage = processedFile;
          _imageAspectRatio = aspectRatio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error al procesar la imagen',
          isError: true,
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Orquesta el proceso de guardado llamando al servicio.
  Future<void> _submitForm() async {
    setState(() {
      _formSubmitted = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    final isCategoryValid = _selectedCategory != null;

    if (!isValid || !isCategoryValid || _selectedImage == null) {
      // Los errores se mostrarán en cada campo individualmente
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Guardando prenda...';
    });

    try {
      await _garmentService.saveNewGarment(
        garmentName: _nameController.text,
        imageFile: _selectedImage!,
        category: _selectedCategory!,
        shouldProcess: false, // Ya está procesada
      );

      if (mounted) {
        Navigator.of(context).pop();
        AppAlerts.showFloatingSnackBar(
          context,
          'Prenda guardada con éxito',
          // Margen para evitar el FAB y alinearse horizontalmente (izquierda: 20, derecha: 90, abajo: 20)
          margin: const EdgeInsets.only(left: 20, right: 90, bottom: 20),
        );
      }
    } catch (e) {
      debugPrint('Error en _submitForm: $e');
      if (mounted) {
        AppAlerts.showFloatingSnackBar(
          context,
          'Error: ${e.toString().replaceAll('Exception:', '').trim()}',
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
                border: Border.all(
                  color: (_formSubmitted && _selectedImage == null)
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey.shade300,
                ),
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
          if (_formSubmitted && _selectedImage == null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                'Por favor, añade una imagen.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la prenda',
              prefixIcon: Icon(Icons.checkroom),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, introduce un nombre.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownMenu<String>(
                width: constraints.maxWidth,
                initialSelection: _selectedCategory,
                label: const Text('Categoría'),
                leadingIcon: const Icon(Icons.category),
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    value: 'top',
                    label: 'Parte Superior',
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                    ),
                    labelWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 12.0,
                          ),
                          child: Text('Parte Superior'),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade300,
                          indent: 6,
                          endIndent: 12,
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuEntry(
                    value: 'bottom',
                    label: 'Parte Inferior',
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                    ),
                    labelWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 12.0,
                          ),
                          child: Text('Parte Inferior'),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade300,
                          indent: 6,
                          endIndent: 12,
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuEntry(
                    value: 'footwear',
                    label: 'Calzado',
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                    ),
                    labelWidget: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 12.0,
                      ),
                      child: Text('Calzado'),
                    ),
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                errorText: _formSubmitted && _selectedCategory == null
                    ? 'Por favor, selecciona una categoría.'
                    : null,
              );
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
                        height: 20,
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
