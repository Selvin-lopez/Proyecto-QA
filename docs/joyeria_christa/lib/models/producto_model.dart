class ProductoModel {
  final String id;
  final String nombre;
  final String imagen;
  final double precio;
  final int cantidad;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.precio,
    required this.cantidad,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      cantidad: json['cantidad'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'imagen': imagen,
      'precio': precio,
      'cantidad': cantidad,
    };
  }
}
