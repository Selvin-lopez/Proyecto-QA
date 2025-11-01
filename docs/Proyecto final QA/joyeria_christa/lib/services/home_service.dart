// 📁 lib/services/home_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Banners activos
  Stream<List<Map<String, dynamic>>> obtenerBanners() {
    return _db
        .collection('banners')
        .where('activo', isEqualTo: true)
        .orderBy('orden', descending: false)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            return {
              ...data,
              'id': doc.id,
              'imagen': (data['imagen'] ?? '').toString(),
              'titulo': (data['titulo'] ?? 'Sin título').toString(),
            };
          }).toList();
        });
  }

  /// 🔹 Joyas en oferta (requiere índice: esOferta + descuento)
  Stream<List<Map<String, dynamic>>> obtenerJoyasOferta() {
    return _db
        .collection('joyas')
        .where('esOferta', isEqualTo: true)
        .orderBy('descuento', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            return {
              ...data,
              'id': doc.id,
              'precio': (data['precio'] is num)
                  ? (data['precio'] as num).toDouble()
                  : 0.0,
              'descuento': (data['descuento'] ?? 0) as int,
            };
          }).toList();
        });
  }

  /// 🔹 Joyas TOP (solo filtro simple)
  Stream<List<Map<String, dynamic>>> obtenerJoyasTop() {
    return _db
        .collection('joyas')
        .where('esTop', isEqualTo: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            return {
              ...data,
              'id': doc.id,
              'precio': (data['precio'] is num)
                  ? (data['precio'] as num).toDouble()
                  : 0.0,
            };
          }).toList();
        });
  }

  /// 🔹 Joyas nuevas (requiere índice: esNuevo + fechaIngreso)
  Stream<List<Map<String, dynamic>>> obtenerJoyasNuevas() {
    return _db
        .collection('joyas')
        .where('esNuevo', isEqualTo: true)
        .orderBy('fechaIngreso', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());

            // 🔑 Convertir fechaIngreso si es Timestamp
            if (data['fechaIngreso'] is Timestamp) {
              data['fechaIngreso'] = (data['fechaIngreso'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            } else {
              // fallback si aún tienes strings
              data['fechaIngreso'] =
                  (data['fechaIngreso'] ?? DateTime.now().toIso8601String())
                      .toString();
            }

            return {
              ...data,
              'id': doc.id,
              'precio': (data['precio'] is num)
                  ? (data['precio'] as num).toDouble()
                  : 0.0,
            };
          }).toList();
        });
  }
}
