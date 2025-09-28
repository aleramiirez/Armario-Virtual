import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OutfitService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOutfit({
    required String topGarmentId,
    required String bottomGarmentId,
    required String shoesGarmentId,
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
          'topGarmentId': topGarmentId,
          'bottomGarmentId': bottomGarmentId,
          'shoesGarmentId': shoesGarmentId,
          'createdAt': Timestamp.now(),
        });
  }
}
