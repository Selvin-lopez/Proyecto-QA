import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/pedido_service.dart';
import '../../models/pedido_estado.dart';
import 'package:printing/printing.dart';
import '../../services/factura_pdf_service.dart';

class PantallaMisPedidos extends StatelessWidget {
  const PantallaMisPedidos({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Debes iniciar sesión')));
    }

    final stream = FirebaseFirestore.instance
        .collection('pedidos')
        .where('usuarioId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.purple.shade100,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('Error al cargar pedidos'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aún no tienes pedidos'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();

              // Estado
              final est = estadoFromString(
                (d['estado'] ?? 'pendiente').toString(),
              );

              // Total robusto (num -> double)
              final totalVal = d['total'];
              final double total = totalVal is num ? totalVal.toDouble() : 0.0;

              // Fecha robusta
              DateTime? fecha;
              final rawFecha = d['fecha'];
              if (rawFecha is Timestamp) {
                fecha = rawFecha.toDate();
              } else if (rawFecha is String) {
                // por si en algún momento la guardaste como string ISO
                fecha = DateTime.tryParse(rawFecha);
              }

              // Método de pago
              final metodoPago = (d['metodoPago'] ?? '').toString();
              final pagoLabel = metodoPago == 'tarjeta'
                  ? 'Tarjeta'
                  : 'Efectivo';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(
                    context,
                    // Usa la ruta que ya definiste en tu app
                    '/pedidos/detalle',
                    arguments: doc.id,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedido ${doc.id.substring(0, 6).toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor(est).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          estadoLabel(est),
                          style: TextStyle(
                            color: estadoColor(est),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (fecha != null)
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
                      'Total: Q${total.toStringAsFixed(2)}',
                      'Pago: $pagoLabel',
                    ].join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'pdf') {
                        try {
                          final itemsRaw = (d['items'] as List?) ?? const [];
                          final items = itemsRaw
                              .map((e) => (e as Map).cast<String, dynamic>())
                              .toList();

                          final pedidoPdf = {
                            'nombre': d['nombre'] ?? '',
                            'telefono': d['telefono'] ?? '',
                            'correo': d['email'] ?? d['correo'] ?? '',
                            'direccion': d['direccion'] ?? '',
                            'nitDpi': d['nitDpi'] ?? '',
                            'metodoPago': metodoPago,
                            'tarjeta': d['tarjeta'],
                            'items': items,
                            'total': total,
                            'fecha': fecha ?? DateTime.now(),
                            'pedidoId': doc.id,
                          };

                          final bytes = await FacturaPdfService.generarFactura(
                            pedido: pedidoPdf,
                          );
                          await Printing.layoutPdf(
                            onLayout: (_) async => bytes,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo generar PDF: $e'),
                            ),
                          );
                        }
                      } else if (val == 'cancelar') {
                        try {
                          final ok = await PedidoService().cancelarMiPedido(
                            doc.id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Pedido cancelado'
                                    : 'No se pudo cancelar el pedido',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Text('Factura PDF'),
                      ),
                      if (est == PedidoEstado.pendiente)
                        const PopupMenuItem(
                          value: 'cancelar',
                          child: Text(
                            'Cancelar pedido',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
