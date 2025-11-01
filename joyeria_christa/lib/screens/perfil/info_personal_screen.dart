import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../providers/perfil_provider.dart';
import '../../services/perfil_service.dart';

class InfoPersonalScreen extends StatefulWidget {
  const InfoPersonalScreen({super.key});

  @override
  State<InfoPersonalScreen> createState() => _InfoPersonalScreenState();
}

class _InfoPersonalScreenState extends State<InfoPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _documento = TextEditingController();
  final _direccion = TextEditingController();
  final _nitDpi = TextEditingController();

  DateTime? _fechaNac;
  String? _genero;

  @override
  void initState() {
    super.initState();
    final p = context.read<PerfilProvider>().perfil;
    if (p != null) {
      _nombre.text = (p['nombre'] ?? '').toString();
      _telefono.text = (p['telefono'] ?? '').toString();
      _documento.text = (p['documento'] ?? '').toString();
      _direccion.text = (p['direccion'] ?? '').toString();
      _nitDpi.text = (p['nitDpi'] ?? '').toString();

      final rawGenero = (p['genero'] ?? '').toString();
      if (['M', 'F', 'O'].contains(rawGenero)) {
        _genero = rawGenero;
      }

      final ts = p['fechaNacimiento'];
      if (ts is Timestamp) _fechaNac = ts.toDate();
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _documento.dispose();
    _direccion.dispose();
    _nitDpi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información personal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo(
              controller: _nombre,
              label: 'Nombre completo',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            _campo(
              controller: _telefono,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _campo(controller: _direccion, label: 'Dirección de entrega'),
            const SizedBox(height: 12),
            _campo(
              controller: _nitDpi,
              label: 'NIT o número de DPI',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _genero,
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                DropdownMenuItem(value: 'F', child: Text('Femenino')),
                DropdownMenuItem(
                  value: 'O',
                  child: Text('Otro / Prefiero no decir'),
                ),
              ],
              onChanged: (v) => setState(() => _genero = v),
              decoration: const InputDecoration(
                labelText: 'Género',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _campo(controller: _documento, label: 'Documento (opcional)'),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: Text(
                _fechaNac == null
                    ? 'Fecha de nacimiento'
                    : DateFormat('dd/MM/yyyy').format(_fechaNac!),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final hoy = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(hoy.year, hoy.month, hoy.day),
                  initialDate:
                      _fechaNac ?? DateTime(hoy.year - 18, hoy.month, hoy.day),
                );
                if (picked != null) setState(() => _fechaNac = picked);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  try {
                    final uid = context.read<PerfilService>().currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .set({
                            'nombre': _nombre.text.trim(),
                            'telefono': _telefono.text.trim(),
                            'documento': _documento.text.trim(),
                            'direccion': _direccion.text.trim(),
                            'nitDpi': _nitDpi.text.trim(),
                            'genero': _genero,
                            'fechaNacimiento': _fechaNac == null
                                ? null
                                : Timestamp.fromDate(_fechaNac!),
                            'actualizadoEn': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                      if (context.mounted) {
                        await context.read<PerfilProvider>().init();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Guardado')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
