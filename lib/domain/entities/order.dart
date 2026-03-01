import 'order_item.dart';

class Order {
  String id;
  int orderNumber;
  int tableNumber;
  String waiterName;
  String? clientName;
  String? clientDocument;
  List<OrderItem> items;
  bool isCompleted;
  DateTime timestamp;
  Order({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    required this.waiterName,
    this.clientName,
    this.clientDocument,
    required this.items,
    this.isCompleted = false,
    required this.timestamp,
  });
  double get total => items.fold(0, (sum, item) => sum + item.total);
  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'tableNumber': tableNumber,
        'waiterName': waiterName,
        'clientName': clientName,
        'clientDocument': clientDocument,
        'items': items.map((i) => i.toJson()).toList(),
        'isCompleted': isCompleted,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as int? ?? 0,
        tableNumber: json['tableNumber'] as int,
        waiterName: json['waiterName'] as String,
        clientName: json['clientName'] as String?,
        clientDocument: json['clientDocument'] as String?,
        items: List<OrderItem>.from(
            json['items'].map((x) => OrderItem.fromJson(x))),
        isCompleted: json['isCompleted'] as bool,
        timestamp: DateTime.parse(json['timestamp']),
      );
}
