import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/perfil_provider.dart';
import '../../providers/tema_provider.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(prov.error!)));
      }
    }
  }

  Future<void> _seleccionarFoto() async {
    // BottomSheet para elegir cámara/galería
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
              const SizedBox(height: 8),
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
    if ((user?.emailVerified ?? false)) ok++; // verificación de email
    return ok / total;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PerfilProvider>();
    final tema = context.watch<TemaProvider>();
    final p = prov.perfil;
    final cs = Theme.of(context).colorScheme;

    // Estado auxiliar para botón Guardar nombre
    final nombreActual = (p?['nombre'] ?? '').toString();
    final nombreIngresado = _nombreCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                  // =============== Banner de verificación de email ===============
                  Builder(
                    builder: (context) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && !(user.emailVerified)) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tu correo no está verificado. Verifica para completar tu perfil.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await user.sendEmailVerification();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enlace de verificación enviado',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Reenviar'),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // =================== Header ===================
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _seleccionarFoto,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: cs.primaryContainer,
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
                                    size: 48,
                                    color: cs.onPrimaryContainer,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p['nombre'] ?? 'Usuario',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['email'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================== Progreso ===================
                  _BloqueCard(
                    titulo: 'Completa tu perfil',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _calcularProgreso(p),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Completa los pasos para mejorar tu experiencia',
                        ),
                      ],
                    ),
                  ),

                  // =================== Editar nombre ===================
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
                          onChanged: (_) =>
                              setState(() {}), // para refrescar botón
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(msg)),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================== Cambiar contraseña ===================
                  _BloqueCard(
                    titulo: 'Nueva contraseña',
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Cambiar contraseña'),
                            onPressed: () async {
                              final nueva = _passCtrl.text.trim();
                              if (nueva.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
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
                                  : (prov.error!.contains('recent login') ||
                                        prov.error!.contains(
                                          'requires-recent-login',
                                        ))
                                  ? 'Por seguridad, vuelve a iniciar sesión y reintenta'
                                  : prov.error!;
                              if (mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              }
                              _passCtrl.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================== Apariencia ===================
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
                        const SizedBox(height: 4),
                        ListTile(
                          leading: CircleAvatar(backgroundColor: tema.seed),
                          title: const Text('Cambiar color'),
                          subtitle: const Text(
                            'Elige el color principal de la app',
                          ),
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

                  // =================== Secciones estilo “app grande” ===================
                  _BloqueCard(
                    titulo: 'Perfil',
                    child: Column(
                      children: [
                        _tile(
                          context,
                          Icons.person_outline,
                          'Información personal',
                          () {
                            Navigator.pushNamed(context, '/perfil/info');
                          },
                        ),
                        _tile(
                          context,
                          Icons.location_on_outlined,
                          'Direcciones',
                          () {
                            Navigator.pushNamed(context, '/perfil/direcciones');
                          },
                        ),
                        _tile(context, Icons.favorite_border, 'Favoritos', () {
                          Navigator.pushNamed(context, '/perfil/favoritos');
                        }),
                      ],
                    ),
                  ),

                  _BloqueCard(
                    titulo: 'Actividad',
                    child: Column(
                      children: [
                        _tile(
                          context,
                          Icons.account_balance_wallet_outlined,
                          'Billetera',
                          () {
                            // Implementar cuando tengas wallet
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente')),
                            );
                          },
                        ),
                        _tile(
                          context,
                          Icons.volunteer_activism_outlined,
                          'Donaciones',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  _BloqueCard(
                    titulo: 'Configuración',
                    child: Column(
                      children: [
                        _tile(
                          context,
                          Icons.notifications_none,
                          'Notificaciones',
                          () {
                            Navigator.pushNamed(
                              context,
                              '/perfil/notificaciones',
                            );
                          },
                        ),
                        _tile(
                          context,
                          Icons.info_outline,
                          'Información legal',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente')),
                            );
                          },
                        ),
                        _tile(
                          context,
                          Icons.devices_other_outlined,
                          'Cerrar sesión en otros dispositivos',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Para cerrar sesiones remotas, configura una Cloud Function.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================== Cerrar sesión ===================
                  TextButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    onPressed: () async {
                      await prov.cerrarSesion();
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (r) => false);
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
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
          title: const Text('Selecciona un color'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Paleta rápida
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _paleta)
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(c),
                          child: CircleAvatar(radius: 16, backgroundColor: c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Picker avanzado
                  SizedBox(
                    height: 200,
                    child: Material(
                      child: ColorPicker(
                        pickerColor: seleccionado,
                        onColorChanged: (c) => seleccionado = c,
                        enableAlpha: false,
                        displayThumbColor: true,
                      ),
                    ),
                  ),
                ],
              ),
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

  static const List<Color> _paleta = [
    Color(0xFF7B4EFF), // morado
    Color(0xFF6750A4),
    Color(0xFF2E7D32),
    Color(0xFF0277BD),
    Color(0xFF00838F),
    Color(0xFFD81B60),
    Color(0xFFF57C00),
    Color(0xFF5D4037),
  ];
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
