import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/perfil_service.dart';

class DireccionesScreen extends StatelessWidget {
  const DireccionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<PerfilService>(context, listen: false);
    final user = service.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('📍 Mis direcciones')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showUpsertDialog(context, service),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Agregar'),
            ),
      body: user == null
          ? const Center(child: Text('⚠️ Usuario no autenticado'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamDirecciones(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ocurrió un error al cargar las direcciones.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final direcciones = snapshot.data ?? [];

                if (direcciones.isEmpty) {
                  return const Center(
                    child: Text(
                      '📭 No hay direcciones guardadas.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: direcciones.length,
                  itemBuilder: (context, index) {
                    final dir = direcciones[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: dir['principal'] == true
                              ? Colors.amber[600]
                              : Colors.grey[300],
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (dir['etiqueta'] ?? 'Sin etiqueta').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (dir['principal'] == true)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Chip(
                                  label: Text(
                                    'Principal',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((dir['linea1'] ?? '').toString()),
                              if ((dir['linea2'] ?? '').toString().isNotEmpty)
                                Text(dir['linea2']),
                              Text(
                                [
                                  if ((dir['ciudad'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    dir['ciudad'],
                                  if ((dir['departamento'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    dir['departamento'],
                                ].join(', '),
                              ),
                              if ((dir['referencia'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text('Referencia: ${dir['referencia']}'),
                              if (dir['creadoEn'] is Timestamp)
                                Text(
                                  'Creado: ${(dir['creadoEn'] as Timestamp).toDate()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'editar') {
                              _showUpsertDialog(
                                context,
                                service,
                                direccion: dir,
                              );
                            } else if (value == 'principal') {
                              await service.upsertDireccion(
                                id: dir['id'],
                                etiqueta: dir['etiqueta'] ?? 'Sin etiqueta',
                                linea1: dir['linea1'] ?? '',
                                linea2: dir['linea2'],
                                ciudad: dir['ciudad'],
                                departamento: dir['departamento'],
                                referencia: dir['referencia'],
                                principal: true,
                              );
                            } else if (value == 'eliminar') {
                              await service.eliminarDireccion(dir['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                                dense: true,
                              ),
                            ),
                            if (dir['principal'] != true)
                              const PopupMenuItem(
                                value: 'principal',
                                child: ListTile(
                                  leading: Icon(Icons.star),
                                  title: Text('Marcar como principal'),
                                  dense: true,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Eliminar'),
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showUpsertDialog(
    BuildContext context,
    PerfilService service, {
    Map<String, dynamic>? direccion,
  }) {
    final etiquetaCtrl = TextEditingController(
      text: (direccion?['etiqueta'] ?? '').toString(),
    );
    final linea1Ctrl = TextEditingController(
      text: (direccion?['linea1'] ?? '').toString(),
    );
    final linea2Ctrl = TextEditingController(
      text: (direccion?['linea2'] ?? '').toString(),
    );
    final ciudadCtrl = TextEditingController(
      text: (direccion?['ciudad'] ?? '').toString(),
    );
    final deptoCtrl = TextEditingController(
      text: (direccion?['departamento'] ?? '').toString(),
    );
    final refCtrl = TextEditingController(
      text: (direccion?['referencia'] ?? '').toString(),
    );
    bool principal = (direccion?['principal'] ?? false) as bool;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                direccion == null ? 'Nueva dirección' : 'Editar dirección',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: etiquetaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Etiqueta (Casa, Trabajo...)',
                ),
              ),
              TextField(
                controller: linea1Ctrl,
                decoration: const InputDecoration(labelText: 'Línea 1'),
              ),
              TextField(
                controller: linea2Ctrl,
                decoration: const InputDecoration(labelText: 'Línea 2'),
              ),
              TextField(
                controller: ciudadCtrl,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              TextField(
                controller: deptoCtrl,
                decoration: const InputDecoration(labelText: 'Departamento'),
              ),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Referencia'),
              ),
              SwitchListTile(
                value: principal,
                onChanged: (v) => (principal = v),
                title: const Text('Marcar como principal'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await service.upsertDireccion(
                          id: direccion?['id'],
                          etiqueta: etiquetaCtrl.text.trim().isEmpty
                              ? 'Sin etiqueta'
                              : etiquetaCtrl.text.trim(),
                          linea1: linea1Ctrl.text.trim(),
                          linea2: linea2Ctrl.text.trim().isEmpty
                              ? null
                              : linea2Ctrl.text.trim(),
                          ciudad: ciudadCtrl.text.trim().isEmpty
                              ? null
                              : ciudadCtrl.text.trim(),
                          departamento: deptoCtrl.text.trim().isEmpty
                              ? null
                              : deptoCtrl.text.trim(),
                          referencia: refCtrl.text.trim().isEmpty
                              ? null
                              : refCtrl.text.trim(),
                          principal: principal,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
