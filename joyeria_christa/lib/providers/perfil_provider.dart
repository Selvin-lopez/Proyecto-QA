import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/perfil_service.dart';

class PerfilProvider extends ChangeNotifier {
  final PerfilService _service;
  PerfilProvider(this._service);

  bool cargando = false;
  String? error;

  Map<String, dynamic>? perfil; // {uid, nombre, email, fotoUrl, ...}

  Future<void> init() async {
    try {
      cargando = true;
      error = null;
      notifyListeners();
      perfil = await _service.cargarPerfil();
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> actualizarNombre(String nombre) async {
    try {
      cargando = true;
      error = null;
      notifyListeners();
      await _service.actualizarNombre(nombre);
      perfil?['nombre'] = nombre;
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> actualizarFoto(File archivo) async {
    try {
      cargando = true;
      error = null;
      notifyListeners();
      final url = await _service.actualizarFoto(archivo);
      if (url != null) perfil?['fotoUrl'] = url;
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cambiarPassword(String nueva) async {
    try {
      cargando = true;
      error = null;
      notifyListeners();
      await _service.cambiarPassword(nueva);
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() => _service.cerrarSesion();
}
