with open('lib/services/pdf_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Change pw.Page to pw.MultiPage
content = content.replace(
    """    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [""",
    """    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 40),
        build: (context) => [""",
    1
)

# 2. Fix the closing: remove the Column close and function close, just close the list
content = content.replace(
    """            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader""",
    """        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader""",
    1
)

with open('lib/services/pdf_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Switched to MultiPage successfully!")
