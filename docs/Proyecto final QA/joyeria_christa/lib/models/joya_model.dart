import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class Joya {
  final String id;
  final String nombre;
  final String imagen;
  final double precio;
  final String material;
  final double peso;
  final String tipo;
  final int cantidad;

  // 🔽 Nuevos campos
  final bool esOferta;
  final int descuento;
  final bool esTop;
  final bool esNuevo;
  final DateTime? fechaIngreso;

  const Joya({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.precio,
    required this.material,
    required this.peso,
    required this.tipo,
    this.cantidad = 1,
    this.esOferta = false,
    this.descuento = 0,
    this.esTop = false,
    this.esNuevo = false,
    this.fechaIngreso,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'imagen': imagen,
      'precio': precio,
      'material': material,
      'peso': peso,
      'tipo': tipo,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'esOferta': esOferta,
      'descuento': descuento,
      'esTop': esTop,
      'esNuevo': esNuevo,
      'fechaIngreso': fechaIngreso?.toIso8601String(),
    };
  }

  factory Joya.fromJson(Map<String, dynamic> map) {
    return Joya(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? 'Sin nombre',
      imagen: map['imagen'] ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      material: map['material'] ?? 'No especificado',
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      tipo: map['tipo'] ?? 'Sin tipo',
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
      esOferta: map['esOferta'] ?? false,
      descuento: (map['descuento'] as num?)?.toInt() ?? 0,
      esTop: map['esTop'] ?? false,
      esNuevo: map['esNuevo'] ?? false,
      fechaIngreso: map['fechaIngreso'] != null
          ? DateTime.tryParse(map['fechaIngreso'])
          : null,
    );
  }

  factory Joya.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Joya.fromJson({...data, 'id': doc.id});
  }

  Joya copyWith({
    String? id,
    String? nombre,
    String? imagen,
    double? precio,
    String? material,
    double? peso,
    String? tipo,
    int? cantidad,
    bool? esOferta,
    int? descuento,
    bool? esTop,
    bool? esNuevo,
    DateTime? fechaIngreso,
  }) {
    return Joya(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagen: imagen ?? this.imagen,
      precio: precio ?? this.precio,
      material: material ?? this.material,
      peso: peso ?? this.peso,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      esOferta: esOferta ?? this.esOferta,
      descuento: descuento ?? this.descuento,
      esTop: esTop ?? this.esTop,
      esNuevo: esNuevo ?? this.esNuevo,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
    );
  }
}
