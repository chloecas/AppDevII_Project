import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class BalanceException implements Exception {
  BalanceException(this.message);
  final String message;
}

class CollectionsCrud {
  static const startingBalance = 1000;

  static final balance = ValueNotifier<double?>(null);

  static DocumentReference<Map<String, dynamic>> _user() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<void> loadBalance() async {
    final doc = await _user().get();
    balance.value = ((doc.data()?['balance'] as num?)?.toDouble() ?? startingBalance) as double?;
  }
  /// Reads the card's owner
  static Future<DocumentSnapshot<Map<String, dynamic>>> get(String cardId) => _user().collection('cards').doc(cardId).get();


  /// Changed Add to Buy to buy one copy at current market time.
  static Future<void> buy(String cardId, double price) async {
    final user = _user();
    final card = user.collection('cards').doc(cardId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userSnap = await tx.get(user);
      final cardSnap = await tx.get(card);
      final bal =
          (userSnap.data()?['balance'] as num?)?.toDouble() ?? startingBalance;

      if (bal < price) throw BalanceException('Not enough balance.');

      tx.set(user, {'balance': bal - price}, SetOptions(merge: true));

      if (cardSnap.exists) {
        final qty = (cardSnap.data()?['quantity'] as num?)?.toInt() ?? 1;
        final paid =
            (cardSnap.data()?['purchasePrice'] as num?)?.toDouble() ?? price;
        tx.update(card, {
          'quantity': qty + 1,
          'purchasePrice': (paid * qty + price) / (qty + 1), // average cost
        });
      } else {
        tx.set(card, {
          'quantity': 1,
          'purchasePrice': price,
          'dateAdded': FieldValue.serverTimestamp(),
        });
      }
    });
    await loadBalance();
  }

  /// removeOne changed to sell to sell a copy at market price
  static Future<void> sell(String cardId, double price, {bool all = false}) async {
    final user = _user();
    final card = user.collection('cards').doc(cardId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final userSnap = await tx.get(user);
      final cardSnap = await tx.get(card);
      if (!cardSnap.exists) throw BalanceException('You do not own this card.');

      final bal =
          (userSnap.data()?['balance'] as num?)?.toDouble() ?? startingBalance;
      final qty = (cardSnap.data()?['quantity'] as num?)?.toInt() ?? 1;
      final n = all ? qty : 1;

      tx.set(user, {'balance': bal + price * n}, SetOptions(merge: true));
      if (n >= qty) {
        tx.delete(card);
      } else {
        tx.update(card, {'quantity': qty - n});
      }
    });
    await loadBalance();

  }
}

