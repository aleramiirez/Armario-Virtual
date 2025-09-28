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
  if (image.width > 1024 || image.height > 1024) {
    final resized = image.width > image.height
        ? img.copyResize(image, width: 1024)
        : img.copyResize(image, height: 1024);
    return img.encodeJpg(resized, quality: 85);
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
  }) async {
    // 1. Obtener el usuario actual. Si no hay, es un error.
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    // 2. Procesar la imagen: quitar fondo y redimensionar.
    final processedImageFile = await _processImage(imageFile);

    // 3. Subir la imagen procesada a Firebase Storage.
    final imageUrl = await _uploadImage(processedImageFile, user.uid);

    // 4. Guardar los datos de la prenda en Firestore.
    await _saveGarmentData(user.uid, garmentName, imageUrl);
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
    final processedImageFile = await _processImage(newImageFile);

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
  Future<File> _processImage(File imageFile) async {
    // Leemos los bytes del archivo original
    final imageBytes = await imageFile.readAsBytes();

    // Redimensionamos en un Isolate para no congelar la UI
    final resizedBytes = await compute(_resizeImageIsolate, imageBytes);
    final imageBase64 = base64Encode(resizedBytes);

    // Llamamos a la Cloud Function
    final callable = _functions.httpsCallable('remove_background_from_image');
    final results = await callable.call<Map<String, dynamic>>({
      'imageBase64': imageBase64,
    });

    // Decodificamos el resultado y lo escribimos de vuelta en el archivo
    final processedImageBase64 = results.data['imageBase64'] as String;
    final processedImageBytes = base64Decode(processedImageBase64);

    return await imageFile.writeAsBytes(processedImageBytes);
  }

  /// Sube un archivo de imagen a Firebase Storage y devuelve la URL de descarga.
  Future<String> _uploadImage(File imageFile, String userId) async {
    final fileName = '${userId}_${DateTime.now().toIso8601String()}.png';
    final storageRef = _storage
        .ref()
        .child('garment_images')
        .child(userId)
        .child(fileName);

    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  /// Guarda los metadatos de la prenda en la subcolección del usuario.
  Future<void> _saveGarmentData(
    String userId,
    String garmentName,
    String imageUrl,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('garments')
        .add({
          'name': garmentName.trim(),
          'imageUrl': imageUrl,
          'createdAt': Timestamp.now(),
          'tags': [],
        });
  }

  /// Obtiene las dimensiones de una imagen de forma asíncrona.
  /// Se usa para mostrar la previsualización correctamente.
  Future<double> getImageAspectRatio(String imagePath) async {
    final imageDetails = await compute(_decodeImageIsolate, imagePath);
    return imageDetails['aspectRatio'] as double;
  }
}
