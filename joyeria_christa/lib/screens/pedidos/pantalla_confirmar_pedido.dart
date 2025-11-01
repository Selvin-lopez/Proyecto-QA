import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../providers/carrito_provider.dart';
import '../../services/pedido_service.dart';
import '../../services/factura_pdf_service.dart';

class PantallaConfirmarPedido extends StatelessWidget {
  const PantallaConfirmarPedido({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return _errorScaffold(
        context,
        'No se recibieron datos para confirmar el pedido.',
      );
    }

    final Map<String, dynamic> datos = Map<String, dynamic>.from(args);

    // Datos de entrega
    final nombre = (datos['nombre'] ?? '').toString();
    final telefono = (datos['telefono'] ?? '').toString();
    final correo = (datos['correo'] ?? '').toString();
    final direccion = (datos['direccion'] ?? '').toString();
    final nit = (datos['nitDpi'] ?? '').toString();
    final metodoPago = (datos['metodoPago'] ?? '').toString();

    final fecha = DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now());

    // 🔹 Datos de tarjeta (si existen)
    final tarjeta = (datos['tarjeta'] is Map<String, dynamic>)
        ? (datos['tarjeta'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final pago = metodoPago == 'tarjeta'
        ? 'Tarjeta ${tarjeta['brand'] ?? ''} •••• ${tarjeta['last4'] ?? ''}'
        : metodoPago == 'paypal'
        ? 'PayPal ($correo)'
        : 'Efectivo contra entrega';

    final carrito = context.watch<CarritoProvider>();

    /// 🔧 Generar bytes de la factura PDF
    Future<Uint8List> _generarFacturaBytes() async {
      return await FacturaPdfService.generarFactura(
        pedido: {
          ...datos,
          'items': carrito.productos.map((j) => j.toJson()).toList(),
          'total': carrito.total,
          'fecha': DateTime.now().toIso8601String(),
        },
      );
    }

    /// 🔧 Confirmar pedido
    Future<void> _confirmar() async {
      if (carrito.productos.isEmpty) {
        _toast(context, 'El carrito está vacío');
        return;
      }

      try {
        final pedidoId = await PedidoService().crearPedido(
          joyas: carrito.productos,
          metodoPago: metodoPago,
          datosEntrega: {
            'nombre': nombre,
            'telefono': telefono,
            'correo': correo,
            'direccion': direccion,
            'nitDpi': nit,
          },
          tarjeta: tarjeta.isNotEmpty ? tarjeta : null,
        );

        if (!context.mounted) return;

        if (pedidoId != null && pedidoId.isNotEmpty) {
          carrito.limpiarCarrito();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pedido-exito',
            (route) => false,
            arguments: pedidoId,
          );
        } else {
          _toast(context, 'No se pudo crear el pedido');
        }
      } catch (e) {
        if (context.mounted) {
          _toast(context, 'Error al crear el pedido: $e');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación de Pedido'),
        backgroundColor: Colors.purple.shade100,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ ¡Pedido listo para confirmar!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text('🧾 Resumen', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 30),
            _infoRow('🗓 Fecha:', fecha),
            _infoRow('👤 Cliente:', nombre),
            _infoRow('🆔 NIT/DPI:', nit),
            _infoRow('📧 Correo:', correo),
            _infoRow('📱 Teléfono:', telefono),
            _infoRow('📍 Dirección:', direccion),
            _infoRow('💳 Pago:', pago),
            const SizedBox(height: 16),

            const Spacer(),

            // Confirmar pedido
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirmar y crear pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _confirmar,
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
              onPressed: () =>
                  Navigator.popUntil(context, ModalRoute.withName('/')),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers =====

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(child: Text((value ?? '').toString())),
        ],
      ),
    );
  }

  Scaffold _errorScaffold(BuildContext context, String msg) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Pedido')),
      body: Center(child: Text(msg)),
    );
  }
}
