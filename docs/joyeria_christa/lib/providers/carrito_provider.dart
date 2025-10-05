import 'package:flutter/foundation.dart';
//import '../models/joya.dart'; // 👈 Asegúrate de que apunta bien
import '../models/joya_model.dart';

class CarritoProvider extends ChangeNotifier {
  final List<Joya> _productos = [];

  List<Joya> get productos => List.unmodifiable(_productos);

  double get total => _productos.fold(0.0, (suma, j) => suma + j.subtotal);

  int get totalProductos => _productos.fold(0, (suma, j) => suma + j.cantidad);

  bool contiene(String id) => _productos.any((j) => j.id == id);

  void agregarProducto(Joya nueva) {
    final idx = _productos.indexWhere((j) => j.id == nueva.id);
    if (idx >= 0) {
      _productos[idx] = _productos[idx].copyWith(
        cantidad: _productos[idx].cantidad + nueva.cantidad,
      );
    } else {
      _productos.add(nueva);
    }

    _productos.sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();
  }

  void incrementar(String id) {
    final i = _productos.indexWhere((j) => j.id == id);
    if (i >= 0) {
      _productos[i] = _productos[i].copyWith(
        cantidad: _productos[i].cantidad + 1,
      );
      notifyListeners();
    }
  }

  void decrementar(String id) {
    final i = _productos.indexWhere((j) => j.id == id);
    if (i >= 0) {
      final actual = _productos[i];
      if (actual.cantidad > 1) {
        _productos[i] = actual.copyWith(cantidad: actual.cantidad - 1);
      } else {
        _productos.removeAt(i);
      }
      notifyListeners();
    }
  }

  void removerProducto(Joya joya) {
    _productos.removeWhere((j) => j.id == joya.id);
    notifyListeners();
  }

  void limpiarCarrito() {
    _productos.clear();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (kDebugMode) {
      print('[CarritoProvider] Joyas en carrito:');
      for (final j in _productos) {
        print('- ${j.toString()}');
      }
    }
    super.notifyListeners();
  }
}
