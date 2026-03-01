import '../entities/product.dart';
import '../entities/order.dart';
import '../entities/table.dart';

abstract class RestaurantRepository {
  Future<List<RestaurantTable>> getTables();
  Future<void> saveTables(List<RestaurantTable> tables);
  
  Future<List<Product>> getMenu();
  Future<void> saveMenu(List<Product> menu);
  
  Future<List<Order>> getOrders();
  Future<void> saveOrders(List<Order> orders);
  
  Future<int> getOrderCounter();
  Future<void> saveOrderCounter(int counter);
}
