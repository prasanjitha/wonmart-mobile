void main() {
  String name = "Cheese Str Fry - 080427";
  name = name.replaceAll(RegExp(r'\s*-\s*[\w\d]+\s*$'), '').trim();
  print(name);
}
