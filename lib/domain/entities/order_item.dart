import 'product.dart';

class OrderItem {
  Product product;
  int quantity;
  String note;
  OrderItem({required this.product, required this.quantity, this.note = ""});
  double get total => product.price * quantity;
  Map<String, dynamic> toJson() =>
      {'product': product.toJson(), 'quantity': quantity, 'note': note};
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        product: Product.fromJson(json['product']),
        quantity: json['quantity'] as int,
        note: json['note'] ?? "",
      );
}
