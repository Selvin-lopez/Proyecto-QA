import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/joya_model.dart';
import '../../providers/carrito_provider.dart';
import '../screens/products/detalle_joya_screen.dart';

class PantallaJoyasFirestore extends StatefulWidget {
  const PantallaJoyasFirestore({super.key});

  @override
  State<PantallaJoyasFirestore> createState() => _PantallaJoyasFirestoreState();
}

class _PantallaJoyasFirestoreState extends State<PantallaJoyasFirestore> {
  String _busqueda = '';
  String _filtroTipo = 'Todos';
  String _filtroMaterial = 'Todos';
  String _ordenPrecio = 'Ninguno';

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Joyas en venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: "Filtrar joyas",
            onPressed: _mostrarFiltros,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Ver carrito',
                onPressed: () => Navigator.pushNamed(context, '/carrito'),
              ),
              if (carrito.totalProductos > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${carrito.totalProductos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar joyas...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (valor) {
                setState(() => _busqueda = valor);
              },
            ),
          ),

          // 📋 Lista de joyas desde Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('joyas')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('❌ Error al cargar joyas'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay joyas disponibles 🪙',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                var joyas = docs
                    .map(
                      (doc) => Joya.fromSnapshot(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      ),
                    )
                    .toList();

                // === 🔎 Aplicar búsqueda ===
                joyas = joyas
                    .where(
                      (j) => j.nombre.toLowerCase().contains(
                        _busqueda.toLowerCase(),
                      ),
                    )
                    .toList();

                // === 🛠 Filtros ===
                if (_filtroTipo != 'Todos') {
                  joyas = joyas.where((j) => j.tipo == _filtroTipo).toList();
                }

                if (_filtroMaterial != 'Todos') {
                  joyas = joyas
                      .where((j) => j.material == _filtroMaterial)
                      .toList();
                }

                if (_ordenPrecio == 'Ascendente') {
                  joyas.sort((a, b) => a.precio.compareTo(b.precio));
                } else if (_ordenPrecio == 'Descendente') {
                  joyas.sort((a, b) => b.precio.compareTo(a.precio));
                }

                // === Mostrar en Grid ===
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: joyas.length,
                  itemBuilder: (context, index) {
                    final joya = joyas[index];
                    return _JoyaCard(joya: joya, carrito: carrito);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ BottomSheet de filtros
  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Filtros",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Tipo
                  DropdownButton<String>(
                    value: _filtroTipo,
                    items: ['Todos', 'Anillo', 'Collar', 'Aretes']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (valor) => setModal(() => _filtroTipo = valor!),
                  ),

                  // Material
                  DropdownButton<String>(
                    value: _filtroMaterial,
                    items: ['Todos', 'Oro', 'Plata', 'Acero']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (valor) =>
                        setModal(() => _filtroMaterial = valor!),
                  ),

                  // Precio
                  DropdownButton<String>(
                    value: _ordenPrecio,
                    items: ['Ninguno', 'Ascendente', 'Descendente']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (valor) => setModal(() => _ordenPrecio = valor!),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => setState(() {}));
  }
}

/// ===== Widget de tarjeta de joya =====
class _JoyaCard extends StatelessWidget {
  final Joya joya;
  final CarritoProvider carrito;

  const _JoyaCard({required this.joya, required this.carrito});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Precio con descuento si aplica
    double precioFinal = joya.precio;
    if (joya.esOferta && joya.descuento > 0) {
      precioFinal = joya.precio * (1 - (joya.descuento / 100));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleJoyaScreen(joya: joya)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con etiqueta
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: joya.imagen,
                      height: size.width * 0.45,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                  if (joya.esOferta || joya.esTop || joya.esNuevo)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: joya.esOferta
                              ? Colors.redAccent
                              : joya.esTop
                              ? Colors.deepPurple
                              : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          joya.esOferta
                              ? "OFERTA ${joya.descuento}%"
                              : joya.esTop
                              ? "TOP"
                              : "NUEVO",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Nombre y precio
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                joya.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: (joya.esOferta && joya.descuento > 0)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${joya.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '\$${precioFinal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '\$${joya.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            // Botón carrito
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  carrito.agregarProducto(joya);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${joya.nombre} agregado al carrito'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
