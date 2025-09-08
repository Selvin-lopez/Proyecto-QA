import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> irAlCheckout(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes iniciar sesión para continuar')),
    );
    return;
  }

  final doc = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

  try {
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      throw 'No se encontraron tus datos de perfil';
    }

    final data = snapshot.data()!;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final telefono = data['telefono'] ?? 'Sin teléfono';
    final correo = data['email'] ?? user.email ?? 'Sin correo';
    final direccion = data['direccion'] ?? 'Sin dirección';
    final nit = data['nit'] ?? ''; // puedes usar 'dpi' si decides usar eso

    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'nombre': nombre,
        'telefono': telefono,
        'correo': correo,
        'direccion': direccion,
        'nit': nit,
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error al cargar tus datos: $e')));
  }
}
