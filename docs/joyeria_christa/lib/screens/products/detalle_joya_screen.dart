import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/joya_model.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/favoritos_provider.dart'; // 🔹 Nuevo provider

class DetalleJoyaScreen extends StatelessWidget {
  final Joya joya;

  const DetalleJoyaScreen({super.key, required this.joya});

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CarritoProvider>();
    final favoritos = context.watch<FavoritosProvider>(); // 🔹 Observa cambios
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final esFavorito = favoritos.esFavorito(joya.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          joya.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_border,
              color: Colors.purple,
            ),
            onPressed: () {
              if (esFavorito) {
                favoritos.quitarFavorito(joya.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${joya.nombre} quitado de favoritos'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                favoritos.agregarFavorito(joya);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${joya.nombre} agregado a favoritos'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🖼 Imagen con Hero + zoom interactivo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Hero(
                tag: joya.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    clipBehavior: Clip.none,
                    panEnabled: true,
                    minScale: 1,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: joya.imagen,
                      height: size.width * 0.65,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(
                        height: size.width * 0.65,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                ),
              ),
            ),
            // 📋 Detalles de la joya
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    joya.nombre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Q${joya.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  _detalle("Material", joya.material),
                  _detalle("Peso", "${joya.peso.toStringAsFixed(2)} g"),
                  _detalle("Tipo", joya.tipo),
                  _detalle(
                    "Cantidad disponible",
                    "${joya.cantidad} unidad(es)",
                  ),
                  const SizedBox(height: 32),
                  // 🛒 Botón agregar al carrito
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text("Agregar al carrito"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        carrito.agregarProducto(joya.copyWith(cantidad: 1));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${joya.nombre} agregado al carrito'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
