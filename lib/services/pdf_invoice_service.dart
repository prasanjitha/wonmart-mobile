import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sales_record_model.dart';
import '../models/sales_payment_model.dart';

class PdfInvoiceService {
  static final _currency = NumberFormat('#,##0.00', 'en_US');

  /// Generate a PDF invoice and return the bytes
  static Future<Uint8List> generateInvoice(SalesRecordModel record) async {
    final pdf = pw.Document();
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(record.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.red800,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'W',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            'WONMART',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red800,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Quality Distribution & Logistics',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: $date',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'ID: #${record.id.substring(0, 8).toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.red800, thickness: 2),
              pw.SizedBox(height: 10),

              // Shop info
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                record.shopName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200),
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red800),
                    children: [
                      _tableHeader('Product'),
                      _tableHeader('Qty'),
                      _tableHeader('Price'),
                      _tableHeader('Total'),
                    ],
                  ),
                  // Item rows
                  ...record.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _tableCell(item.productName),
                        _tableCell('${item.quantity} ${item.unit}'),
                        _tableCell('Rs ${_currency.format(item.price)}'),
                        _tableCell('Rs ${_currency.format(item.totalPrice)}'),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SUB TOTAL: Rs ${_currency.format(record.items.fold(0.0, (sum, i) => sum + i.totalPrice))}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'NET TOTAL: Rs ${_currency.format(record.totalAmount)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (record.totalReturnAmount > 0) ...[
                        pw.Text(
                          'RETURNS: Rs ${_currency.format(record.totalReturnAmount)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.red50,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'TOTAL DUE: ',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Rs ${_currency.format(record.totalAmount - record.totalReturnAmount)}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Authorized Signature',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Computer Generated Invoice',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'WONMART - Reliable Partner for Your Shop',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );

  static pw.Widget _tableCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
  );

  /// Print the invoice using the printing package (supports Bluetooth printers)
  static Future<void> printInvoice(SalesRecordModel record) async {
    final bytes = await generateInvoice(record);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Share invoice via WhatsApp
  static Future<void> shareViaWhatsApp(
    SalesRecordModel record,
    String phone,
  ) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hello! Please find your invoice for order '
      '#${record.id.substring(0, 8).toUpperCase()} '
      'from Wonmart. Total: Rs ${_currency.format(record.totalAmount)}',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Show the share/print dialog using the system print sheet
  static Future<void> shareOrPrint(SalesRecordModel record) async {
    final bytes = await generateInvoice(record);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'invoice_${record.id.substring(0, 8)}_${record.shopName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generate a PDF payment receipt and return the bytes
  static Future<Uint8List> generatePaymentReceipt(
    SalesPaymentModel payment,
    SalesRecordModel record, {
    pw.ImageProvider? logo,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt);
    final subTotal = record.items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final prevPaid = record.paidAmount - payment.payAmount;
    final grandTotalReceived = record.paidAmount;
    final balance =
        record.totalAmount - record.totalReturnAmount - grandTotalReceived;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null)
                        pw.Container(
                          height: 60,
                          width: 150,
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Text(
                          'Won Mart',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
                          ),
                        ),
                      pw.Text(
                        'Payment Receipt',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Won Mart (Pvt) Ltd',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        '206, Rolawatta, Meegama, Dharga Town',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Email: info.wonm@gmail.com',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Phone: +94 713 148 203',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 20),

              // Info Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SHOP DETAILS',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Name: ${payment.shopName}'),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'AGENT DETAILS',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Name: ${payment.agentName}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECEIPT DETAILS',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Receipt ID: #${payment.id.toUpperCase().substring(0, 8)}',
                      ),
                      pw.Text(
                        'Order ID: #${payment.salesRecordId.toUpperCase().substring(0, 8)}',
                      ),
                      pw.Text('Date: $date'),
                      pw.Text('Status: ${payment.status.toUpperCase()}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Summary Section (Matching mockup)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SUMMARY',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryRow('SUB TOTAL', _currency.format(subTotal)),
                      _summaryRow(
                        'NET TOTAL',
                        _currency.format(record.totalAmount),
                      ),
                      if (record.totalReturnAmount > 0)
                        _summaryRow(
                          'RETURNS',
                          '- ${_currency.format(record.totalReturnAmount)}',
                        ),
                      _summaryRow(
                        'TOTAL DUE',
                        _currency.format(
                          record.totalAmount - record.totalReturnAmount,
                        ),
                        isBold: true,
                      ),
                      _summaryRow(
                        'PREV. RECEIVED TOTAL',
                        _currency.format(prevPaid),
                      ),
                      _summaryRow(
                        'PAID ON ${DateFormat('M/d/y').format(payment.createdAt)}',
                        _currency.format(payment.payAmount),
                        isBold: true,
                        color: PdfColors.green800,
                      ),
                      _summaryRow(
                        'GRAND TOTAL RECEIVED',
                        _currency.format(grandTotalReceived),
                        isBold: true,
                      ),
                      pw.Divider(thickness: 1, color: PdfColors.black),
                      _summaryRow(
                        'BALANCE',
                        _currency.format(balance),
                        isBold: true,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signatureLine('Agent Signature'),
                  _signatureLine('Customer Signature'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: fontSize,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  /// Print payment receipt
  static Future<void> printPaymentReceipt(
    SalesPaymentModel payment,
    SalesRecordModel record, {
    pw.ImageProvider? logo,
  }) async {
    final bytes = await generatePaymentReceipt(payment, record, logo: logo);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Share payment receipt
  static Future<void> sharePaymentReceipt(
    SalesPaymentModel payment,
    SalesRecordModel record, {
    pw.ImageProvider? logo,
  }) async {
    final bytes = await generatePaymentReceipt(payment, record, logo: logo);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'receipt_${payment.shopName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(payment.createdAt)}.pdf',
    );
  }
}
