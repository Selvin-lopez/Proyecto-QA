import 'package:flutter/material.dart';

class PantallaCheckout extends StatelessWidget {
  const PantallaCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    // Validación robusta de argumentos
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
      },
      {
        'icono': Icons.credit_card,
        'titulo': 'Pago con tarjeta de crédito o débito',
        'ruta': '/pago-tarjeta',
        'argumento': 'tarjeta',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona método de pago'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade100,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📦 Información de entrega y facturación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _datoResumen('👤 Nombre', datosEntrega['nombre']),
          _datoResumen('📞 Teléfono', datosEntrega['telefono']),
          _datoResumen('📧 Correo', datosEntrega['correo']),
          _datoResumen('📍 Dirección', datosEntrega['direccion']),
          _datoResumen('🆔 NIT/DPI', datosEntrega['nitDpi']),
          const SizedBox(height: 24),
          const Divider(),
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
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Editar datos de entrega'),
          ),
        ],
      ),
    );
  }

  Widget _datoResumen(String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Flexible(
            child: Text(
              (valor ?? 'No especificado'),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
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

  const _OpcionPagoCard({
    required this.icono,
    required this.titulo,
    required this.ruta,
    required this.metodoPago,
    required this.datosEntrega,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: Colors.deepPurple.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          final datosCompletos = {...datosEntrega, 'metodoPago': metodoPago};
          Navigator.pushNamed(context, ruta, arguments: datosCompletos);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icono, size: 32, color: Colors.deepPurple),
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
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
