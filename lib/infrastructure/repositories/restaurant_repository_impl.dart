import 'dart:convert';
import '../../domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/table.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/remote_datasource.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RemoteDataSource dataSource;
  RestaurantRepositoryImpl(this.dataSource);

  @override
  Future<List<RestaurantTable>> getTables() async {
    final jsonStr = await dataSource.getString('tables');
    if (jsonStr == null) return [];
    Iterable l = jsonDecode(jsonStr);
    return List<RestaurantTable>.from(l.map((m) => RestaurantTable.fromJson(m)));
  }

  @override
  Future<void> saveTables(List<RestaurantTable> tables) {
    return dataSource.postData('tables', tables.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<Product>> getMenu() async {
    final jsonStr = await dataSource.getString('menu');
    if (jsonStr == null) return [];
    Iterable l = jsonDecode(jsonStr);
    return List<Product>.from(l.map((m) => Product.fromJson(m)));
  }

  @override
  Future<void> saveMenu(List<Product> menu) {
    return dataSource.postData('menu', menu.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<Order>> getOrders() async {
    final jsonStr = await dataSource.getString('orders');
    if (jsonStr == null) return [];
    Iterable l = jsonDecode(jsonStr);
    return List<Order>.from(l.map((m) => Order.fromJson(m)));
  }

  @override
  Future<void> saveOrders(List<Order> orders) {
    return dataSource.postData('orders', orders.map((e) => e.toJson()).toList());
  }

  @override
  Future<int> getOrderCounter() async {
    return (await dataSource.getInt('counter')) ?? 1;
  }

  @override
  Future<void> saveOrderCounter(int counter) async {
    // In this implementation, the counter is handled server-side or implicitly.
    // We don't necessarily need to save it if the server calculates it from Max(OrderNumber).
  }
}
