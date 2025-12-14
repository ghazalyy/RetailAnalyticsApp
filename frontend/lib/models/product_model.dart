class Product {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Tanpa Nama',
      category: json['category'] ?? 'Umum',
      subCategory: json['subCategory'] ?? '-',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }
}