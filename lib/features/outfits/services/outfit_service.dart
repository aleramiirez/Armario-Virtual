import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OutfitService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOutfit({
    required Map<String, dynamic> topData,
    required Map<String, dynamic> bottomData,
    required Map<String, dynamic> shoesData,
    List<String>? tags,
    Map<String, dynamic>? layout,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('outfits')
        .add({
          'topGarmentId': topData['id'],
          'bottomGarmentId': bottomData['id'],
          'shoesGarmentId': shoesData['id'],
          'topGarment': {
            'name': topData['name'],
            'imageUrl': topData['imageUrl'],
          },
          'bottomGarment': {
            'name': bottomData['name'],
            'imageUrl': bottomData['imageUrl'],
          },
          'shoesGarment': {
            'name': shoesData['name'],
            'imageUrl': shoesData['imageUrl'],
          },
          'tags': tags ?? [],
          'layout': layout,
          'createdAt': Timestamp.now(),
        });
  }

  Future<void> updateOutfitLayout(
    String outfitId,
    Map<String, dynamic> layout,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('outfits')
        .doc(outfitId)
        .update({'layout': layout});
  }
}
