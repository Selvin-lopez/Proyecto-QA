import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaProvider extends ChangeNotifier {
  static const _kDark = 'tema.oscuro';
  static const _kSeed = 'tema.seed'; // ARGB int

  bool _oscuro = false;
  Color _seed = const Color(0xFF7B4EFF);

  bool get oscuro => _oscuro;
  Color get seed => _seed;

  ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: _oscuro ? Brightness.dark : Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
  }

  Future<void> cargar() async {
    final sp = await SharedPreferences.getInstance();
    _oscuro = sp.getBool(_kDark) ?? false;
    final seedInt = sp.getInt(_kSeed);
    if (seedInt != null) _seed = Color(seedInt);
    notifyListeners();
  }

  Future<void> setOscuro(bool v) async {
    _oscuro = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDark, v);
    notifyListeners();
  }

  Future<void> setSeed(Color c) async {
    _seed = c;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSeed, c.value);
    notifyListeners();
  }
}
