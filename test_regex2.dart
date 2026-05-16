void main() {
  var names = [
    "12345 - Sunlight Soap 100g - සන්ලයිට් සබන්",
    "001 Apple - ඇපල්",
    "12-343 CodeItem (කොඩ්)",
    "PRD001 - English Name 500ml",
    "4567 English Only",
    "1001-Sunlight 100g-සන්ලයිට්"
  ];
  
  for (var originalName in names) {
    String name = originalName.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
    name = name.replaceAll(RegExp(r'\s*-\s*$'), '').trim();
    name = name.replaceAll(RegExp(r'\(\s*\)'), '').trim();
    
    name = name.replaceAll(RegExp(r'^[\w\d]+\s*-\s*'), '').trim();
    name = name.replaceAll(RegExp(r'^\d+\s+'), '').trim();

    print("Original: $originalName");
    print("Cleaned: $name");
    print("---");
  }
}
