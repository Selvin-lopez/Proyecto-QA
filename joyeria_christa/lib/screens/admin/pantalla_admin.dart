import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  // ========== JOYAS ==========
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _descuentoCtrl = TextEditingController();

  final _db = FirebaseFirestore.instance;
  String? _editingId;

  bool _esOferta = false;
  bool _esTop = false;
  bool _esNuevo = true;

  Future<void> _guardarJoya() async {
    if (!_formKey.currentState!.validate()) return;

    final joya = {
      'nombre': _nombreCtrl.text.trim(),
      'precio': double.tryParse(_precioCtrl.text.trim()) ?? 0.0,
      'imagen': _imagenCtrl.text.trim(),
      'material': _materialCtrl.text.trim(),
      'peso': double.tryParse(_pesoCtrl.text.trim()) ?? 0.0,
      'tipo': _tipoCtrl.text.trim(),
      'cantidad': int.tryParse(_cantidadCtrl.text.trim()) ?? 1,
      'descuento': int.tryParse(_descuentoCtrl.text.trim()) ?? 0,
      'esOferta': _esOferta,
      'esTop': _esTop,
      'esNuevo': _esNuevo,
    };

    try {
      if (_editingId == null) {
        await _db.collection('joyas').add({
          ...joya,
          'fechaIngreso': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Joya agregada con éxito")),
        );
      } else {
        await _db.collection('joyas').doc(_editingId).update({
          ...joya,
          'fechaActualizacion': DateTime.now().toIso8601String(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Joya actualizada con éxito")),
        );
      }
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error al guardar: $e")));
    }
  }

  void _resetForm() {
    _editingId = null;
    _nombreCtrl.clear();
    _precioCtrl.clear();
    _imagenCtrl.clear();
    _materialCtrl.clear();
    _pesoCtrl.clear();
    _tipoCtrl.clear();
    _cantidadCtrl.clear();
    _descuentoCtrl.clear();
    _esOferta = false;
    _esTop = false;
    _esNuevo = true;
    setState(() {});
  }

  Future<void> _eliminarJoya(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar Joya"),
        content: const Text("¿Seguro que deseas eliminar esta joya?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _db.collection('joyas').doc(id).delete();
    }
  }

  // ========== PEDIDOS (helpers robustos para Web) ==========

  /// Evita el bug en Web: usa set(merge:true) y filtra nulos.
  Future<void> _safeUpdate(
    String pedidoId,
    Map<String, dynamic> changes,
  ) async {
    // limpia nulos y strings vacíos
    changes.removeWhere((k, v) => v == null);
    await _db
        .collection('pedidos')
        .doc(pedidoId)
        .set(changes, SetOptions(merge: true));
  }

  String _formatFecha(dynamic v) {
    try {
      if (v is Timestamp)
        return v.toDate().toString(); // puedes formatear con intl si quieres
      if (v is DateTime) return v.toString();
      if (v is String) return v;
    } catch (_) {}
    return '';
  }

  Color _estadoColor(String? estado) {
    switch ((estado ?? 'pendiente').toLowerCase()) {
      case 'asignado':
        return Colors.deepPurple;
      case 'en camino':
        return Colors.orange;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cambiarEstado(String pedidoId, String nuevo) async {
    try {
      await _safeUpdate(pedidoId, {
        'estado': nuevo,
        'fechaCambioEstado': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Estado actualizado a $nuevo")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al actualizar estado: $e")),
      );
    }
  }

  Future<void> _asignarRepartidor(String pedidoId) async {
    String? repartidorSeleccionado; // uid o nombre
    final manualCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Asignar Repartidor"),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lista de usuarios con rol 'repartidor'
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('usuarios')
                      .where('rol', isEqualTo: 'repartidor')
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (docs.isEmpty) {
                      return const Text(
                        "No hay repartidores registrados.\nPuedes asignar uno manualmente abajo.",
                        textAlign: TextAlign.center,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final nombre =
                            (data['nombre'] ?? data['email'] ?? 'Sin nombre')
                                .toString();
                        return RadioListTile<String>(
                          title: Text(nombre),
                          value: nombre, // o usa d.id si prefieres uid
                          groupValue: repartidorSeleccionado,
                          onChanged: (v) {
                            repartidorSeleccionado = v;
                            // fuerza rebuild del AlertDialog
                            (context as Element).markNeedsBuild();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                TextField(
                  controller: manualCtrl,
                  decoration: const InputDecoration(
                    labelText: "Asignar manualmente (nombre)",
                    helperText: "Si no hay repartidores registrados",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Asignar"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final elegido = (repartidorSeleccionado ?? manualCtrl.text.trim());
    if (elegido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Debes seleccionar o escribir un repartidor."),
        ),
      );
      return;
    }

    try {
      await _safeUpdate(pedidoId, {
        'repartidor': elegido,
        'estado': 'Asignado',
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Repartidor '$elegido' asignado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al asignar repartidor: $e")),
      );
    }
  }

  Future<void> _crearPedidoManual() async {
    final clienteCtrl = TextEditingController();
    final totalCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Crear pedido manual"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clienteCtrl,
              decoration: const InputDecoration(
                labelText: "Cliente (nombre o email)",
              ),
            ),
            TextField(
              controller: totalCtrl,
              decoration: const InputDecoration(labelText: "Total (Q)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Crear"),
          ),
        ],
      ),
    );

    if (ok == true) {
      final total = double.tryParse(totalCtrl.text.trim()) ?? 0.0;
      await _db.collection('pedidos').add({
        'cliente': clienteCtrl.text.trim(),
        'total': total,
        'estado': 'pendiente',
        'fecha': FieldValue.serverTimestamp(),
        'items': [], // opcional
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Pedido creado")));
    }
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return FutureBuilder<bool>(
      future: AuthService.instance.esAdmin(user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) {
          return const Scaffold(
            body: Center(
              child: Text("⚠️ Acceso denegado. Solo para administradores."),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Panel de Administración"),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.diamond), text: "Joyas"),
                  Tab(icon: Icon(Icons.local_shipping), text: "Pedidos"),
                ],
              ),
              actions: [
                if (_editingId != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _resetForm,
                    tooltip: "Cancelar edición",
                  ),
              ],
            ),
            body: TabBarView(
              children: [
                // ======== TAB JOYAS (tu código intacto) ========
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: "Nombre",
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? "Campo requerido" : null,
                            ),
                            TextFormField(
                              controller: _precioCtrl,
                              decoration: const InputDecoration(
                                labelText: "Precio",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            TextFormField(
                              controller: _imagenCtrl,
                              decoration: const InputDecoration(
                                labelText: "URL Imagen",
                              ),
                            ),
                            TextFormField(
                              controller: _materialCtrl,
                              decoration: const InputDecoration(
                                labelText: "Material",
                              ),
                            ),
                            TextFormField(
                              controller: _pesoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Peso (gr)",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            TextFormField(
                              controller: _tipoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Tipo",
                              ),
                            ),
                            TextFormField(
                              controller: _cantidadCtrl,
                              decoration: const InputDecoration(
                                labelText: "Cantidad",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            TextFormField(
                              controller: _descuentoCtrl,
                              decoration: const InputDecoration(
                                labelText: "Descuento (%)",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              title: const Text("¿Es Oferta?"),
                              value: _esOferta,
                              onChanged: (v) => setState(() => _esOferta = v),
                            ),
                            SwitchListTile(
                              title: const Text("¿Es Top?"),
                              value: _esTop,
                              onChanged: (v) => setState(() => _esTop = v),
                            ),
                            SwitchListTile(
                              title: const Text("¿Es Nuevo?"),
                              value: _esNuevo,
                              onChanged: (v) => setState(() => _esNuevo = v),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _guardarJoya,
                              child: Text(
                                _editingId == null
                                    ? "Agregar Joya"
                                    : "Actualizar Joya",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _db.collection('joyas').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error al cargar joyas"),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text("No hay joyas registradas"),
                            );
                          }
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final joya =
                                  docs[i].data() as Map<String, dynamic>;
                              final id = docs[i].id;

                              return ListTile(
                                leading: Image.network(
                                  joya['imagen'] ?? '',
                                  width: 50,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                                title: Text(joya['nombre'] ?? 'Sin nombre'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Q ${joya['precio']}"),
                                    if (joya['fechaIngreso'] != null)
                                      Text("Ingreso: ${joya['fechaIngreso']}"),
                                    if (joya['fechaActualizacion'] != null)
                                      Text(
                                        "Última edición: ${joya['fechaActualizacion']}",
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        _editingId = id;
                                        _nombreCtrl.text = joya['nombre'] ?? '';
                                        _precioCtrl.text =
                                            (joya['precio'] ?? '').toString();
                                        _imagenCtrl.text = joya['imagen'] ?? '';
                                        _materialCtrl.text =
                                            joya['material'] ?? '';
                                        _pesoCtrl.text = (joya['peso'] ?? '')
                                            .toString();
                                        _tipoCtrl.text = joya['tipo'] ?? '';
                                        _cantidadCtrl.text =
                                            (joya['cantidad'] ?? 1).toString();
                                        _descuentoCtrl.text =
                                            (joya['descuento'] ?? 0).toString();
                                        _esOferta = joya['esOferta'] ?? false;
                                        _esTop = joya['esTop'] ?? false;
                                        _esNuevo = joya['esNuevo'] ?? true;
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _eliminarJoya(id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // ======== TAB PEDIDOS (nuevo) ========
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Crear pedido manual"),
                          onPressed: _crearPedidoManual,
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('pedidos')
                            .orderBy('fecha', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error al cargar pedidos"),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text("No hay pedidos registrados"),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final d = docs[i];
                              final pedido = d.data() as Map<String, dynamic>;
                              final id = d.id;

                              final cliente = (pedido['cliente'] ?? '')
                                  .toString();
                              final estado = (pedido['estado'] ?? 'pendiente')
                                  .toString();
                              final fecha = _formatFecha(pedido['fecha']);
                              final repartidor = (pedido['repartidor'] ?? '')
                                  .toString();

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  title: Text("Pedido #$id"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Cliente: $cliente"),
                                      Row(
                                        children: [
                                          Text("Estado: "),
                                          Chip(
                                            label: Text(estado),
                                            backgroundColor: _estadoColor(
                                              estado,
                                            ).withOpacity(0.15),
                                            labelStyle: TextStyle(
                                              color: _estadoColor(estado),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.edit),
                                            tooltip: "Cambiar estado",
                                            onSelected: (v) =>
                                                _cambiarEstado(id, v),
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'pendiente',
                                                child: Text('Pendiente'),
                                              ),
                                              PopupMenuItem(
                                                value: 'Asignado',
                                                child: Text('Asignado'),
                                              ),
                                              PopupMenuItem(
                                                value: 'En camino',
                                                child: Text('En camino'),
                                              ),
                                              PopupMenuItem(
                                                value: 'Entregado',
                                                child: Text('Entregado'),
                                              ),
                                              PopupMenuItem(
                                                value: 'Cancelado',
                                                child: Text('Cancelado'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (repartidor.isNotEmpty)
                                        Text("Repartidor: $repartidor"),
                                      if (fecha.isNotEmpty)
                                        Text("Fecha: $fecha"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.person_add,
                                      color: Colors.green,
                                    ),
                                    tooltip: "Asignar repartidor",
                                    onPressed: () => _asignarRepartidor(id),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
