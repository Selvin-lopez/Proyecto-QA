import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/carrito_provider.dart';
import '../../services/pedido_service.dart';
import '../../services/perfil_service.dart';

class ConfirmarPedidoScreen extends StatelessWidget {
  const ConfirmarPedidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pedido'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Deseas confirmar tu pedido?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmar pedido en efectivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmarPedido(context, carrito),
            ),
          ],
        ),
      ),
    );
  }

  /// 🛒 Lógica para crear el pedido
  Future<void> _confirmarPedido(
    BuildContext context,
    CarritoProvider carrito,
  ) async {
    if (carrito.productos.isEmpty) {
      _mostrarMensaje(context, 'Tu carrito está vacío', isError: true);
      return;
    }

    try {
      final perfilService = PerfilService();
      final datosEntrega = await perfilService.obtenerDatosEntrega();

      if (datosEntrega == null ||
          datosEntrega.values.any(
            (v) => v == null || v.toString().trim().isEmpty,
          )) {
        _mostrarMensaje(
          context,
          'Faltan datos de entrega en tu perfil. Por favor verifica tu información.',
          isError: true,
        );
        return;
      }

      // 🔄 Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // ✅ Crear pedido en Firestore
      final pedidoId = await PedidoService().crearPedido(
        joyas: carrito.productos,
        metodoPago: 'efectivo',
        datosEntrega: datosEntrega,
      );

      Navigator.pop(context); // 🔄 Cerrar el diálogo de carga

      if (pedidoId != null) {
        carrito.limpiarCarrito();

        _mostrarMensaje(context, '✅ Pedido creado correctamente');

        await Future.delayed(const Duration(milliseconds: 600));

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/pedido-exito',
          (route) => false,
        );
      } else {
        _mostrarMensaje(context, 'Error al crear el pedido', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // 🔄 Cerrar el diálogo en caso de error
      _mostrarMensaje(context, 'Hubo un error: $e', isError: true);
    }
  }

  /// 🔔 SnackBar de feedback
  void _mostrarMensaje(
    BuildContext context,
    String mensaje, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
