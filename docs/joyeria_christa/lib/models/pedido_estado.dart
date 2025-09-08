import 'package:flutter/material.dart';

enum PedidoEstado { pendiente, confirmado, en_camino, entregado, cancelado }

PedidoEstado estadoFromString(String v) {
  switch (v) {
    case 'confirmado':
      return PedidoEstado.confirmado;
    case 'en_camino':
      return PedidoEstado.en_camino;
    case 'entregado':
      return PedidoEstado.entregado;
    case 'cancelado':
      return PedidoEstado.cancelado;
    default:
      return PedidoEstado.pendiente;
  }
}

String estadoToString(PedidoEstado e) => e.name;

Color estadoColor(PedidoEstado e) {
  switch (e) {
    case PedidoEstado.confirmado:
      return Colors.blue;
    case PedidoEstado.en_camino:
      return Colors.orange;
    case PedidoEstado.entregado:
      return Colors.green;
    case PedidoEstado.cancelado:
      return Colors.red;
    case PedidoEstado.pendiente:
      return Colors.grey;
  }
}

String estadoLabel(PedidoEstado e) {
  switch (e) {
    case PedidoEstado.confirmado:
      return 'Confirmado';
    case PedidoEstado.en_camino:
      return 'En camino';
    case PedidoEstado.entregado:
      return 'Entregado';
    case PedidoEstado.cancelado:
      return 'Cancelado';
    case PedidoEstado.pendiente:
      return 'Pendiente';
  }
}
