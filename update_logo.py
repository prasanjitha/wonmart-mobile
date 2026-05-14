with open('lib/services/pdf_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_logo_block = """                    pw.Text(
                      'WON MART',
                      style: pw.TextStyle(fontSize: 54, fontWeight: pw.FontWeight.bold),
                    ),"""

new_logo_block = """                    if (logo != null)
                      pw.Container(
                        height: 120,
                        width: 300,
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text(
                        'WON MART',
                        style: pw.TextStyle(fontSize: 54, fontWeight: pw.FontWeight.bold),
                      ),"""

if old_logo_block in content:
    content = content.replace(old_logo_block, new_logo_block, 1)
    with open('lib/services/pdf_service.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Logo block updated!")
else:
    print("ERROR: old_logo_block not found.")
