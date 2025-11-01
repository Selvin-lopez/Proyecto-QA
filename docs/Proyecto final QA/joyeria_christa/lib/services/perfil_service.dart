import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PerfilService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Usuario autenticado
  User? get currentUser => _auth.currentUser;

  /// Referencia al documento de perfil
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('usuarios').doc(uid);

  /// Subcolección de direcciones
  CollectionReference<Map<String, dynamic>> _dirCol(String uid) =>
      _doc(uid).collection('direcciones');

  // ==================== PERFIL BÁSICO ====================

  Future<Map<String, dynamic>?> cargarPerfil() async {
    final user = currentUser;
    if (user == null) return null;

    final docRef = _doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      final now = FieldValue.serverTimestamp();
      final data = {
        'uid': user.uid,
        'nombre': user.displayName ?? 'Usuario',
        'email': user.email,
        'fotoUrl': user.photoURL,
        'direccion': '',
        'nitDpi': '',
        'creadoEn': now,
        'actualizadoEn': now,
      };
      await docRef.set(data);
      return data;
    }
    return snap.data();
  }

  /// ✅ Retorna los datos necesarios para crear un pedido
  Future<Map<String, dynamic>?> obtenerDatosEntrega() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _doc(user.uid).get();
    final data = doc.data();
    if (data == null) return null;

    return {
      'nombre': data['nombre'] ?? '',
      'telefono': data['telefono'] ?? '',
      'correo': data['email'] ?? user.email ?? '',
      'direccion': data['direccion'] ?? '',
      'nitDpi': data['nitDpi'] ?? '',
    };
  }

  Future<void> actualizarNombre(String nombre) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await user.updateDisplayName(nombre);
    await _doc(
      user.uid,
    ).update({'nombre': nombre, 'actualizadoEn': FieldValue.serverTimestamp()});
  }

  Future<void> actualizarDireccionYNit({
    required String direccion,
    required String nitDpi,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await _doc(user.uid).update({
      'direccion': direccion,
      'nitDpi': nitDpi,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> actualizarFoto(File archivo) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final ref = _storage.ref('perfiles/${user.uid}/avatar.jpg');
    await ref.putFile(archivo);
    final url = await ref.getDownloadURL();
    await user.updatePhotoURL(url);

    await _doc(
      user.uid,
    ).update({'fotoUrl': url, 'actualizadoEn': FieldValue.serverTimestamp()});

    return url;
  }

  Future<void> cambiarPassword(String nueva) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await user.updatePassword(nueva);
  }

  Future<void> cerrarSesion() => _auth.signOut();

  // ==================== NOTIFICACIONES ====================

  Future<Map<String, dynamic>> cargarNotificaciones() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final snap = await _doc(user.uid).get();
    final noti = (snap.data()?['notificaciones'] as Map?) ?? {};
    return {
      'promos': noti['promos'] ?? true,
      'pedidos': noti['pedidos'] ?? true,
      'novedades': noti['novedades'] ?? true,
    };
  }

  Future<void> guardarNotificaciones({
    required bool promos,
    required bool pedidos,
    required bool novedades,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _doc(user.uid).set({
      'notificaciones': {
        'promos': promos,
        'pedidos': pedidos,
        'novedades': novedades,
      },
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==================== DIRECCIONES ====================

  Stream<List<Map<String, dynamic>>> streamDirecciones() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collectionGroup('direcciones')
        .where('ownerId', isEqualTo: uid)
        .orderBy('principal', descending: true)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> upsertDireccion({
    String? id,
    required String etiqueta,
    required String linea1,
    String? linea2,
    String? ciudad,
    String? departamento,
    String? referencia,
    bool principal = false,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final ref = _dirCol(user.uid);

    if (principal) {
      final existing = await ref.get();
      for (final doc in existing.docs) {
        await doc.reference.update({'principal': false});
      }
    }

    final ahora = FieldValue.serverTimestamp();
    final base = <String, dynamic>{
      'ownerId': user.uid,
      'etiqueta': etiqueta,
      'linea1': linea1,
      'linea2': linea2,
      'ciudad': ciudad,
      'departamento': departamento,
      'referencia': referencia,
      'principal': principal,
      'actualizadoEn': ahora,
    };

    if (id == null) {
      base['creadoEn'] = ahora;
      await ref.add(base);
    } else {
      await ref.doc(id).set(base, SetOptions(merge: true));
    }
  }

  Future<void> eliminarDireccion(String id) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await _dirCol(user.uid).doc(id).delete();
  }

  Future<void> migrarDirecciones() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final snap = await _dirCol(uid).get();
    for (final d in snap.docs) {
      final m = d.data();
      final upd = <String, dynamic>{};
      if (m['ownerId'] == null) upd['ownerId'] = uid;
      if (m['creadoEn'] == null) upd['creadoEn'] = FieldValue.serverTimestamp();
      if (upd.isNotEmpty) await d.reference.update(upd);
    }
  }
}
