import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Theme
import 'providers/tema_provider.dart';

// Providers
import 'providers/carrito_provider.dart';
import 'providers/perfil_provider.dart';
import 'providers/pedidos_provider.dart';
import 'providers/favoritos_provider.dart';

// Services
import 'services/perfil_service.dart';

// Screens - Auth y Home
import 'screens/auth/login_screen.dart';
import 'screens/Home/home_screen.dart';

// Screens - Admin
import 'screens/admin/pantalla_admin.dart';

// Screens - Carrito y Joyas
import 'screens/cart/pantalla_carrito.dart';
import 'screens/pantalla_joyas_firestore.dart';

// Screens - Perfil
import 'screens/perfil/pantalla_perfil.dart';
import 'screens/perfil/info_personal_screen.dart';
import 'screens/perfil/direcciones_screen.dart';
import 'screens/perfil/notificaciones_screen.dart';
import 'screens/perfil/favoritos_screen.dart';

// Screens - Pedidos
import 'screens/pedidos/pantalla_lista_pedidos.dart';
import 'screens/pedidos/pantalla_detalle_pedido.dart';
import 'screens/pedidos/pantalla_mis_pedidos.dart';
import 'screens/pedidos/pantalla_pedido_exito.dart';

// Screens - Checkout
import 'screens/checkout/pantalla_checkout.dart';
import 'screens/checkout/confirmar_pedido_screen.dart';
import 'screens/checkout/pantalla_pago_tarjeta.dart';

// Global para SnackBars
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final tema = TemaProvider();
  await tema.cargar();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => tema),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => PedidosProvider()),
        ChangeNotifierProvider(
          create: (_) => FavoritosProvider()..cargarFavoritos(),
        ),
        Provider<PerfilService>(create: (_) => PerfilService()),
        ChangeNotifierProxyProvider<PerfilService, PerfilProvider>(
          create: (_) => PerfilProvider(PerfilService()), // inicial temporal
          update: (_, service, __) => PerfilProvider(service),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Joyería App',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: tema.theme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(tema.theme.textTheme),
      ),
      // ✅ Definimos rutas claras
      initialRoute: '/login',
      routes: {
        // Auth
        '/login': (_) => const LoginScreen(),

        // Cliente
        '/home': (_) => const PantallaHome(),
        '/carrito': (_) => const PantallaCarrito(),
        '/joyas': (_) => const PantallaJoyasFirestore(),
        '/perfil': (_) => const PantallaPerfil(),
        '/perfil/info': (_) => const InfoPersonalScreen(),
        '/perfil/direcciones': (_) => const DireccionesScreen(),
        '/perfil/notificaciones': (_) => const NotificacionesScreen(),
        '/perfil/favoritos': (_) => const FavoritosScreen(),

        // Pedidos
        '/lista-pedidos': (_) => const PantallaListaPedidos(),
        '/mis-pedidos': (_) => const PantallaMisPedidos(),
        '/detalle-pedido': (_) => const PantallaDetallePedido(),
        '/pedido-exito': (_) => const PantallaPedidoExito(),

        // Checkout
        '/checkout': (_) => const PantallaCheckout(),
        '/confirmar-pedido': (_) => const ConfirmarPedidoScreen(),
        '/pago-tarjeta': (_) => const PantallaPagoTarjeta(),

        // Admin
        '/admin': (_) => const PantallaAdmin(),
      },

      // 🔹 Manejo de autenticación y roles dinámicamente
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error de autenticación')),
            );
          }
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          // Si hay usuario → verificamos rol
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snap.hasData || !snap.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text('Usuario no encontrado')),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;
              final rol = data['rol'] ?? 'cliente';

              if (rol == 'admin') {
                return const PantallaAdmin();
              } else {
                return const PantallaHome();
              }
            },
          );
        },
      ),

      // 🚨 Manejo de rutas inexistentes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Ruta no encontrada'))),
      ),
    );
  }
}
