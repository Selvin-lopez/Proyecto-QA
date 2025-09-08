import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/joya_model.dart';
import '../models/pedido_model.dart';

class PedidoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final bool mostrarLogs = true;

  /// ✅ Crea un nuevo pedido y retorna su ID o null si falla
  Future<String?> crearPedido({
    required List<Joya> joyas,
    required String metodoPago, // 'tarjeta', 'paypal', 'efectivo'
    required Map<String, dynamic> datosEntrega,
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

    final camposRequeridos = [
      'nombre',
      'telefono',
      'correo',
      'direccion',
      'nitDpi',
    ];
    for (final campo in camposRequeridos) {
      if ((datosEntrega[campo] ?? '').toString().trim().isEmpty) {
        _log('[PedidoService] ❌ Faltan datos obligatorios: $campo');
        return null;
      }
    }

    try {
      final double total = joyas.fold(0.0, (sum, j) => sum + j.subtotal);

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
      };

      final ref = await _db.collection('pedidos').add(pedido);
      _log('[PedidoService] ✅ Pedido creado con ID: ${ref.id}');
      return ref.id;
    } catch (e, stack) {
      _log(
        '[PedidoService] 🛑 Error al crear el pedido: $e',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// 📥 Retorna la lista de pedidos del usuario autenticado
  Future<List<Pedido>> obtenerMisPedidos() async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw Exception('[PedidoService] Usuario no autenticado');
    }

    try {
      final snapshot = await _db
          .collection('pedidos')
          .where('usuarioId', isEqualTo: usuario.uid)
          .orderBy('fecha', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Pedido.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e, stack) {
      _log('[PedidoService] Error al obtener pedidos: $e', stackTrace: stack);
      rethrow;
    }
  }

  /// 🔎 Retorna un pedido específico por ID
  Future<Pedido> obtenerPedidoPorId(String id) async {
    try {
      final doc = await _db.collection('pedidos').doc(id).get();
      if (!doc.exists) {
        throw Exception('[PedidoService] Pedido no encontrado');
      }
      return Pedido.fromJson(doc.data()!, doc.id);
    } catch (e, stack) {
      _log(
        '[PedidoService] Error al obtener pedido por ID: $e',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 🚫 Cancela un pedido si pertenece al usuario autenticado
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
        _log('[PedidoService] ❌ No puedes cancelar un pedido que no es tuyo');
        return false;
      }

      if ((data['estado'] ?? '') == 'cancelado') {
        _log('[PedidoService] ⚠️ El pedido ya estaba cancelado');
        return true;
      }

      await ref.update({'estado': 'cancelado'});
      _log('[PedidoService] ✅ Pedido cancelado exitosamente');
      return true;
    } catch (e, stack) {
      _log(
        '[PedidoService] 🛑 Error al cancelar el pedido: $e',
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 🧾 Logger privado con control de bandera
  void _log(String mensaje, {StackTrace? stackTrace}) {
    if (mostrarLogs) log(mensaje, stackTrace: stackTrace);
  }
}
