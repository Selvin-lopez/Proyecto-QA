import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/joya_model.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/carrito_provider.dart';

import '../products/detalle_joya_screen.dart';
import '../../theme/app_colors.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();
    final carrito = context.read<CarritoProvider>();
    final favoritos = favoritosProvider.favoritos;

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Favoritos ❤️"), centerTitle: true),
      body: favoritos.isEmpty
          ? const _EmptyFavoritos()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: favoritos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // ✅ Dos columnas
                  childAspectRatio: 0.65, // 🔥 Mejor proporción
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final joya = favoritos[index];
                  return _FavoritoCard(
                    joya: joya,
                    onVerDetalle: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleJoyaScreen(joya: joya),
                        ),
                      );
                    },
                    onAgregarCarrito: () {
                      carrito.agregarProducto(joya.copyWith(cantidad: 1));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${joya.nombre} agregado al carrito'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                    },
                    onEliminar: () {
                      favoritosProvider.quitarFavorito(joya.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${joya.nombre} eliminado de favoritos',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _FavoritoCard extends StatelessWidget {
  final Joya joya;
  final VoidCallback onVerDetalle;
  final VoidCallback onAgregarCarrito;
  final VoidCallback onEliminar;

  const _FavoritoCard({
    required this.joya,
    required this.onVerDetalle,
    required this.onAgregarCarrito,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVerDetalle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen ocupa la parte superior
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: joya.imagen,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 40),
              ),
            ),

            // Información (nombre + precio + botones)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    joya.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Q${joya.precio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AccionBoton(
                        icon: Icons.shopping_cart,
                        color: Colors.purple,
                        onPressed: onAgregarCarrito,
                        tooltip: "Agregar al carrito",
                      ),
                      _AccionBoton(
                        icon: Icons.delete,
                        color: Colors.redAccent,
                        onPressed: onEliminar,
                        tooltip: "Quitar de favoritos",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de acción redondeado para consistencia visual
class _AccionBoton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  const _AccionBoton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _EmptyFavoritos extends StatelessWidget {
  const _EmptyFavoritos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Aún no tienes favoritos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Explora las joyas y agrega las que más te gusten ❤️",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
