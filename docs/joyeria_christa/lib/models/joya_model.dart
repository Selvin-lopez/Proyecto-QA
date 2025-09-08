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

  const Joya({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.precio,
    required this.material,
    required this.peso,
    required this.tipo,
    this.cantidad = 1,
  });

  /// Calcula el subtotal de esta joya (precio x cantidad)
  double get subtotal => precio * cantidad;

  /// Convierte la joya a un mapa para Firestore o almacenamiento local
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
    };
  }

  /// Crea una joya desde un mapa (JSON / Firestore)
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
    );
  }

  /// Crea una joya desde un documento de Firestore
  factory Joya.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Joya.fromJson({...data, 'id': doc.id});
  }

  /// Para poder usar `copyWith` al modificar cantidad u otros campos
  Joya copyWith({
    String? id,
    String? nombre,
    String? imagen,
    double? precio,
    String? material,
    double? peso,
    String? tipo,
    int? cantidad,
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
    );
  }

  @override
  String toString() {
    return 'Joya($nombre x$cantidad, \$${subtotal.toStringAsFixed(2)})';
  }
}
