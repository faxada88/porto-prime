class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
  });
  final String id, name, email, role, status;
  final String? phone;
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'].toString(),
    name: j['name']?.toString() ?? '',
    email: j['email']?.toString() ?? '',
    phone: j['phone']?.toString(),
    role: j['role']?.toString() ?? 'CUSTOMER',
    status: j['status']?.toString() ?? 'ACTIVE',
  );
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });
  final String id, name, slug;
  final String? imageUrl;
  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
    id: j['id'].toString(),
    name: j['name']?.toString() ?? '',
    slug: j['slug']?.toString() ?? '',
    imageUrl: j['imageUrl']?.toString(),
  );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.imageUrl,
  });
  final String id, categoryId, name;
  final double price;
  final int stock;
  final String? description, imageUrl;
  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id: j['id'].toString(),
    categoryId: j['categoryId']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    price: double.tryParse(j['price'].toString()) ?? 0,
    stock: int.tryParse(j['stock'].toString()) ?? 0,
    description: j['description']?.toString(),
    imageUrl: j['imageUrl']?.toString(),
  );
}

class AddressModel {
  const AddressModel({
    required this.id,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.postalCode,
    this.label,
    this.complement,
  });
  final String id, street, number, neighborhood, city, state, postalCode;
  final String? label, complement;
  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'].toString(),
    street: j['street']?.toString() ?? '',
    number: j['number']?.toString() ?? '',
    neighborhood: j['neighborhood']?.toString() ?? '',
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    postalCode: j['postalCode']?.toString() ?? '',
    label: j['label']?.toString(),
    complement: j['complement']?.toString(),
  );
}

class CartLine {
  CartLine({required this.product, this.quantity = 1});
  final ProductModel product;
  int quantity;
  double get total => product.price * quantity;
}
