class Product {
  String id;
  String name;
  double price;
  String? image;
  int sortOrder;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'sortOrder': sortOrder,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        image: json['image'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
