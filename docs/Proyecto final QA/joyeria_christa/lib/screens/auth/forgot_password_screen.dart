import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/ui_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendReset(_email.text.trim());
      if (!mounted) return;
      UI.toast(context, 'Enviamos un enlace a tu correo');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      UI.toast(context, 'No se pudo enviar el correo');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con tu imagen
          Image.asset('assets/images/Fondo_login.png', fit: BoxFit.cover),
          // Overlay para mejorar contraste del contenido
          Container(color: Colors.black.withOpacity(0.45)),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Restablecer contraseña',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              hintText: 'tu@correo.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: UI.emailValidator,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (_) => _loading ? null : _send(),
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _send,
                                    icon: const Icon(Icons.send_outlined),
                                    label: const Text('Enviar enlace'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
