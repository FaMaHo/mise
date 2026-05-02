import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // =========================
  // CREATE HOUSEHOLD
  // =========================
  Future<String> createHousehold(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final inviteCode = _generateInviteCode();

    final householdRef = await _firestore.collection('households').add({
      'name': name,
      'ownerId': user.uid,
      'members': [user.uid],
      'inviteCode': inviteCode,
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection('users').doc(user.uid).set({
      'householdId': householdRef.id,
      'email': user.email,
    }, SetOptions(merge: true));

    return inviteCode; // ✅ NEW
  }

  // =========================
  // JOIN HOUSEHOLD
  // =========================
  Future<void> joinHousehold(String inviteCode) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final query = await _firestore
        .collection('households')
        .where('inviteCode', isEqualTo: inviteCode)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code');
    }

    final householdDoc = query.docs.first;

    await householdDoc.reference.update({
      'members': FieldValue.arrayUnion([user.uid]),
    });

    await _firestore.collection('users').doc(user.uid).set({
      'householdId': householdDoc.id,
      'email': user.email,
    }, SetOptions(merge: true));
  }

  // =========================
  // INVITE CODE GENERATOR
  // =========================
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final seed = DateTime.now().millisecondsSinceEpoch;

    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(seed + i * 7) % chars.length];
    }

    return '${code.substring(0, 3)}-${code.substring(3, 6)}';
  }
}
