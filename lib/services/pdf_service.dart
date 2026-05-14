import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sales_record_model.dart';
import '../models/shop_model.dart';
import '../services/store_service.dart';

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
    String? paymentType,
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
          _buildInfoSection(
            record,
            agentName,
            agentId,
            shop,
            effectiveStatus,
            paymentType,
          ),
          pw.SizedBox(height: 30),
          _buildItemsTable(record.items),
          pw.SizedBox(height: 30),
          _buildSummary(
            record,
            effectivePaidAmount,
            effectiveStatus,
            paymentType,
          ),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateThermalInvoice({
    required SalesRecordModel record,
    required String agentName,
    required String agentId,
    ShopModel? shop,
    double? paidAmount,
    String? paymentStatus,
    String? paymentType,
    pw.ImageProvider? logo,
  }) async {
    final pdf = pw.Document();

    final effectivePaidAmount = paidAmount ?? record.paidAmount;

    // Calculate values
    final totalNoItems = record.items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final grossTotal = record.items.fold(
      0.0,
      (sum, item) => sum + item.totalAgentPrice,
    );
    final returnAmount = record.totalReturnAmount;
    final totalValue = grossTotal - returnAmount;
    final change = effectivePaidAmount - totalValue;

    // Format numbers without currency symbol
    String formatNumber(double value) {
      return value.toStringAsFixed(2);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 40),
        build: (context) => [
          // ── Header ── centered, full-width
          pw.SizedBox(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 120,
                    width: 300,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Text(
                    'WON MART',
                    style: pw.TextStyle(
                      fontSize: 54,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.Text(
                  'Quality Distribution & Logistics',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '206, Rolawatta, Meegama',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '0713148203',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
          pw.SizedBox(height: 6),

          // ── Shop name ── centered, full-width
          pw.SizedBox(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  shop?.name ?? record.shopName,
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (shop?.address != null && shop!.address.isNotEmpty)
                  pw.Text(
                    shop.address,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
          pw.SizedBox(height: 6),

          // ── Invoice details ── left-aligned
          pw.Text(
            'Invoice: ${record.id.substring(0, 8)}',
            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Staff: $agentName',
            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Time: ${DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt)}",
            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),

          // ── Table header ── full-width via FlexColumnWidth
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(1.0),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      'Qty',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      'Price',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      'Amt',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 2),

          // ── Items ── each row is a full-width pw.Table row
          ...record.items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(1.0),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.productName,
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            maxLines: 3,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '  ${item.productId.substring(item.productId.length > 6 ? item.productId.length - 6 : 0)}',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        '${item.quantity}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        formatNumber(item.agentPrice),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        formatNumber(item.totalAgentPrice),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),

          // ── Items count & Subtotal ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Items: $totalNoItems',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Subtotal:',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                formatNumber(grossTotal),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          if (returnAmount > 0) ...[
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Returns:',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '-${formatNumber(returnAmount)}',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
          pw.SizedBox(height: 4),

          // ── Total ── larger, bold
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total:',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                formatNumber(totalValue),
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Cash:',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                formatNumber(effectivePaidAmount),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Change:',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                formatNumber(change != 0 ? change.abs() : 0),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
          pw.SizedBox(height: 6),

          // ── Footer ── centered, full-width
          pw.SizedBox(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Thank You',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.BarcodeWidget(
                  data: record.id,
                  width: 250,
                  height: 80,
                  barcode: pw.Barcode.code128(),
                  drawText: false,
                ),
              ],
            ),
          ),
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
    String? paymentType,
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
              pw.Text('Invoice No: ${record.id}'),
              pw.Text(
                'Date & Time: ${DateFormat('M/d/y h:mm:ss a').format(record.createdAt)}',
              ),
              pw.Text('Payment Type: ${paymentType ?? 'CASH'}'),
              pw.Text('Status: ${status.toUpperCase()}'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<SalesRecordItem> items) {
    final headers = [
      'Item Code',
      'Description',
      'MRP',
      'Order Qty',
      'Price',
      'Value',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: List<List<dynamic>>.generate(items.length, (index) {
        final item = items[index];
        return [
          item.productId.length > 10
              ? '${item.productId.substring(0, 10)}...'
              : item.productId,
          item.productName,
          _currency.format(item.price),
          item.quantity,
          _currency.format(item.agentPrice),
          _currency.format(item.totalAgentPrice),
        ];
      }),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: tableHeaderGray),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(
    SalesRecordModel record,
    double paidAmount,
    String status,
    String? paymentType,
  ) {
    final totalNoItems = record.items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final grossTotal = record.items.fold(
      0.0,
      (sum, item) => sum + item.totalAgentPrice,
    );
    final returnAmount = record.totalReturnAmount;
    final totalValue = grossTotal - returnAmount;
    final balance = totalValue - paidAmount;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildSummaryRow('Total No. Items', totalNoItems.toString()),
            _buildSummaryRow('Gross Total', _currency.format(grossTotal)),
            _buildSummaryRow('Return Amount', _currency.format(returnAmount)),
            _buildSummaryRow(
              'Total Value',
              _currency.format(totalValue),
              isBold: true,
            ),
            // _buildSummaryRow(
            //   'Payment Type',
            //   '${paymentType ?? 'CASH'} - ${status.replaceAll('_', ' ').toUpperCase()}',
            // ),
            _buildSummaryRow('Payment Received', _currency.format(paidAmount)),
            _buildSummaryRow(
              'Balance',
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
    String? paymentType,
    pw.ImageProvider? logo,
  }) async {
    final pdfBytes = await generateInvoice(
      record: record,
      agentName: agentName,
      agentId: agentId,
      shop: shop,
      paidAmount: paidAmount,
      paymentStatus: paymentStatus,
      paymentType: paymentType,
      logo: logo,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'invoice_${record.shopName.replaceAll(' ', '_')}_${record.id.substring(0, 8)}.pdf',
    );
  }

  static Future<String?> generateAndSaveInventorySummary(
    String agentId,
    String agentName,
  ) async {
    try {
      final items = await StoreService().getAgentStore(agentId);

      final pdf = pw.Document();
      final dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timeString = DateFormat('hh:mm a').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              'Daily Inventory Summary',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: primaryRed,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Agent Name: $agentName'),
            pw.Text('Date & Time: $dateString, $timeString'),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Product Name', 'Quantity', 'Unit'],
              data: List<List<dynamic>>.generate(items.length, (index) {
                final item = items[index];
                return [item.productName, item.quantity.toString(), item.unit];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              headerDecoration: const pw.BoxDecoration(color: tableHeaderGray),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      // Determine directory to save
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) return null;

      final filePath = '${dir.path}/Inventory_Summary_$dateString.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      return null;
    }
  }
}
