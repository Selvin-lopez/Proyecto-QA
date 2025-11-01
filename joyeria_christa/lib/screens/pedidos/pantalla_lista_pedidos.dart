import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PantallaListaPedidos extends StatelessWidget {
  const PantallaListaPedidos({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver tus pedidos.')),
      );
    }

    final pedidosQuery = FirebaseFirestore.instance
        .collection('pedidos')
        .where('usuarioId', isEqualTo: usuario.uid)
        .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pedidosQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar pedidos.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has realizado pedidos.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final id = doc.id;

              // 🔹 Lectura segura
              final totalRaw = data['total'];
              final estado =
                  data['estado']?.toString().toLowerCase() ?? 'pendiente';
              final metodoPago =
                  data['metodoPago']?.toString().toLowerCase() ?? 'desconocido';
              final fecha = (data['fecha'] is Timestamp)
                  ? (data['fecha'] as Timestamp).toDate()
                  : null;

              final total = (totalRaw is num)
                  ? totalRaw.toDouble()
                  : double.tryParse(totalRaw.toString()) ?? 0.0;

              // 🔹 Mostrar método de pago detallado
              String pagoLabel;
              if (metodoPago == 'tarjeta' && data['tarjeta'] != null) {
                final tarjeta = Map<String, dynamic>.from(data['tarjeta']);
                pagoLabel =
                    "Tarjeta ${tarjeta['brand'] ?? ''} •••• ${tarjeta['last4'] ?? ''}";
              } else if (metodoPago == 'paypal') {
                pagoLabel = "PayPal (${data['correo'] ?? ''})";
              } else {
                pagoLabel = "Efectivo 💵";
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detalle-pedido',
                      arguments: id,
                    );
                  },
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    'Pedido #${id.substring(0, 6).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fecha != null)
                        Text(
                          DateFormat('dd/MM/yyyy – HH:mm').format(fecha),
                          style: const TextStyle(fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              estado.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _colorEstado(estado),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              pagoLabel,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    'Q${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🌈 Colores de estado
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return Colors.green;
      case 'enviado':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
