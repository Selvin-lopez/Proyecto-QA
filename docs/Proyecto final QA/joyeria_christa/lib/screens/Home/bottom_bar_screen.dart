import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart'; // Tu pantalla pro de inicio
import '../products/products_screen.dart'; // O podrías mostrar productos desde home
// Importa tus otras pantallas reales aquí

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({super.key});

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _index = 0;

  final List<Widget> _pages = const [
    PantallaHome(),
    ProductsScreen(), // Podrías cambiar a CartScreen()
    Center(child: Text('Tus favoritos 📌')),
    Center(child: Text('Perfil del usuario')),
  ];

  final List<String> _titles = ['Inicio', 'Productos', 'Favoritos', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
