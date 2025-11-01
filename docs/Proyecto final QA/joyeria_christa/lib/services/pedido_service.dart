// lib/services/pedido_service.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/joya_model.dart';
import '../models/pedido_model.dart';

class PedidoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final bool mostrarLogs = true;

  Future<String?> crearPedido({
    required List<Joya> joyas,
    required String metodoPago, // 'tarjeta' | 'efectivo'
    required Map<String, dynamic> datosEntrega,
    Map<String, dynamic>? tarjeta, // solo si metodoPago == 'tarjeta'
  }) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      _log('[PedidoService] ❌ Usuario no autenticado');
      return null;
    }
    if (joyas.isEmpty) {
      _log('[PedidoService] ❌ El carrito está vacío');
      return null;
    }

    // Validación de entrega con lista de faltantes
    final req = ['nombre', 'telefono', 'correo', 'direccion', 'nitDpi'];
    final faltantes = <String>[];
    for (final k in req) {
      final v = (datosEntrega[k] ?? '').toString().trim();
      if (v.isEmpty) faltantes.add(k);
    }
    if (faltantes.isNotEmpty) {
      _log(
        '[PedidoService] ❌ Faltan datos de entrega: ${faltantes.join(', ')}',
      );
      return null;
    }

    // Validar tarjeta si aplica
    if (metodoPago == 'tarjeta') {
      if (tarjeta == null) {
        _log('[PedidoService] ❌ No se enviaron datos de tarjeta');
        return null;
      }
      final reqT = ['brand', 'last4', 'nombre', 'vencimiento', 'authCode'];
      final faltanT = <String>[];
      for (final k in reqT) {
        final v = (tarjeta[k] ?? '').toString().trim();
        if (v.isEmpty) faltanT.add(k);
      }
      if (faltanT.isNotEmpty) {
        _log(
          '[PedidoService] ❌ Faltan datos de tarjeta: ${faltanT.join(', ')}',
        );
        return null;
      }
    }

    try {
      final double total = joyas.fold(0.0, (s, j) => s + j.subtotal);

      final pedido = {
        'usuarioId': usuario.uid,
        'email': datosEntrega['correo'] ?? usuario.email ?? 'Sin email',
        'nombre': datosEntrega['nombre'],
        'telefono': datosEntrega['telefono'],
        'direccion': datosEntrega['direccion'],
        'nitDpi': datosEntrega['nitDpi'],
        'metodoPago': metodoPago,
        'fecha': FieldValue.serverTimestamp(),
        'total': total,
        'estado': 'pendiente',
        'items': joyas.map((j) => j.toJson()).toList(),
        if (tarjeta != null) 'tarjeta': tarjeta,
      };

      final ref = await _db.collection('pedidos').add(pedido);
      _log('[PedidoService] ✅ Pedido creado: ${ref.id}');
      return ref.id;
    } catch (e, st) {
      _log('[PedidoService] 🛑 Error al crear pedido: $e', stackTrace: st);
      return null;
    }
  }

  Future<List<Pedido>> obtenerMisPedidos() async {
    final usuario = _auth.currentUser;
    if (usuario == null)
      throw Exception('[PedidoService] Usuario no autenticado');
    try {
      final snap = await _db
          .collection('pedidos')
          .where('usuarioId', isEqualTo: usuario.uid)
          .orderBy('fecha', descending: true)
          .get();
      return snap.docs.map((d) => Pedido.fromJson(d.data(), d.id)).toList();
    } catch (e, st) {
      _log('[PedidoService] Error al obtener pedidos: $e', stackTrace: st);
      rethrow;
    }
  }

  Future<Pedido> obtenerPedidoPorId(String id) async {
    try {
      final doc = await _db.collection('pedidos').doc(id).get();
      if (!doc.exists) throw Exception('[PedidoService] Pedido no encontrado');
      return Pedido.fromJson(doc.data()!, doc.id);
    } catch (e, st) {
      _log(
        '[PedidoService] Error al obtener pedido por ID: $e',
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<bool> cancelarMiPedido(String pedidoId) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      _log('[PedidoService] ❌ Usuario no autenticado');
      return false;
    }
    try {
      final ref = _db.collection('pedidos').doc(pedidoId);
      final doc = await ref.get();
      if (!doc.exists) {
        _log('[PedidoService] ❌ El pedido no existe');
        return false;
      }
      final data = doc.data();
      if (data == null || data['usuarioId'] != usuario.uid) {
        _log('[PedidoService] ❌ No puedes cancelar este pedido');
        return false;
      }
      if ((data['estado'] ?? '') == 'cancelado') {
        _log('[PedidoService] ⚠️ El pedido ya estaba cancelado');
        return true;
      }
      await ref.update({'estado': 'cancelado'});
      _log('[PedidoService] ✅ Pedido cancelado');
      return true;
    } catch (e, st) {
      _log('[PedidoService] 🛑 Error al cancelar: $e', stackTrace: st);
      return false;
    }
  }

  void _log(String m, {StackTrace? stackTrace}) {
    if (mostrarLogs) log(m, stackTrace: stackTrace);
  }
}
