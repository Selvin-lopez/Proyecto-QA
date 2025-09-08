import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/ui_helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showPass2 = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pass.text.trim() != _pass2.text.trim()) {
      UI.toast(context, 'Las contraseñas no coinciden');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.registerWithEmail(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      // (Opcional) envía verificación por correo
      await AuthService.instance.currentUser?.sendEmailVerification();

      if (!mounted) return;
      UI.toast(context, 'Usuario registrado. Revisa tu correo para verificar.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      UI.toast(context, e.message ?? 'Error al registrarse');
    } catch (e) {
      if (!mounted) return;
      UI.toast(context, 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo + overlay para legibilidad (igual que el login)
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Fondo_login.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.45)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 10,
                    color: Colors.white.withOpacity(0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Nombre
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa tu nombre'
                                  : (v.trim().length < 3
                                        ? 'Mínimo 3 caracteres'
                                        : null),
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 12),

                            // Correo
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(
                                labelText: 'Correo',
                                hintText: 'tu@correo.com',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: UI.emailValidator,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 12),

                            // Contraseña
                            TextFormField(
                              controller: _pass,
                              obscureText: !_showPass,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _showPass = !_showPass),
                                  icon: Icon(
                                    _showPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: UI.passValidator,
                              enabled: !_loading,
                              onChanged: (_) {
                                // fuerza revalidar confirmación al cambiar pass
                                if (_pass2.text.isNotEmpty) {
                                  _formKey.currentState!.validate();
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Confirmar contraseña
                            TextFormField(
                              controller: _pass2,
                              obscureText: !_showPass2,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_outlined,
                                ),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _showPass2 = !_showPass2),
                                  icon: Icon(
                                    _showPass2
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  _loading ? null : _register(),
                              validator: (v) {
                                final p1 = _pass.text.trim();
                                final p2 = (v ?? '').trim();
                                if (p2.isEmpty) return 'Confirma tu contraseña';
                                if (p1 != p2)
                                  return 'Las contraseñas no coinciden';
                                return null;
                              },
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 20),

                            // Botón crear cuenta
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: _loading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _register,
                                      child: const Text('Crear cuenta'),
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
          ),
        ],
      ),
    );
  }
}
