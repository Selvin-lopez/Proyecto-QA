import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/pedido_service.dart';
import '../../services/factura_pdf_service.dart';
import '../../models/pedido_model.dart';

class PantallaDetallePedido extends StatelessWidget {
  const PantallaDetallePedido({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id == null || id is! String || id.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('ID de pedido no válido')),
      );
    }

    return FutureBuilder<Pedido>(
      future: PedidoService().obtenerPedidoPorId(id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData) {
          return const Scaffold(
            body: Center(child: Text('No se encontró el pedido')),
          );
        }

        final Pedido pedido = snap.data!;
        final items = pedido.items;
        final total = pedido.total;

        /// 🔹 Etiqueta de método de pago
        final pagoLabel =
            pedido.metodoPago == 'tarjeta' && pedido.tarjeta != null
            ? 'Tarjeta ${pedido.tarjeta?['brand'] ?? ''} •••• ${pedido.tarjeta?['last4'] ?? ''}'
            : pedido.metodoPago == 'paypal'
            ? 'PayPal (${pedido.email})'
            : 'Efectivo contra entrega';

        /// 🔹 Ver / imprimir PDF
        Future<void> _verImprimir() async {
          try {
            final pedidoPdf = {
              'nombre': pedido.nombre,
              'telefono': pedido.telefono,
              'correo': pedido.email,
              'direccion': pedido.direccion,
              'nitDpi': pedido.nitDpi,
              'metodoPago': pedido.metodoPago,
              'tarjeta': pedido.tarjeta,
              'items': items.map((j) => j.toJson()).toList(),
              'total': total,
              'fecha': pedido.fecha?.toIso8601String() ?? '',
            };
            final bytes = await FacturaPdfService.generarFactura(
              pedido: pedidoPdf,
            );
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          } catch (e) {
            _toast(context, 'No se pudo imprimir el PDF: $e');
          }
        }

        /// 🔹 Compartir PDF
        Future<void> _compartir() async {
          try {
            final pedidoPdf = {
              'nombre': pedido.nombre,
              'telefono': pedido.telefono,
              'correo': pedido.email,
              'direccion': pedido.direccion,
              'nitDpi': pedido.nitDpi,
              'metodoPago': pedido.metodoPago,
              'tarjeta': pedido.tarjeta,
              'items': items.map((j) => j.toJson()).toList(),
              'total': total,
              'fecha': pedido.fecha?.toIso8601String() ?? '',
            };
            final bytes = await FacturaPdfService.generarFactura(
              pedido: pedidoPdf,
            );
            await Printing.sharePdf(
              bytes: bytes,
              filename: 'factura_${pedido.id}.pdf',
            );
          } catch (e) {
            _toast(context, 'No se pudo compartir el PDF: $e');
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Pedido ${pedido.id}'),
            backgroundColor: Colors.purple.shade100,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Datos del pedido
                Text(
                  'Cliente: ${pedido.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Pago: $pagoLabel'),
                if (pedido.fecha != null) Text('Fecha: ${pedido.fecha}'),
                const Divider(height: 30),

                // 🔹 Lista de productos
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item.nombre),
                        subtitle: Text(
                          'x${item.cantidad} • Q${item.precio.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          'Q${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // 🔹 Botones de acciones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Ver / Imprimir'),
                        onPressed: _verImprimir,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Compartir PDF'),
                        onPressed: _compartir,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔹 Total
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: Q${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
