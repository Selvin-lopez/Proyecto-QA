import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../services/pedido_service.dart';
import '../../services/factura_pdf_service.dart';
import '../../models/pedido_estado.dart';

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

              // Total robusto
              final totalRaw = d['total'];
              final double total = totalRaw is num ? totalRaw.toDouble() : 0.0;

              // Fecha
              DateTime? fecha;
              final rawFecha = d['fecha'];
              if (rawFecha is Timestamp) {
                fecha = rawFecha.toDate();
              } else if (rawFecha is String) {
                fecha = DateTime.tryParse(rawFecha);
              }

              // Método de pago
              final metodoPago = (d['metodoPago'] ?? '').toString();
              final pagoLabel = metodoPago == 'tarjeta'
                  ? 'Tarjeta ${d['tarjeta']?['brand'] ?? ''} •••• ${d['tarjeta']?['last4'] ?? ''}'
                  : metodoPago == 'paypal'
                  ? 'PayPal (${d['correo'] ?? ''})'
                  : 'Efectivo';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/pedidos/detalle',
                    arguments: doc.id,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedido ${doc.id.substring(0, 6).toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fecha != null)
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 14),
                            const SizedBox(width: 4),
                            Text('Q${total.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.credit_card, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pagoLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                        final confirmar =
                            await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancelar pedido'),
                                content: const Text(
                                  '¿Seguro que deseas cancelar este pedido?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Sí, cancelar'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirmar) {
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
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
