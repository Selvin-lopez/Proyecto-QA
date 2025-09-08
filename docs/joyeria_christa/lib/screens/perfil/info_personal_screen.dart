import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      _nombre.text = (p['nombre'] ?? '') as String;
      _telefono.text = (p['telefono'] ?? '') as String? ?? '';
      _documento.text = (p['documento'] ?? '') as String? ?? '';
      _direccion.text = (p['direccion'] ?? '') as String? ?? '';
      _nitDpi.text = (p['nitDpi'] ?? '') as String? ?? '';

      final rawGenero = (p['genero'] ?? '') as String?;
      if (['M', 'F', 'O'].contains(rawGenero)) {
        _genero = rawGenero;
      } else {
        _genero = null;
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
    final service = context.read<PerfilService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Información personal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccion,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nitDpi,
              decoration: const InputDecoration(
                labelText: 'NIT o número de DPI',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: ['M', 'F', 'O'].contains(_genero) ? _genero : null,
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
            TextFormField(
              controller: _documento,
              decoration: const InputDecoration(
                labelText: 'Documento (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: Text(
                _fechaNac == null
                    ? 'Fecha de nacimiento'
                    : _fechaNac!.toString().split(' ').first,
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
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
}
