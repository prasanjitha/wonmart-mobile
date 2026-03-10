import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getAgentProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('agents').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<String> getAgentFirstName() async {
    final profile = await getAgentProfile();
    if (profile != null) {
      final fullName = profile['name'] as String? ?? 'Agent';
      return fullName.split(' ').first;
    }
    return _auth.currentUser?.displayName?.split(' ').first ?? 'Agent';
  }

  Future<String> getAgentRegion() async {
    final profile = await getAgentProfile();
    return profile?['region'] as String? ?? '';
  }
}
