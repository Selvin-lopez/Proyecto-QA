import 'package:flutter/material.dart';

class PantallaPedidoExito extends StatelessWidget {
  const PantallaPedidoExito({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Intentamos recibir el ID del pedido desde argumentos
    final pedidoId = ModalRoute.of(context)?.settings.arguments as String?;

    return WillPopScope(
      onWillPop: () async => false, // 🚫 Bloquea retroceso físico
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Pedido confirmado'),
          centerTitle: true,
          backgroundColor: Colors.green.shade600,
          automaticallyImplyLeading: false, // 🚫 evita botón back en AppBar
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // ✅ Icono de confirmación (puedes reemplazar por animación Lottie)
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 24),

              const Text(
                '¡Gracias por tu compra!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Tu pedido fue creado exitosamente 🎉\n'
                'Recibirás una notificación cuando esté en camino.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              if (pedidoId != null) ...[
                const SizedBox(height: 20),
                Text(
                  'ID de pedido: #${pedidoId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],

              const Spacer(),

              // 🔹 Botón "Ver mis pedidos"
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Ver mis pedidos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/mis-pedidos',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),

              // 🔹 Botón "Volver al inicio"
              OutlinedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: Colors.deepPurple.shade300,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
