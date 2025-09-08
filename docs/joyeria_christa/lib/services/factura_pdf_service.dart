import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Estructura esperada en [pedido]:
/// {
///   'nombre','telefono','correo','direccion','nitDpi','metodoPago','fecha',
///   'total', 'items': [ {'id','nombre','precio','cantidad','subtotal','imagen'} ],
///   'tarjeta': {'brand','last4','nombre','vencimiento'} // opcional si pago tarjeta
/// }
class FacturaPdfService {
  static Future<Uint8List> generarFactura({
    required Map<String, dynamic> pedido,
    String serie = 'A-2025',
    String numero = '000001',
    String empresa = 'JOYERÍA CHRISTA',
    String nitEmpresa = '111515135',
    String direccionEmpresa = 'Ciudad, Guatemala',
    String telefonoEmpresa = '(502) 0000-0000',
  }) async {
    final pdf = pw.Document();
    final fechaStr = DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now());
    final items = List<Map<String, dynamic>>.from(pedido['items'] as List);

    num total = 0;
    for (final it in items) {
      total += (it['subtotal'] ?? (it['precio'] * it['cantidad']));
    }

    pw.Widget _rowL(String l, String v) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$l ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(28),
          textDirection: pw.TextDirection.ltr,
        ),
        build: (context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    empresa,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(direccionEmpresa),
                  pw.Text('Tel: $telefonoEmpresa'),
                ],
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FACTURA ELECTRÓNICA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('SERIE: $serie'),
                    pw.Text('No.: $numero'),
                    pw.Text('NIT: $nitEmpresa'),
                    pw.Text('FECHA: $fechaStr'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Cliente
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _rowL('CLIENTE:', pedido['nombre'] ?? ''),
                _rowL('DIRECCIÓN:', pedido['direccion'] ?? ''),
                _rowL('NIT / DPI:', pedido['nitDpi'] ?? ''),
                _rowL('TEL:', pedido['telefono'] ?? ''),
                _rowL('EMAIL:', pedido['correo'] ?? ''),
                _rowL(
                  'PAGO:',
                  pedido['metodoPago'] == 'tarjeta'
                      ? "Tarjeta ${pedido['tarjeta']?['brand']} •••• ${pedido['tarjeta']?['last4']}"
                      : 'Efectivo contra entrega',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Tabla items
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['CANT', 'DESCRIPCIÓN', 'P.UNIT', 'SUBTOTAL'],
            cellAlignment: pw.Alignment.centerLeft,
            data: items.map((it) {
              final cant = (it['cantidad'] ?? 1).toString();
              final nom = (it['nombre'] ?? '').toString();
              final p = (it['precio'] ?? 0).toDouble();
              final sub = (it['subtotal'] ?? (p * (it['cantidad'] ?? 1)))
                  .toDouble();
              return [cant, nom, _q(p), _q(sub)];
            }).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300),
              bottom: const pw.BorderSide(),
              top: const pw.BorderSide(),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),

          // Totales
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('TOTAL EN LETRAS: ${_enLetras(total)}'),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'TOTAL: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _q(total),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Sujeto a IVA/ISR según aplique.'),
        ],
      ),
    );

    return pdf.save();
  }

  static String _q(num v) {
    return 'Q${v.toStringAsFixed(2)}';
  }

  // Versión corta para QTZ (puedes cambiar a librería de números a letras si quieres más precisión)
  static String _enLetras(num valor) {
    return 'QUETZALES ${valor.toStringAsFixed(2)}';
  }
}
