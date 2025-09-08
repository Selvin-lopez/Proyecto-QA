// 📁 pantalla_home.dart

import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/tema_provider.dart';
import '../../theme/app_colors.dart';

class PantallaHome extends StatelessWidget {
  const PantallaHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final usuario = FirebaseAuth.instance.currentUser;
    final saludoEmail = usuario?.email ?? 'usuario';
    final carouselHeight = size.height * 0.26; // un poco más alto para lucir

    // === DATA DEMO ===
    final List<Map<String, String>> destacados = [
      {
        'titulo': 'Colección Oro 18k',
        'imagen': 'https://i.imgur.com/nvZ3R7E.jpg',
      },
      {
        'titulo': 'Esmeraldas y Perlas',
        'imagen': 'https://i.imgur.com/74gFzIv.jpg',
      },
      {
        'titulo': 'Diamantes Certificados',
        'imagen': 'https://i.imgur.com/ZF6s192.jpeg',
      },
    ];

    final List<Map<String, String>> ofertas = [
      {
        'titulo': 'Anillo solitario -20%',
        'imagen': 'https://i.imgur.com/a8x8W8O.jpeg',
        'precio': 'Q 2,399',
      },
      {
        'titulo': 'Aretes perla -15%',
        'imagen': 'https://i.imgur.com/hh1wQmD.jpeg',
        'precio': 'Q 1,190',
      },
      {
        'titulo': 'Pulsera oro -10%',
        'imagen': 'https://i.imgur.com/4gVb6kC.jpeg',
        'precio': 'Q 2,990',
      },
    ];

    final List<Map<String, String>> masVendidos = [
      {
        'titulo': 'Collar corazón',
        'imagen': 'https://i.imgur.com/4P2Ww4a.jpeg',
        'precio': 'Q 1,650',
      },
      {
        'titulo': 'Anillo zafiro',
        'imagen': 'https://i.imgur.com/3vQy0jC.jpeg',
        'precio': 'Q 3,250',
      },
      {
        'titulo': 'Aretes diamante',
        'imagen': 'https://i.imgur.com/8n6t8vt.jpeg',
        'precio': 'Q 2,790',
      },
    ];

    final List<Map<String, String>> nuevosIngresos = [
      {
        'titulo': 'Anillo media alianza',
        'imagen': 'https://i.imgur.com/6X5jJm5.jpeg',
        'precio': 'Q 3,990',
      },
      {
        'titulo': 'Dije luna',
        'imagen': 'https://i.imgur.com/1Gq3c17.jpeg',
        'precio': 'Q 890',
      },
      {
        'titulo': 'Pulsera minimal',
        'imagen': 'https://i.imgur.com/9gR6jQb.jpeg',
        'precio': 'Q 1,150',
      },
    ];

    final List<Map<String, String>> recomendados = [
      {
        'titulo': 'Set perlas clásicas',
        'imagen': 'https://i.imgur.com/1lZbGqi.jpeg',
        'precio': 'Q 2,350',
      },
      {
        'titulo': 'Collar inicial',
        'imagen': 'https://i.imgur.com/9hY5b6t.jpeg',
        'precio': 'Q 980',
      },
      {
        'titulo': 'Anillo geométrico',
        'imagen': 'https://i.imgur.com/2rXz3i4.jpeg',
        'precio': 'Q 1,490',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        actions: [
          IconButton(
            tooltip: 'Cambiar color',
            icon: const Icon(Icons.palette_outlined),
            color: AppColors.primary,
            onPressed: () async {
              final tema = context.read<TemaProvider>();
              Color seleccionado = tema.seed;

              final nuevo = await showDialog<Color>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Selecciona un color'),
                  content: SizedBox(
                    height: 200,
                    child: ColorPicker(
                      pickerColor: seleccionado,
                      onColorChanged: (c) => seleccionado = c,
                      enableAlpha: false,
                      displayThumbColor: true,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, seleccionado),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              );

              if (nuevo != null) await tema.setSeed(nuevo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            color: AppColors.primary,
            tooltip: 'Mi perfil',
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.primary,
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bgLight, AppColors.secondary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),

                    // ===== CARRUSEL (sin zoom, tarjetas del mismo tamaño) =====
                    SizedBox(
                      height: carouselHeight,
                      child: Swiper(
                        itemCount: destacados.length,
                        autoplay: true,
                        autoplayDelay: 4000,
                        duration: 550,
                        curve: Curves.easeOutCubic,
                        viewportFraction: 0.9,
                        scale: 1.0, // ✅ sin efecto de zoom
                        pagination: const SwiperPagination(),
                        itemBuilder: (context, index) {
                          final item = destacados[index];
                          final url = item['imagen']!;
                          final titulo = item['titulo']!;
                          return _HeroCard(imageUrl: url, title: titulo);
                        },
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ===== SECCIONES =====
                    _SeccionTarjetas(
                      titulo: 'Ofertas',
                      items: ofertas,
                      badge: 'OFERTA',
                      onTapVerTodo: () =>
                          Navigator.pushNamed(context, '/joyas'),
                    ),
                    const SizedBox(height: 18),
                    _SeccionTarjetas(
                      titulo: 'Más vendidos',
                      items: masVendidos,
                      badge: 'TOP',
                      onTapVerTodo: () =>
                          Navigator.pushNamed(context, '/joyas'),
                    ),
                    const SizedBox(height: 18),
                    _SeccionTarjetas(
                      titulo: 'Nuevos ingresos',
                      items: nuevosIngresos,
                      badge: 'NUEVO',
                      onTapVerTodo: () =>
                          Navigator.pushNamed(context, '/joyas'),
                    ),
                    const SizedBox(height: 18),
                    _SeccionTarjetas(
                      titulo: 'Recomendados para ti',
                      items: recomendados,
                      badge: '★',
                      onTapVerTodo: () =>
                          Navigator.pushNamed(context, '/joyas'),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ===== BOTONES INFERIORES =====
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white.withOpacity(0.96),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ActionChip(
                      icon: Icons.home_filled,
                      label: 'Inicio',
                      onTap: () => _tap(context, 'Inicio'),
                    ),
                    _ActionChip(
                      icon: Icons.shopping_cart,
                      label: 'Carrito',
                      onTap: () => _tap(context, 'Carrito'),
                    ),
                    _ActionChip(
                      icon: Icons.diamond,
                      label: 'Joyas',
                      onTap: () => _tap(context, 'Joyas'),
                    ),
                    _ActionChip(
                      icon: Icons.favorite,
                      label: 'Favoritos',
                      onTap: () => _tap(context, 'Favoritos'),
                    ),
                    _ActionChip(
                      icon: Icons.receipt_long,
                      label: 'Pedidos',
                      onTap: () => _tap(context, 'Mis pedidos'),
                    ),
                    _ActionChip(
                      icon: Icons.person,
                      label: 'Perfil',
                      onTap: () => _tap(context, 'Perfil'),
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

  static void _tap(BuildContext context, String destino) {
    switch (destino) {
      case 'Inicio':
        // Ya estás en Home; podrías hacer scroll up o refrescar si gustas.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ya estás en Inicio')));
        break;
      case 'Carrito':
        Navigator.pushNamed(context, '/carrito');
        break;
      case 'Joyas':
        Navigator.pushNamed(context, '/joyas');
        break;
      case 'Perfil':
        Navigator.pushNamed(context, '/perfil');
        break;
      case 'Mis pedidos':
        Navigator.pushNamed(context, '/lista-pedidos');
        break;
      case 'Favoritos':
        Navigator.pushNamed(context, '/favoritos');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Destino "$destino" no disponible.')),
        );
    }
  }
}

/// ===== Tarjeta grande del carrusel (tamaño uniforme, sin zoom) =====
class _HeroCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _HeroCard({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mantener tamaño uniforme con AspectRatio visual (simulado por height fijo del Swiper)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover, // no zoom animado; solo recorte elegante
              placeholder: (ctx, _) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (ctx, _, __) => Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Text('No se pudo cargar la imagen'),
              ),
            ),
            // Overlay sutil para legibilidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Título
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Sección con lista horizontal de tarjetas pequeñas =====
class _SeccionTarjetas extends StatelessWidget {
  final String titulo;
  final List<Map<String, String>> items;
  final String? badge;
  final VoidCallback? onTapVerTodo;

  const _SeccionTarjetas({
    required this.titulo,
    required this.items,
    this.badge,
    this.onTapVerTodo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header de sección
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            TextButton(onPressed: onTapVerTodo, child: const Text('Ver todo')),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              return _MiniCard(
                title: item['titulo'] ?? '',
                imageUrl: item['imagen'] ?? '',
                price: item['precio'],
                badge: badge,
                onTap: () {
                  // Podrías navegar a detalle, con argumentos
                  Navigator.pushNamed(context, '/joyas');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ===== Tarjeta pequeña de producto =====
class _MiniCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String? price;
  final String? badge;
  final VoidCallback? onTap;

  const _MiniCard({
    required this.title,
    required this.imageUrl,
    this.price,
    this.badge,
    this.onTap,
  });

  @override
  State<_MiniCard> createState() => _MiniCardState();
}

class _MiniCardState extends State<_MiniCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(_) => _controller.forward();
  void _onExit(_) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen con altura fija para un tamaño consistente
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, _) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (ctx, _, __) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                        if (widget.badge != null)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (widget.price != null)
                          Text(
                            widget.price!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===== Botón/chip inferior con hover y escala =====
class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(_) => _controller.forward();
  void _onExit(_) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 24, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
