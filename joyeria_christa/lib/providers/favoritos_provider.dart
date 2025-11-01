import 'dart:async'; // ✅ para StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/joya_model.dart';

class FavoritosProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _subscription; // ✅ para controlar el stream
  List<Joya> _favoritos = [];
  List<Joya> get favoritos => _favoritos;

  /// 🔹 Cargar favoritos en tiempo real (solo 1 listener activo)
  void cargarFavoritos() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Cancelar listener anterior si ya existía
    _subscription?.cancel();

    _subscription = _db
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .snapshots()
        .listen((snapshot) {
          _favoritos = snapshot.docs.map((doc) {
            final data = doc.data();
            return Joya(
              id: doc.id,
              nombre: data['nombre'] ?? '',
              imagen: data['imagen'] ?? '',
              precio: (data['precio'] ?? 0).toDouble(),
              material: data['material'] ?? '',
              peso: (data['peso'] ?? 0).toDouble(),
              tipo: data['tipo'] ?? '',
              cantidad: data['cantidad'] ?? 1,
              descuento: data['descuento'] ?? 0,
              esNuevo: data['esNuevo'] ?? false,
              esOferta: data['esOferta'] ?? false,
              esTop: data['esTop'] ?? false,
            );
          }).toList();

          notifyListeners();
        });
  }

  /// 🔹 Verificar si una joya ya está en favoritos
  bool esFavorito(String joyaId) {
    return _favoritos.any((j) => j.id == joyaId);
  }

  /// 🔹 Agregar joya a favoritos
  Future<void> agregarFavorito(Joya joya) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .doc(joya.id)
        .set({
          'nombre': joya.nombre,
          'imagen': joya.imagen,
          'precio': joya.precio,
          'material': joya.material,
          'peso': joya.peso,
          'tipo': joya.tipo,
          'cantidad': joya.cantidad,
          'descuento': joya.descuento,
          'esNuevo': joya.esNuevo,
          'esOferta': joya.esOferta,
          'esTop': joya.esTop,
          'fechaAgregado':
              FieldValue.serverTimestamp(), // ✅ mejor que DateTime.now()
        });
  }

  /// 🔹 Quitar joya de favoritos
  Future<void> quitarFavorito(String joyaId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .doc(joyaId)
        .delete();
  }

  /// 🔹 Vaciar todos los favoritos
  Future<void> limpiarFavoritos() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _db
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// 🔹 Cerrar stream al destruir provider
  @override
  void dispose() {
    _subscription?.cancel(); // ✅ evitamos fugas de memoria
    super.dispose();
  }
}
