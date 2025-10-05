import 'package:flutter/material.dart';

class PantallaCheckout extends StatelessWidget {
  const PantallaCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text('⚠️ No se encontraron los datos de entrega')),
      );
    }

    final datosEntrega = Map<String, dynamic>.from(args);

    final opciones = [
      {
        'icono': Icons.attach_money,
        'titulo': 'Pago en efectivo contra entrega',
        'ruta': '/confirmar-pedido',
        'argumento': 'efectivo',
        'color': Colors.green,
      },
      {
        'icono': Icons.credit_card,
        'titulo': 'Pago con tarjeta de crédito o débito',
        'ruta': '/pago-tarjeta',
        'argumento': 'tarjeta',
        'color': Colors.deepPurple,
      },
      // 🔮 Ejemplo: futuro método PayPal
      // {
      //   'icono': Icons.account_balance_wallet,
      //   'titulo': 'Pago con PayPal',
      //   'ruta': '/pago-paypal',
      //   'argumento': 'paypal',
      //   'color': Colors.blue,
      // },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona método de pago'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==== Sección Información de entrega ====
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Información de entrega y facturación",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _datoResumenIcon(Icons.person, datosEntrega['nombre']),
                  _datoResumenIcon(Icons.phone, datosEntrega['telefono']),
                  _datoResumenIcon(Icons.email, datosEntrega['correo']),
                  _datoResumenIcon(Icons.home, datosEntrega['direccion']),
                  _datoResumenIcon(Icons.badge, datosEntrega['nitDpi']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==== Métodos de pago ====
          const Text(
            '💳 Selecciona método de pago:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...opciones.map(
            (opcion) => _OpcionPagoCard(
              icono: opcion['icono'] as IconData,
              titulo: opcion['titulo'] as String,
              ruta: opcion['ruta'] as String,
              metodoPago: opcion['argumento'] as String,
              datosEntrega: datosEntrega,
              color: opcion['color'] as Color,
            ),
          ),

          const SizedBox(height: 20),

          // ==== Botón para editar datos ====
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/formulario-entrega',
                arguments: datosEntrega,
              );
            },
            icon: const Icon(Icons.edit, color: Colors.pink),
            label: const Text(
              'Editar datos de entrega',
              style: TextStyle(color: Colors.pink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoResumenIcon(IconData icono, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor?.toString().trim().isNotEmpty == true
                  ? valor!
                  : 'No especificado',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionPagoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String ruta;
  final String metodoPago;
  final Map<String, dynamic> datosEntrega;
  final Color color;

  const _OpcionPagoCard({
    required this.icono,
    required this.titulo,
    required this.ruta,
    required this.metodoPago,
    required this.datosEntrega,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          final datosCompletos = {...datosEntrega, 'metodoPago': metodoPago};
          Navigator.pushNamed(context, ruta, arguments: datosCompletos);
        },
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icono, size: 32, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
