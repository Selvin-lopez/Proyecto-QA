import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get user => _firebaseAuth.currentUser;

  bool get isAuthenticated => user != null;

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    notifyListeners();
  }
}
