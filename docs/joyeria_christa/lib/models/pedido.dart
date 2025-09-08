import 'package:cloud_firestore/cloud_firestore.dart';
import 'producto_model.dart';

class Pedido {
  final String id;
  final DateTime fecha;
  final double total;
  final String estado;
  final List<ProductoModel> productos;

  Pedido({
    required this.id,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.productos,
  });

  /// ✅ MÉTODO NECESARIO PARA QUITAR EL ERROR
  factory Pedido.fromJson(Map<String, dynamic> json, String id) {
    return Pedido(
      id: id,
      fecha: (json['fecha'] as Timestamp).toDate(),
      total: (json['total'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      productos:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ProductoModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  /// (Opcional, pero recomendado si guardas pedidos)
  Map<String, dynamic> toJson() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'total': total,
      'estado': estado,
      'items': productos.map((p) => p.toJson()).toList(),
    };
  }
}
