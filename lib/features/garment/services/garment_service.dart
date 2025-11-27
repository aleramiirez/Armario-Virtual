import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// --- Funciones de Isolate (deben ser globales) ---

/// Redimensiona una imagen en un isolate para no bloquear la UI.
List<int> _resizeImageIsolate(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;
  if (image.width > 800 || image.height > 800) {
    final resized = image.width > image.height
        ? img.copyResize(image, width: 800)
        : img.copyResize(image, height: 800);
    return img.encodeJpg(resized, quality: 80);
  }
  return imageBytes;
}

/// Decodifica una imagen en un isolate para obtener sus dimensiones.
Map<String, dynamic> _decodeImageIsolate(String imagePath) {
  final imageBytes = File(imagePath).readAsBytesSync();
  final image = img.decodeImage(imageBytes);
  if (image == null) return {'aspectRatio': 1.0};
  return {'aspectRatio': image.width / image.height};
}

/// Recorta los bordes transparentes de una imagen en un isolate y añade un pequeño margen.
List<int> _trimImageIsolate(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;

  // 1. Recorta la imagen eliminando los bordes transparentes
  final trimmed = img.trim(image, mode: img.TrimMode.transparent);

  // 2. Añade un pequeño margen (padding) para que no quede pegada al borde
  const int padding = 20;
  final newWidth = trimmed.width + (padding * 2);
  final newHeight = trimmed.height + (padding * 2);

  // Crea una imagen nueva transparente (asegurando 4 canales para RGBA)
  final padded = img.Image(width: newWidth, height: newHeight, numChannels: 4);

  // Copia la imagen recortada en el centro (dstX, dstY)
  img.compositeImage(padded, trimmed, dstX: padding, dstY: padding);

  return img.encodePng(padded);
}

// --- Clase del Servicio ---

/// Servicio que encapsula toda la lógica de backend para gestionar prendas.
class GarmentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  /// Procesa y guarda una nueva prenda en Firebase.
  /// Este es el método principal que orquesta todo el proceso.
  Future<void> saveNewGarment({
    required String garmentName,
    required File imageFile,
    required String category, // Nuevo campo
    bool shouldProcess = true,
  }) async {
    // 1. Obtener el usuario actual. Si no hay, es un error.
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    // 2. Procesar la imagen: quitar fondo y redimensionar (si se solicita).
    final processedImageFile = shouldProcess
        ? await processImage(imageFile)
        : imageFile;

    // 3. Subir la imagen procesada a Firebase Storage.
    debugPrint('Iniciando subida de imagen...');
    final imageUrl = await _uploadImage(processedImageFile, user.uid);
    debugPrint('Imagen subida. URL: $imageUrl');

    // 4. Guardar los datos de la prenda en Firestore.
    debugPrint('Guardando datos en Firestore...');
    await _saveGarmentData(user.uid, garmentName, imageUrl, category);
    debugPrint('Datos guardados correctamente.');
  }

  Future<String> updateGarmentImage({
    required String garmentId,
    required String oldImageUrl,
    required File newImageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    // 1. Procesamos la nueva imagen (quitar fondo, redimensionar)
    final processedImageFile = await processImage(newImageFile);

    // 2. Subimos la nueva imagen a Storage
    final newImageUrl = await _uploadImage(processedImageFile, user.uid);

    // 3. Actualizamos la URL en el documento de Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('garments')
        .doc(garmentId)
        .update({'imageUrl': newImageUrl});

    // 4. Borramos la imagen antigua de Storage para no acumular basura
    try {
      await _storage.refFromURL(oldImageUrl).delete();
    } catch (e) {
      // Si falla el borrado (ej. URL inválida), no detenemos el proceso
      // pero sí lo registramos para futura depuración.
      debugPrint("Error al borrar la imagen antigua: $e");
    }

    // 5. Devolvemos la nueva URL para que la UI se actualice al instante
    return newImageUrl;
  }

  /// Llama a la Cloud Function para quitar el fondo y redimensiona la imagen.
  Future<File> processImage(File imageFile) async {
    // Leemos los bytes del archivo original
    final imageBytes = await imageFile.readAsBytes();

    // Redimensionamos en un Isolate para no congelar la UI
    final resizedBytes = await compute(_resizeImageIsolate, imageBytes);
    final imageBase64 = base64Encode(resizedBytes);

    // Llamamos a la Cloud Function
    try {
      final callable = _functions.httpsCallable(
        'remove_background_from_image',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
      );
      final results = await callable.call<Map<String, dynamic>>({
        'imageBase64': imageBase64,
      });

      // Decodificamos el resultado
      final processedImageBase64 = results.data['imageBase64'] as String;
      final processedImageBytes = base64Decode(processedImageBase64);

      // Recortamos los bordes transparentes
      final trimmedBytes = await compute(
        _trimImageIsolate,
        processedImageBytes,
      );

      return await imageFile.writeAsBytes(trimmedBytes);
    } catch (e) {
      debugPrint('Error al quitar el fondo: $e');
      // Si falla, devolvemos la imagen redimensionada original
      return await imageFile.writeAsBytes(resizedBytes);
    }
  }

  /// Sube un archivo de imagen a Firebase Storage y devuelve la URL de descarga.
  Future<String> _uploadImage(File imageFile, String userId) async {
    debugPrint(
      '[_uploadImage] Iniciando. Archivo: ${imageFile.path}, Tamaño: ${await imageFile.length()} bytes',
    );
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${userId}_$timestamp.png';
    final storageRef = _storage
        .ref()
        .child('garment_images')
        .child(userId)
        .child(fileName);

    debugPrint('[_uploadImage] Referencia creada: ${storageRef.fullPath}');

    try {
      final task = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/png'),
      );

      task.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          debugPrint(
            '[_uploadImage] Progreso: ${snapshot.bytesTransferred} / ${snapshot.totalBytes} (${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1)}%)',
          );
        },
        onError: (e) {
          debugPrint('[_uploadImage] Error en stream: $e');
        },
      );

      await task.timeout(const Duration(seconds: 60));
      debugPrint('[_uploadImage] Subida completada. Obteniendo URL...');
      final url = await storageRef.getDownloadURL();
      debugPrint('[_uploadImage] URL obtenida: $url');
      return url;
    } catch (e) {
      debugPrint('[_uploadImage] Excepción: $e');
      rethrow;
    }
  }

  /// Guarda los metadatos de la prenda en la subcolección del usuario.
  Future<void> _saveGarmentData(
    String userId,
    String garmentName,
    String imageUrl,
    String category,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('garments')
        .add({
          'name': garmentName,
          'imageUrl': imageUrl,
          'category': category,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Obtiene el aspect ratio de una imagen local.
  Future<double> getImageAspectRatio(String imagePath) async {
    final imageDetails = await compute(_decodeImageIsolate, imagePath);
    return imageDetails['aspectRatio'] as double;
  }
}
