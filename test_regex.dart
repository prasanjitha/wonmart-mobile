void main() {
  var names = [
    "12345 - Sunlight Soap 100g - සන්ලයිට් සබන්",
    "001 Apple - ඇපල්",
    "12-343 CodeItem (කොඩ්)",
    "PRD001 - English Name 500ml",
    "4567 English Only"
  ];
  
  for (var name in names) {
    // 1. Remove non-ASCII (removes Sinhala/Tamil)
    var asciiOnly = name.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
    // 2. Remove trailing/leading hyphens or extra spaces left after removing Sinhala
    asciiOnly = asciiOnly.replaceAll(RegExp(r'\s*-\s*$'), '').trim();
    
    // 3. To remove "numbers+code", maybe remove leading digits and hyphens/spaces.
    // The user said "numbers+code kella ain karanna", maybe they have a specific format.
    // If it's always leading alphanumeric before a hyphen:
    var withoutCode = asciiOnly.replaceAll(RegExp(r'^.*?-\s*'), '');
    if (withoutCode == asciiOnly) {
      // If no hyphen, just remove leading digits
      withoutCode = asciiOnly.replaceAll(RegExp(r'^[\d\s]+'), '');
    }
    
    print("Original: $name");
    print("Cleaned: $withoutCode");
    print("---");
  }
}
