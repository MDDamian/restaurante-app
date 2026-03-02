class Category {
  final String id;
  String name;
  String? image; // Base64
  int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.image,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'sortOrder': sortOrder,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        image: json['image'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
