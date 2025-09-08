// 📁 lib/providers/pedidos_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/pedido.dart';
import '../models/producto_model.dart';

class PedidosProvider with ChangeNotifier {
  final List<Pedido> _pedidos = [];

  List<Pedido> get pedidos => List.unmodifiable(_pedidos);

  /// 🛒 Agrega el pedido y lo guarda en Firestore
  Future<void> agregarPedido(
    List<ProductoModel> productos,
    String usuarioId,
    String emailUsuario,
  ) async {
    final pedidoTemporal = Pedido(
      id: '', // temporal, será reemplazado
      fecha: DateTime.now(),
      estado: 'pendiente',
      productos: productos,
      total: productos.fold(0.0, (sum, p) => sum + (p.precio * p.cantidad)),
    );

    final pedidoConId = await guardarPedidoEnFirestore(
      pedidoTemporal,
      usuarioId,
      emailUsuario,
    );

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

  /// 🔄 Carga los pedidos desde Firestore
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

  /// ✅ Guarda el pedido en Firestore y devuelve uno nuevo con el ID asignado
  Future<Pedido> guardarPedidoEnFirestore(
    Pedido pedido,
    String usuarioId,
    String emailUsuario,
  ) async {
    final docRef = await FirebaseFirestore.instance.collection('pedidos').add({
      'usuarioId': usuarioId,
      'email': emailUsuario,
      'fecha': Timestamp.fromDate(pedido.fecha),
      'estado': pedido.estado,
      'total': pedido.total,
      'items': pedido.productos.map((p) => p.toJson()).toList(),
    });

    return Pedido(
      id: docRef.id, // El ID generado por Firestore
      fecha: pedido.fecha,
      estado: pedido.estado,
      productos: pedido.productos,
      total: pedido.total,
    );
  }
}
