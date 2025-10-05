import 'package:flutter/material.dart';

class UI {
  static void toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  static String? emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!r.hasMatch(v.trim())) return 'Correo no válido';
    return null;
  }

  static String? passValidator(String? v, {int min = 6}) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < min) return 'Mínimo $min caracteres';
    return null;
  }
}
