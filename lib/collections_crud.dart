import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollectionsCrud {
  static CollectionReference<Map<String, dynamic>> _cards() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cards');
  }

  /// Adds one copy of a card. If the user already owns it, quantity goes up
  /// and the original purchase price is kept.
  static Future<void> add(String cardId, {double? purchasePrice}) async {
    final ref = _cards().doc(cardId);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set({
        'quantity': 1,
        'purchasePrice': purchasePrice,
        'dateAdded': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Removes one copy. Deletes the document when the last copy is removed.
  static Future<void> removeOne(String cardId) async {
    final ref = _cards().doc(cardId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final qty = (snap.data()?['quantity'] as num?)?.toInt() ?? 1;
    if (qty <= 1) {
      await ref.delete();
    } else {
      await ref.update({'quantity': FieldValue.increment(-1)});
    }
  }

  /// Deletes the card from the collection entirely.
  static Future<void> removeAll(String cardId) => _cards().doc(cardId).delete();

  /// Live view of one card's ownership document (exists = user owns it).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String cardId) =>
      _cards().doc(cardId).snapshots();

  static Future<DocumentSnapshot<Map<String, dynamic>>> get(String cardId) =>
      _cards().doc(cardId).get();
}

