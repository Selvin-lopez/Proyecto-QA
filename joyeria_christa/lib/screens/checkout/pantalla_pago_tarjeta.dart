import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/carrito_provider.dart';
import '../../services/pedido_service.dart';
import '../../services/perfil_service.dart'; // 👈 fallback desde perfil

class PantallaPagoTarjeta extends StatefulWidget {
  const PantallaPagoTarjeta({super.key});

  @override
  State<PantallaPagoTarjeta> createState() => _PantallaPagoTarjetaState();
}

class _PantallaPagoTarjetaState extends State<PantallaPagoTarjeta> {
  final _formKey = GlobalKey<FormState>();

  final _numCtr = TextEditingController();
  final _nameCtr = TextEditingController();
  final _expCtr = TextEditingController();
  final _cvvCtr = TextEditingController();

  final _cvvFocus = FocusNode();
  bool _showBack = false;
  bool _cargando = false;

  Map<String, dynamic> _datosEntrega = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _datosEntrega = Map<String, dynamic>.from(args);
    }
    Future.microtask(() async {
      if (!mounted) return;
      if (!_entregaValida(_datosEntrega)) {
        final perfil = await PerfilService().obtenerDatosEntrega();
        if (mounted && perfil != null) {
          setState(() => _datosEntrega = perfil);
        }
      }
      if (!_entregaValida(_datosEntrega)) {
        if (!mounted) return;
        _toast(
          context,
          'Faltan datos de entrega. Completa tu información antes de pagar.',
        );
        Navigator.pop(context);
      } else {
        debugPrint('📦 Datos de entrega en pago-tarjeta: $_datosEntrega');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _cvvFocus.addListener(() => setState(() => _showBack = _cvvFocus.hasFocus));
  }

  @override
  void dispose() {
    _numCtr.dispose();
    _nameCtr.dispose();
    _expCtr.dispose();
    _cvvCtr.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  // ====== Validaciones ======
  String _formatCardNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  bool _luhnValid(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return false;
    var sum = 0, even = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (even) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      even = !even;
    }
    return sum % 10 == 0;
  }

  String _detectBrand(String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('4')) return 'VISA';
    if (RegExp(r'^(5[1-5])').hasMatch(d) ||
        RegExp(r'^(2(2[2-9]|[3-6]\d|7[01]))').hasMatch(d)) {
      return 'MASTERCARD';
    }
    return 'CARD';
  }

  bool _expiryValid(String mmYY) {
    final v = mmYY.replaceAll(RegExp(r'\D'), '');
    if (v.length != 4) return false;
    final mm = int.tryParse(v.substring(0, 2)) ?? 0;
    final yy = int.tryParse(v.substring(2, 4)) ?? -1;
    if (mm < 1 || mm > 12) return false;

    final now = DateTime.now();
    final year = 2000 + yy;
    final exp = DateTime(year, mm + 1, 0, 23, 59, 59);
    return exp.isAfter(DateTime(now.year, now.month, now.day));
  }

  bool get _formOk => (_formKey.currentState?.validate() ?? false);

  void _onNumChanged(String v) {
    final formatted = _formatCardNumber(v);
    if (formatted != v) {
      _numCtr.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _onExpChanged(String v) {
    var clean = v.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 4) clean = clean.substring(0, 4);
    String out;
    if (clean.length >= 3) {
      out = '${clean.substring(0, 2)}/${clean.substring(2)}';
    } else if (clean.length >= 1) {
      out = clean.length >= 2 ? '${clean.substring(0, 2)}/' : clean;
    } else {
      out = '';
    }
    if (out != v) {
      _expCtr.value = TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: out.length),
      );
    }
    setState(() {});
  }

  Future<void> _finalizarPedido() async {
    if (!_formOk) {
      _toast(context, 'Verifica los datos de la tarjeta');
      return;
    }
    if (!_entregaValida(_datosEntrega)) {
      _toast(context, 'Faltan datos de entrega. Vuelve y complétalos.');
      return;
    }

    try {
      setState(() => _cargando = true);

      final digits = _numCtr.text.replaceAll(RegExp(r'\D'), '');
      final last4 = digits.length >= 4
          ? digits.substring(digits.length - 4)
          : digits;
      final brand = _detectBrand(_numCtr.text);

      final tarjetaInfo = {
        'brand': brand,
        'last4': last4,
        'nombre': _nameCtr.text.trim(),
        'vencimiento': _expCtr.text,
        'authCode': 'AUTH${DateTime.now().millisecondsSinceEpoch % 1000000}',
      };

      final carrito = context.read<CarritoProvider>();

      // ✅ Mostrar dialogs secuenciales
      await _mostrarDialogoProceso(
        titulo: "Verificando fondos en el banco...",
        icono: const CircularProgressIndicator(color: Colors.white),
        duracion: const Duration(seconds: 2),
      );

      await _mostrarDialogoProceso(
        titulo: "Transacción exitosa ✅",
        icono: const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.greenAccent,
        ),
        duracion: const Duration(seconds: 1),
      );

      // 🔄 Crear pedido
      final pedidoId = await PedidoService().crearPedido(
        joyas: carrito.productos,
        metodoPago: 'tarjeta',
        datosEntrega: {
          'nombre': _datosEntrega['nombre'] ?? '',
          'telefono': _datosEntrega['telefono'] ?? '',
          'correo': _datosEntrega['correo'] ?? '',
          'direccion': _datosEntrega['direccion'] ?? '',
          'nitDpi': _datosEntrega['nitDpi'] ?? '',
        },
        tarjeta: tarjetaInfo,
      );

      if (pedidoId != null) {
        carrito.limpiarCarrito();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/pedido-exito',
          (route) => false,
          arguments: pedidoId,
        );
      } else {
        _toast(context, 'Error al crear el pedido');
      }
    } catch (e) {
      _toast(context, 'Error al procesar pago: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoProceso({
    required String titulo,
    required Widget icono,
    required Duration duracion,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icono,
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(duracion);
    if (mounted) Navigator.of(context).pop(); // cerrar dialogo
  }

  bool _entregaValida(Map<String, dynamic> m) {
    final req = ['nombre', 'telefono', 'correo', 'direccion', 'nitDpi'];
    for (final k in req) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isEmpty) return false;
    }
    return true;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====== UI ======
  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (v) {
          onChanged?.call(v);
          setState(() {});
        },
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = _detectBrand(_numCtr.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con tarjeta'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TarjetaVisual(
              numero: _numCtr.text,
              nombre: _nameCtr.text,
              vencimiento: _expCtr.text,
              cvv: _cvvCtr.text,
              reverso: _showBack,
              brand: brand,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _field(
                      label: 'Número de tarjeta',
                      controller: _numCtr,
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      onChanged: _onNumChanged,
                      validator: (v) => _luhnValid(v ?? '')
                          ? null
                          : 'Número de tarjeta inválido',
                    ),
                    _field(
                      label: 'Nombre del titular',
                      controller: _nameCtr,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Ingresa el nombre'
                          : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Vencimiento (MM/AA)',
                            controller: _expCtr,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            onChanged: _onExpChanged,
                            validator: (v) =>
                                _expiryValid(v ?? '') ? null : 'Fecha inválida',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            label: 'CVV',
                            controller: _cvvCtr,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            focusNode: _cvvFocus,
                            validator: (v) =>
                                (v != null && v.length >= 3 && v.length <= 4)
                                ? null
                                : 'CVV inválido',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: !_cargando ? _finalizarPedido : null,
                      icon: _cargando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.lock),
                      label: Text(_cargando ? 'Procesando...' : 'Pagar ahora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        disabledBackgroundColor: Colors.purple.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== Tarjeta visual ====
class _TarjetaVisual extends StatelessWidget {
  final String numero;
  final String nombre;
  final String vencimiento;
  final String cvv;
  final bool reverso;
  final String brand;

  const _TarjetaVisual({
    required this.numero,
    required this.nombre,
    required this.vencimiento,
    required this.cvv,
    required this.reverso,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: reverso
          ? _TarjetaBack(cvv: cvv, brand: brand, key: const ValueKey('back'))
          : _TarjetaFront(
              numero: numero,
              nombre: nombre,
              vencimiento: vencimiento,
              brand: brand,
              key: const ValueKey('front'),
            ),
    );
  }
}

class _TarjetaFront extends StatelessWidget {
  final String numero;
  final String nombre;
  final String vencimiento;
  final String brand;

  const _TarjetaFront({
    required this.numero,
    required this.nombre,
    required this.vencimiento,
    required this.brand,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayNum = numero.isEmpty
        ? '**** **** **** ****'
        : numero.padRight(19, '•');
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A00FF), Color(0xFF9747FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Text(
                brand,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (nombre.isEmpty ? 'NOMBRE APELLIDO' : nombre.toUpperCase()),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                vencimiento.isEmpty ? 'MM/AA' : vencimiento,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaBack extends StatelessWidget {
  final String cvv;
  final String brand;

  const _TarjetaBack({required this.cvv, required this.brand, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(brand, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(height: 38, color: Colors.black54),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cvv.isEmpty ? '***' : cvv,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
