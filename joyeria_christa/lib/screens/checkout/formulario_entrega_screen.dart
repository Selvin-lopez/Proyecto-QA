import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/perfil_service.dart';

class FormularioEntregaScreen extends StatefulWidget {
  const FormularioEntregaScreen({super.key});

  @override
  State<FormularioEntregaScreen> createState() =>
      _FormularioEntregaScreenState();
}

class _FormularioEntregaScreenState extends State<FormularioEntregaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nitDpiController = TextEditingController();

  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final perfilService = context.read<PerfilService>();
      final perfil = await perfilService.cargarPerfil();

      if (perfil != null) {
        _nombreController.text = perfil['nombre'] ?? '';
        _telefonoController.text = perfil['telefono'] ?? '';
        _correoController.text = perfil['email'] ?? '';
        _direccionController.text = perfil['direccion'] ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

    final datos = {
      'nombre': _nombreController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'nitDpi': _nitDpiController.text.trim(),
    };

    Navigator.pushNamed(context, '/checkout', arguments: datos).then((_) {
      // 🔄 Resetear estado al volver
      if (mounted) {
        setState(() => _procesando = false);
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _nitDpiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de entrega y facturación'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _campoTexto(
                      'Nombre completo',
                      _nombreController,
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                    _campoTexto(
                      'Teléfono',
                      _telefonoController,
                      tipo: TextInputType.phone,
                      icon: Icons.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obligatorio';
                        } else if (v.trim().length < 8) {
                          return 'Teléfono inválido';
                        }
                        return null;
                      },
                    ),
                    _campoTexto(
                      'Correo electrónico',
                      _correoController,
                      tipo: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final regex = RegExp(
                          r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!regex.hasMatch(v.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    _campoTexto(
                      'Dirección de entrega',
                      _direccionController,
                      maxLines: 2,
                      icon: Icons.location_on_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    _campoTexto(
                      'NIT o número de DPI',
                      _nitDpiController,
                      icon: Icons.badge_outlined,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obligatorio';
                        } else if (v.trim().length < 6) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _procesando ? null : _continuar,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar al pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? icon,
    TextInputAction? textInputAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        maxLines: maxLines,
        textInputAction: textInputAction,
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Campo obligatorio'
                : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
