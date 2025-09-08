import 'package:flutter/material.dart';

class EmptyScreen extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final Color color;

  const EmptyScreen({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox,
    this.color = Colors.deepPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 80, color: color.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: color.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
