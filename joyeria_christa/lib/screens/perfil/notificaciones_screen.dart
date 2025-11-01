import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/perfil_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool promos = true;
  bool pedidos = true;
  bool novedades = true;
  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final service = context.read<PerfilService>();
    final notificaciones = await service.cargarNotificaciones();

    if (!mounted) return;
    setState(() {
      promos = notificaciones['promos'] ?? false;
      pedidos = notificaciones['pedidos'] ?? false;
      novedades = notificaciones['novedades'] ?? false;
      cargando = false;
    });
  }

  Future<void> _guardarPreferencias() async {
    setState(() => guardando = true);
    final service = context.read<PerfilService>();

    try {
      await service.guardarNotificaciones(
        promos: promos,
        pedidos: pedidos,
        novedades: novedades,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferencias guardadas')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  value: promos,
                  title: const Text('Promociones y descuentos'),
                  onChanged: (v) => setState(() => promos = v),
                ),
                SwitchListTile(
                  value: pedidos,
                  title: const Text('Actualizaciones de pedidos'),
                  onChanged: (v) => setState(() => pedidos = v),
                ),
                SwitchListTile(
                  value: novedades,
                  title: const Text('Novedades y lanzamientos'),
                  onChanged: (v) => setState(() => novedades = v),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: guardando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(guardando ? 'Guardando...' : 'Guardar'),
                    onPressed: guardando ? null : _guardarPreferencias,
                  ),
                ),
              ],
            ),
    );
  }
}
