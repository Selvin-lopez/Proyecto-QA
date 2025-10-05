// 📁 lib/providers/pedidos_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/pedido_model.dart';
import '../models/joya_model.dart';

class PedidosProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);

  /// 🛒 Agrega un pedido y lo guarda en Firestore
  Future<void> agregarPedido({
    required List<Joya> joyas,
    required String usuarioId,
    required String emailUsuario,
    required String nombre,
    required String telefono,
    required String correo,
    required String direccion,
    required String nitDpi,
    required String metodoPago,
    Map<String, dynamic>? tarjetaInfo,
    String estado = 'pendiente',
  }) async {
    final double total = joyas.fold(0.0, (sum, j) => sum + j.subtotal);

    final pedido = Pedido(
      id: '',
      usuarioId: usuarioId,
      email: emailUsuario,
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
      nitDpi: nitDpi,
      metodoPago: metodoPago,
      estado: estado,
      total: total,
      fecha: DateTime.now(),
      items: joyas,
      tarjeta: tarjetaInfo,
    );

    final pedidoConId = await guardarPedidoEnFirestore(pedido);

    _pedidos.insert(0, pedidoConId);
    notifyListeners();
  }

  Pedido? obtenerPedidoPorId(String id) {
    try {
      return _pedidos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 🔄 Carga los pedidos desde Firestore (una sola vez)
  Future<void> cargarPedidosDesdeFirestore(String usuarioId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .get();

    _pedidos.clear();

    for (final doc in snapshot.docs) {
      final pedido = Pedido.fromJson(doc.data(), doc.id);
      _pedidos.add(pedido);
    }

    notifyListeners();
  }

  /// 🔄 Suscripción en tiempo real a Firestore
  void escucharPedidosRealtime(String usuarioId) {
    FirebaseFirestore.instance
        .collection('pedidos')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .listen((snapshot) {
          _pedidos.clear();
          for (final doc in snapshot.docs) {
            final pedido = Pedido.fromJson(doc.data(), doc.id);
            _pedidos.add(pedido);
          }
          notifyListeners();
        });
  }

  /// ✅ Guarda el pedido en Firestore y devuelve uno nuevo con el ID asignado
  Future<Pedido> guardarPedidoEnFirestore(Pedido pedido) async {
    final docRef = await FirebaseFirestore.instance
        .collection('pedidos')
        .add(pedido.toJson());

    return Pedido(
      id: docRef.id,
      usuarioId: pedido.usuarioId,
      email: pedido.email,
      nombre: pedido.nombre,
      telefono: pedido.telefono,
      direccion: pedido.direccion,
      nitDpi: pedido.nitDpi,
      metodoPago: pedido.metodoPago,
      estado: pedido.estado,
      total: pedido.total,
      fecha: pedido.fecha,
      items: pedido.items,
      tarjeta: pedido.tarjeta,
    );
  }
}
