class RestaurantTable {
  final int id;
  final String name;

  RestaurantTable({required this.id, required this.name});

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  RestaurantTable copyWith({int? id, String? name}) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
