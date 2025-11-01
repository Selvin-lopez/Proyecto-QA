import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/carrito_provider.dart';
import '../../helpers/ir_al_checkout.dart'; // ✅ Importamos la función nueva

class PantallaCarrito extends StatelessWidget {
  const PantallaCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = Provider.of<CarritoProvider>(context);
    final productos = carrito.productos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Carrito'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Vaciar carrito',
            onPressed: productos.isEmpty
                ? null
                : () {
                    carrito.limpiarCarrito();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Carrito vaciado')),
                    );
                  },
          ),
        ],
      ),
      body: productos.isEmpty
          ? _CarritoVacio()
          : _CarritoConProductos(carrito: carrito),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CarritoConProductos extends StatelessWidget {
  final CarritoProvider carrito;

  const _CarritoConProductos({required this.carrito});

  @override
  Widget build(BuildContext context) {
    final productos = carrito.productos;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final producto = productos[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        _ImagenProducto(producto.imagen),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoProducto(producto)),
                        _ControlesCantidad(
                          carrito: carrito,
                          producto: producto,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a pagar:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                '\$${carrito.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Proceder al pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: productos.isEmpty ? null : () => irAlCheckout(context),
          ),
        ],
      ),
    );
  }
}

class _ImagenProducto extends StatelessWidget {
  final String imagen;
  const _ImagenProducto(this.imagen);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imagen,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
        ),
      ),
    );
  }
}

class _InfoProducto extends StatelessWidget {
  final dynamic producto;
  const _InfoProducto(this.producto);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(
          '\$${producto.precio.toStringAsFixed(2)} c/u',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          'Subtotal: \$${(producto.precio * producto.cantidad).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}

class _ControlesCantidad extends StatelessWidget {
  final CarritoProvider carrito;
  final dynamic producto;
  const _ControlesCantidad({required this.carrito, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () => carrito.decrementar(producto.id),
              color: Colors.purple,
            ),
            Text(
              '${producto.cantidad}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => carrito.incrementar(producto.id),
              color: Colors.purple,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => carrito.removerProducto(producto),
        ),
      ],
    );
  }
}
