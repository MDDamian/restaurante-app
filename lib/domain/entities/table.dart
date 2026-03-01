class RestaurantTable {
  int id;
  String name;
  RestaurantTable({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
