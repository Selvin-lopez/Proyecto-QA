import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/perfil_provider.dart';
import '../../providers/tema_provider.dart';
import '../auth/login_screen.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PerfilProvider>().init());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final prov = context.read<PerfilProvider>();
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 85);
    if (img != null) {
      await prov.actualizarFoto(File(img.path));
      if (prov.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(prov.error!)),
        );
      }
    }
  }

  Future<void> _seleccionarFoto() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _calcularProgreso(Map<String, dynamic> p) {
    int total = 4, ok = 0;
    if ((p['nombre'] ?? '').toString().trim().isNotEmpty) ok++;
    if ((p['fotoUrl'] ?? '').toString().trim().isNotEmpty) ok++;
    if ((p['email'] ?? '').toString().trim().isNotEmpty) ok++;
    final user = FirebaseAuth.instance.currentUser;
    if ((user?.emailVerified ?? false)) ok++;
    return ok / total;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PerfilProvider>();
    final tema = context.watch<TemaProvider>();
    final p = prov.perfil;
    final cs = Theme.of(context).colorScheme;

    final nombreActual = (p?['nombre'] ?? '').toString();
    final nombreIngresado = _nombreCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: prov.cargando
          ? const Center(child: CircularProgressIndicator())
          : p == null
          ? const Center(child: Text('No se pudo cargar el perfil'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== Header =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _seleccionarFoto,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage:
                                (p['fotoUrl'] != null &&
                                    p['fotoUrl'].toString().isNotEmpty)
                                ? NetworkImage(p['fotoUrl'])
                                : null,
                            child:
                                (p['fotoUrl'] == null ||
                                    p['fotoUrl'].toString().isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: cs.onPrimary,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p['nombre'] ?? 'Usuario',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                        ),
                        Text(
                          p['email'] ?? '',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: cs.onPrimary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Progreso =====
                  _BloqueCard(
                    titulo: 'Progreso del perfil',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _calcularProgreso(p),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(10),
                          color: cs.primary,
                          backgroundColor: cs.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Completa los pasos para mejorar tu experiencia',
                        ),
                      ],
                    ),
                  ),

                  // ===== Nombre =====
                  _BloqueCard(
                    titulo: 'Nombre',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nombreCtrl..text = p['nombre'] ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar nombre'),
                          onPressed:
                              (nombreIngresado.isEmpty ||
                                  nombreIngresado == nombreActual)
                              ? null
                              : () async {
                                  await prov.actualizarNombre(
                                    _nombreCtrl.text.trim(),
                                  );
                                  final msg = prov.error == null
                                      ? 'Nombre actualizado'
                                      : prov.error!;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: prov.error == null
                                            ? Colors.green
                                            : Colors.red,
                                        content: Text(msg),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),

                  // ===== Seguridad =====
                  _BloqueCard(
                    titulo: 'Seguridad',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: Icon(Icons.lock_reset),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: cs.primary),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Cambiar contraseña'),
                          onPressed: () async {
                            final nueva = _passCtrl.text.trim();
                            if (nueva.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    'La contraseña debe tener al menos 6 caracteres',
                                  ),
                                ),
                              );
                              return;
                            }
                            await prov.cambiarPassword(nueva);
                            final msg = prov.error == null
                                ? 'Contraseña actualizada'
                                : prov.error!;
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: prov.error == null
                                      ? Colors.green
                                      : Colors.red,
                                  content: Text(msg),
                                ),
                              );
                            }
                            _passCtrl.clear();
                          },
                        ),
                      ],
                    ),
                  ),

                  // ===== Apariencia =====
                  _BloqueCard(
                    titulo: 'Apariencia',
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: tema.oscuro,
                          title: const Text('Tema oscuro'),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          onChanged: (v) => tema.setOscuro(v),
                        ),
                        ListTile(
                          leading: CircleAvatar(backgroundColor: tema.seed),
                          title: const Text('Cambiar color'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final nuevo = await _mostrarColorPicker(
                              context,
                              tema.seed,
                            );
                            if (nuevo != null) {
                              await tema.setSeed(nuevo);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // ===== Perfil =====
                  _BloqueCard(
                    titulo: 'Perfil',
                    child: Column(
                      children: [
                        _tile(
                          context,
                          Icons.person_outline,
                          'Información personal',
                          () => Navigator.pushNamed(context, '/perfil/info'),
                        ),
                        _tile(
                          context,
                          Icons.favorite_border,
                          'Favoritos',
                          () =>
                              Navigator.pushNamed(context, '/perfil/favoritos'),
                        ),
                      ],
                    ),
                  ),

                  // ===== Configuración =====
                  _BloqueCard(
                    titulo: 'Configuración',
                    child: Column(
                      children: [
                        _tile(
                          context,
                          Icons.notifications_none,
                          'Notificaciones',
                          () => Navigator.pushNamed(
                            context,
                            '/perfil/notificaciones',
                          ),
                        ),
                        _tile(context, Icons.info_outline, 'Información legal', () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Información legal'),
                              content: const Text(
                                'Esta aplicación es un proyecto académico.\n\n'
                                'Los datos de usuario se manejan únicamente con fines demostrativos.\n\n'
                                'No representa una plataforma comercial real.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Cerrar sesión =====
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    onPressed: () async {
                      await prov.cerrarSesion();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  ListTile _tile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<Color?> _mostrarColorPicker(BuildContext context, Color actual) async {
    Color seleccionado = actual;
    return showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Selecciona un color'),
          content: Material(
            child: ColorPicker(
              pickerColor: seleccionado,
              onColorChanged: (c) => seleccionado = c,
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(seleccionado),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}

// ======== Card contenedora reutilizable ========
class _BloqueCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _BloqueCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
