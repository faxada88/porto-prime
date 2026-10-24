/// A selection always identifies one real catalogue item; no price or stock is inferred.
enum IceType {
 cubes('Cubos'), crushed('Moído');
 const IceType(this.label);
 final String label;
}


/// Weight is useful even when the Admin product name does not specify ice type.
int? icePackageKilograms(dynamic value) {
 if (value is! Map || value['id'] == null) return null;
 final name = (value['name'] ?? '').toString().toLowerCase();
 final matches = RegExp(r'(?:^|[^0-9])(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilogramas?)\b').allMatches(name);
 final weights = matches.map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
  .whereType<double>().toSet();
 if (weights.length != 1) return null;
 final weight = weights.single;
 return weight > 0 && weight == weight.roundToDouble() ? weight.toInt() : null;
}

class IceProductOption {
 const IceProductOption({required this.product, required this.kilograms, required this.type});
 final Map<dynamic, dynamic> product;
 final int kilograms;
 final IceType type;
 String get id => product['id'].toString();

 static IceProductOption? fromProduct(dynamic value) {
  if (value is! Map || value['id'] == null) return null;
  final name = (value['name'] ?? '').toString().toLowerCase()
   .replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u')
   .replaceAll('ã', 'a').replaceAll('é', 'e');
  final weight = icePackageKilograms(value);
  if (weight == null) return null;
  final cubes = RegExp(r'\bcubos?\b').hasMatch(name);
  final crushed = RegExp(r'\b(moid[oa]s?|triturad[oa]s?|picad[oa]s?)\b').hasMatch(name);
  if (cubes == crushed) return null;
  return IceProductOption(product: value, kilograms: weight,
   type: cubes ? IceType.cubes : IceType.crushed);
 }
}

List<IceProductOption> iceOptionsFor(Iterable<dynamic> products, String categoryName) => products
 .where((p) => p is Map && p['category']?['name'] == categoryName && p['archived'] != true)
 .map(IceProductOption.fromProduct).whereType<IceProductOption>().toList();
