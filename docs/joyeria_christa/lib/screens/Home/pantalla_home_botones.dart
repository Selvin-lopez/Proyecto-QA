import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/carrito_provider.dart';
import '../../models/joya_model.dart';

class PantallaJoyasFirestore extends StatelessWidget {
  const PantallaJoyasFirestore({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = Provider.of<CarritoProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Joyas'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade100,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('joyas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar las joyas'));
          }

          final joyas = snapshot.data!.docs;

          if (joyas.isEmpty) {
            return const Center(child: Text('No hay joyas disponibles'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: joyas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final doc = joyas[index];
              final data = doc.data() as Map<String, dynamic>;

              final joya = Joya(
                id: doc.id,
                nombre: data['nombre'] ?? 'Sin nombre',
                precio: (data['precio'] ?? 0).toDouble(),
                imagen: data['imagen'] ?? '',
                material: data['material'] ?? 'Oro 18k',
                peso: (data['peso'] ?? 3.5).toDouble(),
                tipo: data['tipo'] ?? 'Anillo',
                cantidad: 1,
              );

              return CardJoya(
                joya: joya,
                onAdd: () {
                  carrito.agregarProducto(joya);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto agregado al carrito'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CardJoya extends StatelessWidget {
  final Joya joya;
  final VoidCallback onAdd;

  const CardJoya({super.key, required this.joya, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FadeInImage.assetNetwork(
              placeholder:
                  'assets/images/loading.gif', // o usa una imagen local
              image: joya.imagen,
              fit: BoxFit.cover,
              imageErrorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              joya.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '\$${joya.precio.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
