import re

with open('lib/services/pdf_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Locate the items rendering block
old_items_block = """              // ── Items ── each row is a full-width pw.Table row
              ...record.items.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.productName, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 1),
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
                            pw.Text(
                              '  ${item.productId.substring(item.productId.length > 6 ? item.productId.length - 6 : 0)}',
                              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${item.quantity}',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              formatNumber(item.agentPrice),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              formatNumber(item.totalAgentPrice),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),"""

new_items_block = """              // ── Items ── each row is a full-width pw.Table row
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
                                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                                maxLines: 3,
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '  ${item.productId.substring(item.productId.length > 6 ? item.productId.length - 6 : 0)}',
                                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          pw.Text(
                            '${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            formatNumber(item.agentPrice),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            formatNumber(item.totalAgentPrice),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),"""

if old_items_block in content:
    content = content.replace(old_items_block, new_items_block)
    with open('lib/services/pdf_service.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Items block successfully replaced.")
else:
    print("ERROR: Could not find the exact old_items_block to replace.")
