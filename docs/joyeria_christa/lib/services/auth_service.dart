import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== Observables / getters =====
  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ===== Email/Password =====
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Opcional: set displayName dentro de Auth
      await cred.user?.updateDisplayName(name.trim());

      await _ensureUserDoc(
        cred.user!,
        name: name.trim(),
        // puedes agregar campos default aquí si lo deseas
      );
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<void> sendReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ===== Google Sign-In (web vs móvil) =====
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final cred = await _auth.signInWithPopup(provider);
        await _ensureUserDoc(cred.user!, name: cred.user!.displayName ?? '');
        return cred;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'canceled-by-user',
            message: 'Inicio con Google cancelado',
          );
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        final result = await _auth.signInWithCredential(credential);
        await _ensureUserDoc(
          result.user!,
          name: result.user!.displayName ?? '',
        );
        return result;
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ===== Sign out =====
  Future<void> signOut() async {
    await _auth.signOut();
    // Solo intenta cerrar sesión en Google en móvil
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  // ===== Utilidades opcionales =====
  Future<void> ensureEmailVerified() async {
    final u = _auth.currentUser;
    if (u != null && !u.emailVerified) {
      await u.sendEmailVerification();
    }
  }

  Future<void> reauthWithPassword(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.reauthenticateWithCredential(cred);
  }

  // ===== Persistencia en Firestore =====
  Future<void> _ensureUserDoc(User user, {required String name}) async {
    // 🔁 Ajuste de colección: usamos 'usuarios' para mantener consistencia
    final ref = _db.collection('usuarios').doc(user.uid);
    final snap = await ref.get();

    final base = {
      'uid': user.uid,
      'nombre': (name.isNotEmpty ? name : (user.displayName ?? '')).trim(),
      'email': user.email,
      'fotoUrl': user.photoURL,
      'rol': 'cliente',
      'estado': 'activo',
      'proveedores': user.providerData.map((p) => p.providerId).toList(),
    };

    if (!snap.exists) {
      await ref.set({
        ...base,
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        ...base,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ===== Mapeo de errores =====
  Exception _mapFirebaseError(FirebaseAuthException e) {
    final code = e.code;
    final msg = switch (code) {
      'invalid-email' => 'El correo no es válido.',
      'user-disabled' => 'La cuenta está deshabilitada.',
      'user-not-found' => 'No existe un usuario con ese correo.',
      'wrong-password' => 'La contraseña es incorrecta.',
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'weak-password' => 'La contraseña es muy débil.',
      'operation-not-allowed' => 'Operación no permitida.',
      'account-exists-with-different-credential' =>
        'Ya existe una cuenta con distinto método para este correo.',
      'network-request-failed' => 'Sin conexión. Intenta de nuevo.',
      'popup-closed-by-user' => 'Se cerró la ventana de Google.',
      'canceled-by-user' => 'Inicio cancelado por el usuario.',
      _ => e.message ?? 'Error de autenticación ($code).',
    };
    return Exception(msg);
  }
}
