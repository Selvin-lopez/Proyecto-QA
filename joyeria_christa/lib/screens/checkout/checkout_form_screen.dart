import 'package:flutter/material.dart';

class CheckoutFormScreen extends StatefulWidget {
  const CheckoutFormScreen({super.key});

  @override
  State<CheckoutFormScreen> createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _nitController;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final datos =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    _nombreController = TextEditingController(text: datos['nombre'] ?? '');
    _telefonoController = TextEditingController(text: datos['telefono'] ?? '');
    _correoController = TextEditingController(text: datos['correo'] ?? '');
    _direccionController = TextEditingController(
      text: datos['direccion'] ?? '',
    );
    _nitController = TextEditingController(text: datos['nit'] ?? '');

    _initialized = true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _nitController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      final datos = {
        'nombre': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'nit': _nitController.text.trim(),
      };

      Navigator.pushNamed(context, '/checkout/metodo-pago', arguments: datos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de entrega'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCampo(
                _nombreController,
                'Nombre completo',
                autofillHint: AutofillHints.name,
                icon: Icons.person_outline,
              ),
              _buildCampo(
                _telefonoController,
                'Teléfono',
                tipo: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHint: AutofillHints.telephoneNumber,
                icon: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (v.trim().length < 8) return 'Teléfono inválido';
                  return null;
                },
              ),
              _buildCampo(
                _correoController,
                'Correo electrónico',
                tipo: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHint: AutofillHints.email,
                icon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
                  if (!regex.hasMatch(v.trim())) return 'Correo inválido';
                  return null;
                },
              ),
              _buildCampo(
                _direccionController,
                'Dirección de entrega',
                maxLines: 2,
                textInputAction: TextInputAction.next,
                autofillHint: AutofillHints.fullStreetAddress,
                icon: Icons.location_on_outlined,
              ),
              _buildCampo(
                _nitController,
                'NIT o número de DPI',
                textInputAction: TextInputAction.done,
                icon: Icons.badge_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (v.trim().length < 6) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _continuar,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar a método de pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(
    TextEditingController controller,
    String label, {
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? autofillHint,
    IconData? icon,
    TextInputAction? textInputAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        maxLines: maxLines,
        textInputAction: textInputAction,
        autofillHints: autofillHint != null ? [autofillHint] : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator:
            validator ??
            (value) => (value == null || value.isEmpty)
                ? 'Este campo es obligatorio'
                : null,
      ),
    );
  }
}
