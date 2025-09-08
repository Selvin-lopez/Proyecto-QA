import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final favCol = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos');

    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: favCol.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No tienes productos favoritos.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final productoId = data['productoId'] ?? doc.id;
              final fecha = (data['createdAt'] as Timestamp?)?.toDate();
              final fechaTexto = fecha != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(fecha)
                  : 'Sin fecha';

              final nombre = data['nombre'] ?? 'Producto';
              final imagen = data['imagenUrl'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: imagen != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imagen,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 32,
                        ),
                  title: Text(nombre),
                  subtitle: Text('Agregado el $fechaTexto'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => favCol.doc(doc.id).delete(),
                  ),
                  onTap: () {
                    // 👇 Aquí podrías navegar al detalle del producto
                    // Navigator.pushNamed(context, '/detalle-producto', arguments: productoId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
