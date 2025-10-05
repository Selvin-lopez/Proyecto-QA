// 📁 lib/screens/productos/products_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carrito_provider.dart';
import '../../models/joya_model.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productos = [
      const Joya(
        id: 'anillo1',
        nombre: 'Anillo de Oro',
        precio: 350.0,
        imagen: 'https://via.placeholder.com/300x200',
        material: 'Oro',
        peso: 5.5,
        tipo: 'Anillo',
        cantidad: 1,
      ),
      const Joya(
        id: 'collar1',
        nombre: 'Collar de Plata',
        precio: 220.0,
        imagen: 'https://via.placeholder.com/300x200',
        material: 'Plata',
        peso: 7.2,
        tipo: 'Collar',
        cantidad: 1,
      ),
      const Joya(
        id: 'pulsera1',
        nombre: 'Pulsera de Esmeralda',
        precio: 480.0,
        imagen: 'https://via.placeholder.com/300x200',
        material: 'Oro y Esmeralda',
        peso: 4.8,
        tipo: 'Pulsera',
        cantidad: 1,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Joyas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/carrito'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: productos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];
            return _ProductoCard(producto: producto);
          },
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Joya producto;

  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CarritoProvider>();
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              producto.imagen,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              producto.nombre,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '\$${producto.precio.toStringAsFixed(2)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Agregar a favoritos',
                  onPressed: () {
                    // TODO: implementar favoritos
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Agregar al carrito',
                  onPressed: () {
                    carrito.agregarProducto(producto); // ✅ Joya
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${producto.nombre} agregado al carrito'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
