import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

    const primary = PdfColor.fromInt(0xFF6A00FF);
    const secondary = PdfColors.grey300;

    pw.Widget _rowL(String l, String v) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$l ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primary),
          ),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          textDirection: pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          // ==== Header ====
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      empresa,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      direccionEmpresa,
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.Text(
                      'Tel: $telefonoEmpresa',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FACTURA ELECTRÓNICA',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'SERIE: $serie',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.Text(
                      'No.: $numero',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.Text(
                      'NIT: $nitEmpresa',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.Text(
                      'FECHA: $fechaStr',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ==== Datos Cliente ====
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey400),
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

          pw.SizedBox(height: 16),

          // ==== Tabla items ====
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: primary),
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
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: secondary),
              bottom: const pw.BorderSide(),
              top: const pw.BorderSide(),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 16),

          // ==== Totales ====
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'TOTAL EN LETRAS: ${_numeroALetrasConCentavos(total)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'TOTAL: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      _q(total),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Text(
            'Sujeto a IVA/ISR según aplique.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _q(num v) => 'Q${v.toStringAsFixed(2)}';

  /// Convierte número con decimales a letras (quetzales + centavos)
  static String _numeroALetrasConCentavos(num valor) {
    final enteros = valor.floor();
    final centavos = ((valor - enteros) * 100).round();

    final letrasEnteros = _convertirEnteros(enteros);

    if (centavos > 0) {
      return '$letrasEnteros CON ${centavos.toString().padLeft(2, '0')}/100';
    } else {
      return letrasEnteros;
    }
  }

  /// Convierte solo la parte entera a letras (soporta hasta millones)
  static String _convertirEnteros(int valor) {
    if (valor == 0) return 'CERO QUETZALES';
    if (valor == 1) return 'UN QUETZAL';

    String texto = _convertirGrupo(valor);
    return '$texto QUETZALES';
  }

  static String _convertirGrupo(int valor) {
    const unidades = [
      '',
      'UNO',
      'DOS',
      'TRES',
      'CUATRO',
      'CINCO',
      'SEIS',
      'SIETE',
      'OCHO',
      'NUEVE',
    ];
    const decenas = [
      '',
      'DIEZ',
      'VEINTE',
      'TREINTA',
      'CUARENTA',
      'CINCUENTA',
      'SESENTA',
      'SETENTA',
      'OCHENTA',
      'NOVENTA',
    ];
    const especiales = {
      11: 'ONCE',
      12: 'DOCE',
      13: 'TRECE',
      14: 'CATORCE',
      15: 'QUINCE',
      16: 'DIECISÉIS',
      17: 'DIECISIETE',
      18: 'DIECIOCHO',
      19: 'DIECINUEVE',
    };
    const centenas = [
      '',
      'CIEN',
      'DOSCIENTOS',
      'TRESCIENTOS',
      'CUATROCIENTOS',
      'QUINIENTOS',
      'SEISCIENTOS',
      'SETECIENTOS',
      'OCHOCIENTOS',
      'NOVECIENTOS',
    ];

    if (valor < 10) return unidades[valor];
    if (especiales.containsKey(valor)) return especiales[valor]!;
    if (valor < 100) {
      final d = valor ~/ 10;
      final u = valor % 10;
      return '${decenas[d]}${u > 0 ? ' Y ${unidades[u]}' : ''}';
    }
    if (valor < 1000) {
      final c = valor ~/ 100;
      final resto = valor % 100;
      if (resto == 0) return centenas[c];
      if (c == 1) return 'CIENTO ${_convertirGrupo(resto)}';
      return '${centenas[c]} ${_convertirGrupo(resto)}';
    }
    if (valor < 1000000) {
      final miles = valor ~/ 1000;
      final resto = valor % 1000;
      final milesTexto = (miles == 1) ? 'MIL' : '${_convertirGrupo(miles)} MIL';
      return resto == 0 ? milesTexto : '$milesTexto ${_convertirGrupo(resto)}';
    }
    if (valor < 1000000000) {
      final millones = valor ~/ 1000000;
      final resto = valor % 1000000;
      final millonTexto = (millones == 1)
          ? 'UN MILLÓN'
          : '${_convertirGrupo(millones)} MILLONES';
      return resto == 0
          ? millonTexto
          : '$millonTexto ${_convertirGrupo(resto)}';
    }

    return valor.toString();
  }
}
