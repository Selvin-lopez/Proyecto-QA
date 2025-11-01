import 'package:cloud_firestore/cloud_firestore.dart';
import 'joya_model.dart';

class Pedido {
  final String id;
  final String usuarioId;
  final String email;
  final String nombre;
  final String telefono;
  final String direccion;
  final String nitDpi;
  final String metodoPago;
  final String estado;
  final double total;
  final DateTime? fecha;
  final List<Joya> items;
  final Map<String, dynamic>? tarjeta; // 🔹 NUEVO: datos de tarjeta

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.email,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.nitDpi,
    required this.metodoPago,
    required this.estado,
    required this.total,
    required this.fecha,
    required this.items,
    this.tarjeta, // 🔹 opcional
  });

  /// 🔄 Convierte desde Firestore
  factory Pedido.fromJson(Map<String, dynamic> json, String id) {
    return Pedido(
      id: id,
      usuarioId: json['usuarioId'] ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      direccion: json['direccion'] ?? '',
      nitDpi: json['nitDpi'] ?? '',
      metodoPago: json['metodoPago'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      total: (json['total'] ?? 0).toDouble(),
      fecha: (json['fecha'] != null && json['fecha'] is Timestamp)
          ? (json['fecha'] as Timestamp).toDate()
          : null,
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Joya.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      tarjeta: json['tarjeta'] != null
          ? Map<String, dynamic>.from(json['tarjeta'])
          : null, // 🔹 recupera si existe
    );
  }

  /// 🔁 Convierte hacia Firestore
  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'nitDpi': nitDpi,
      'metodoPago': metodoPago,
      'estado': estado,
      'total': total,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'items': items.map((j) => j.toJson()).toList(),
      if (tarjeta != null) 'tarjeta': tarjeta, // 🔹 guarda si existe
    };
  }
}
