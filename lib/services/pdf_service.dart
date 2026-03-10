import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/sales_record_model.dart';
import '../models/shop_model.dart';

class PdfService {
  static const PdfColor primaryRed = PdfColor.fromInt(0xFFC62828);
  static const PdfColor tableHeaderGray = PdfColor.fromInt(0xFFEEEEEE);
  static final _currency = NumberFormat('#,##0.00', 'en_US');

  static Future<Uint8List> generateInvoice({
    required SalesRecordModel record,
    required String agentName,
    required String agentId,
    ShopModel? shop,
    double? paidAmount,
    String? paymentStatus,
    pw.ImageProvider? logo,
  }) async {
    final pdf = pw.Document();

    // Use custom values if provided, else fallback to record values
    final effectivePaidAmount = paidAmount ?? record.paidAmount;
    final effectiveStatus = paymentStatus ?? record.paymentStatus;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(logo),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 20),
          _buildInfoSection(record, agentName, agentId, shop, effectiveStatus),
          pw.SizedBox(height: 30),
          _buildItemsTable(record.items),
          pw.SizedBox(height: 30),
          _buildSummary(record, effectivePaidAmount),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Container(
                height: 80,
                width: 200,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Text(
                'Won Mart',
                style: pw.TextStyle(
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryRed,
                ),
              ),
            pw.Text(
              'Invoice',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Won Mart (Pvt) Ltd',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('206, Rolawatta, Meegama, Dharga Town'),
            pw.Text('Email: info.wonm@gmail.com'),
            pw.Text('Phone: +94 713 148 203'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoSection(
    SalesRecordModel record,
    String agentName,
    String agentId,
    ShopModel? shop,
    String status,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DESTRIBUTOR / AGENT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Name: $agentName'),
              pw.Text('ID: $agentId'),
              if (shop != null) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'SHOP DETAILS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Name: ${shop.name}'),
                pw.Text('Address: ${shop.address}'),
                pw.Text('Phone: ${shop.phone}'),
              ],
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE DETAILS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date & Time: ${DateFormat('M/d/y h:mm:ss a').format(record.createdAt)}',
              ),
              pw.Text('Payment Type: CASH'),
              pw.Text('Status: ${status.toUpperCase()}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<SalesRecordItem> items) {
    final headers = [
      'No',
      'SKU',
      'Item Name',
      'QTY',
      'Rate (Rs)',
      'Discount',
      'Net Value (Rs)',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: List<List<dynamic>>.generate(items.length, (index) {
        final item = items[index];
        return [
          index + 1,
          item.productId.length > 8
              ? '${item.productId.substring(0, 8)}...'
              : item.productId,
          item.productName,
          item.quantity,
          _currency.format(item.price),
          '${item.marginPercentage.toStringAsFixed(0)}%',
          _currency.format(item.totalAgentPrice),
        ];
      }),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: tableHeaderGray),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(SalesRecordModel record, double paidAmount) {
    final subTotal = record.items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final balance = record.totalAmount - paidAmount;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(width: 100),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildSummaryRow('SUB TOTAL', _currency.format(subTotal)),
            _buildSummaryRow(
              'NET TOTAL',
              _currency.format(record.totalAmount),
              isBold: true,
            ),
            _buildSummaryRow('PAYMENT RECEIVED', _currency.format(paidAmount)),
            _buildSummaryRow(
              'BALANCE',
              _currency.format(balance),
              isBold: true,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureField('Invoiced by'),
        _buildSignatureField('Customer Signature'),
        _buildSignatureField('Authorized Signature'),
      ],
    );
  }

  static pw.Widget _buildSignatureField(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static Future<void> shareOrPrintInvoice({
    required SalesRecordModel record,
    required String agentName,
    required String agentId,
    ShopModel? shop,
    double? paidAmount,
    String? paymentStatus,
    pw.ImageProvider? logo,
  }) async {
    final pdfBytes = await generateInvoice(
      record: record,
      agentName: agentName,
      agentId: agentId,
      shop: shop,
      paidAmount: paidAmount,
      paymentStatus: paymentStatus,
      logo: logo,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'invoice_${record.shopName.replaceAll(' ', '_')}_${record.id.substring(0, 8)}.pdf',
    );
  }
}
