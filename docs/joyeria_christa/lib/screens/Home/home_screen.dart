import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../services/home_service.dart';
import '../../models/joya_model.dart';
import '../../providers/favoritos_provider.dart';

import '../products/detalle_joya_screen.dart';

class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

class _PantallaHomeState extends State<PantallaHome> {
  int _currentIndex = 0;
  final HomeService _homeService = HomeService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = FirebaseAuth.instance.currentUser;
    final saludoEmail = usuario?.email ?? 'usuario';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JOYERÍA CHRISTA',
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgLight, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.diamond_outlined,
                size: 64,
                color: AppColors.primary.withOpacity(0.85),
              ),
              const SizedBox(height: 10),
              Text(
                '¡Hola, $saludoEmail!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Bienvenido a la joyería más brillante de Guatemala ✨',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(color: Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

              // ===== CARRUSEL (banners) =====
              SizedBox(
                height: 220,
                width: MediaQuery.of(context).size.width, // 👈 ancho definido
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _homeService.obtenerBanners(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("❌ Error al cargar banners"),
                      );
                    }
                    final banners = snapshot.data ?? [];
                    if (banners.isEmpty) {
                      return const Center(
                        child: Text("No hay banners activos"),
                      );
                    }
                    return Swiper(
                      itemCount: banners.length,
                      autoplay: true,
                      viewportFraction: 0.9,
                      scale: 0.95,
                      pagination: const SwiperPagination(),
                      itemBuilder: (context, index) {
                        final data = banners[index];
                        final imageUrl = (data['imagen'] ?? '')
                            .toString()
                            .trim();
                        final title = (data['titulo'] ?? 'Sin título')
                            .toString();
                        return _HeroCard(imageUrl: imageUrl, title: title);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),

              // ===== SECCIONES =====
              _SeccionStream(
                titulo: "Ofertas",
                stream: _homeService.obtenerJoyasOferta(),
                badge: "OFERTA",
              ),
              const SizedBox(height: 20),

              _SeccionStream(
                titulo: "Más vendidos",
                stream: _homeService.obtenerJoyasTop(),
                badge: "TOP",
              ),
              const SizedBox(height: 20),

              _SeccionStream(
                titulo: "Nuevos ingresos",
                stream: _homeService.obtenerJoyasNuevas(),
                badge: "NUEVO",
              ),
            ],
          ),
        ),
      ),

      // ===== MENÚ INFERIOR =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);

          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/carrito');
              break;
            case 2:
              Navigator.pushNamed(context, '/joyas');
              break;
            case 3:
              Navigator.pushNamed(context, '/perfil/favoritos');
              break;
            case 4:
              Navigator.pushNamed(context, '/lista-pedidos');
              break;
            case 5:
              Navigator.pushNamed(context, '/perfil');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Inicio",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Carrito",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.diamond),
            label: "Joyas",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.favorite),
                Positioned(
                  right: 0,
                  child: Consumer<FavoritosProvider>(
                    builder: (_, favs, __) {
                      if (favs.favoritos.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          favs.favoritos.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            label: "Favoritos",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Pedidos",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _HeroCard({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl.isNotEmpty
                ? imageUrl
                : 'https://via.placeholder.com/600x300?text=Banner',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 60),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Sección con Stream (joyas) =====
class _SeccionStream extends StatelessWidget {
  final String titulo;
  final Stream<List<Map<String, dynamic>>> stream;
  final String badge;

  const _SeccionStream({
    required this.titulo,
    required this.stream,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text("Ver todo")),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 238,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "❌ Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final productos = snapshot.data ?? [];
              if (productos.isEmpty) {
                return const Center(child: Text("Sin productos disponibles"));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: productos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final data = productos[i];

                  final joya = Joya(
                    id: data['id'] ?? 'sin-id',
                    nombre: data['nombre'] ?? 'Producto',
                    precio: (data['precio'] is num)
                        ? (data['precio'] as num).toDouble()
                        : 0.0,
                    imagen: (data['imagen'] ?? '').toString(),
                    material: data['material'] ?? '',
                    peso: (data['peso'] is num)
                        ? (data['peso'] as num).toDouble()
                        : 0.0,
                    tipo: data['tipo'] ?? '',
                    cantidad: (data['cantidad'] ?? 0) as int,
                    descuento: (data['descuento'] ?? 0) as int,
                  );

                  final precio = joya.precio;
                  final precioFinal = precio - (precio * joya.descuento / 100);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleJoyaScreen(joya: joya),
                        ),
                      );
                    },
                    child: _MiniCard(
                      title: joya.nombre,
                      imageUrl: joya.imagen,
                      price: "Q ${precioFinal.toStringAsFixed(2)}",
                      badge: badge,
                      precioOriginal: joya.descuento > 0
                          ? "Q ${precio.toStringAsFixed(2)}"
                          : null,
                      descuento: joya.descuento,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String price;
  final String badge;
  final String? precioOriginal;
  final int descuento;

  const _MiniCard({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.badge,
    this.precioOriginal,
    this.descuento = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl.isNotEmpty
                      ? imageUrl
                      : 'https://via.placeholder.com/300x200?text=Imagen',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 40),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeColor(badge),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge == "OFERTA" && descuento > 0
                          ? "-$descuento%"
                          : badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (precioOriginal != null)
                        Text(
                          precioOriginal!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            height: 1.0,
                          ),
                        ),
                      Text(
                        price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case "OFERTA":
        return Colors.redAccent;
      case "TOP":
        return Colors.deepPurple;
      case "NUEVO":
        return Colors.blueAccent;
      default:
        return AppColors.primary;
    }
  }
}
