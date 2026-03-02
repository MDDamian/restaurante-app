import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/entities/category.dart';
import '../domain/entities/order.dart';
import '../domain/entities/order_item.dart';
import '../domain/entities/product.dart';
import '../domain/entities/table.dart';
import '../domain/repositories/restaurant_repository.dart';
import '../infrastructure/repositories/restaurant_repository_impl.dart';
import '../core/utils/initial_data.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantRepository repository;
  List<Product> _menu = [];
  List<Category> _categories = [];
  List<Order> _orders = [];
  bool _isLocalMode = false; // Based on actual repository implementation

  RestaurantProvider(this.repository) {
    _init();
  }

  Future<void> _init() async {
    _updateConnectionMode();
    _initializeCategories();
    await loadMenu();
  }

  bool get isLocalMode => _isLocalMode;
  List<Category> get categories => _categories;
  List<Product> get menu => _menu;
  List<Order> get orders => _orders;

  List<Order> get pendingOrders => _orders.where((o) => !o.isCompleted).toList();
  List<Order> get completedOrders => _orders.where((o) => o.isCompleted).toList();

  List<String> get knownWaiters {
    return _orders.map((o) => o.waiterName).where((name) => name.isNotEmpty).toSet().toList();
  }

  void _updateConnectionMode() {
    // In this project, we seem to be using RestaurantRepositoryImpl which connects to RemoteDataSource
    _isLocalMode = false; 
    notifyListeners();
  }

  void _initializeCategories() {
    _categories = [
      Category(id: 'cat1', name: 'Platos Fuertes', sortOrder: 1, image: InitialData.imgPlatosFuertes),
      Category(id: 'cat2', name: 'Bebidas', sortOrder: 2, image: InitialData.imgBebidas),
      Category(id: 'cat3', name: 'Entradas', sortOrder: 0, image: InitialData.imgEntradas),
    ];
  }

  // Providing a getter that the UI expects
  List<RestaurantTable> get tables => _tempTables;
  List<RestaurantTable> _tempTables = [];

  List<Order> getPendingOrdersForTable(num tableId) {
    return _orders.where((o) => o.tableNumber == tableId && !o.isCompleted).toList();
  }

  Future<void> loadMenu() async {
    _menu = await repository.getMenu();
    _orders = await repository.getOrders();
    _tempTables = await repository.getTables();
    notifyListeners();
  }

  // UI expects (num tableId, String waiterName, String? clientName, String? clientDocument, List<OrderItem> items)
  void addOrder(num tableId, String waiterName, String? clientName, String? clientDocument, List<OrderItem> items) async {
    int nextOrderNumber = (await repository.getOrderCounter()) + 1;
    await repository.saveOrderCounter(nextOrderNumber);

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: nextOrderNumber,
      tableNumber: tableId.toInt(),
      waiterName: waiterName,
      clientName: clientName,
      clientDocument: clientDocument,
      items: items,
      timestamp: DateTime.now(),
      isCompleted: false,
    );
    _orders.add(order);
    _saveDataLocally();
    notifyListeners();
  }

  // UI expects (String orderId, String waiterName, String? clientName, String? clientDocument, List<OrderItem> items)
  void updateOrder(String orderId, String waiterName, String? clientName, String? clientDocument, List<OrderItem> items) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        waiterName: waiterName,
        clientName: clientName,
        clientDocument: clientDocument,
        items: items,
      );
      _saveDataLocally();
      notifyListeners();
    }
  }

  void completeOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(isCompleted: true);
      _saveDataLocally();
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    _menu.add(product);
    _saveDataLocally();
    notifyListeners();
  }

  void editProduct(Product product) {
    final index = _menu.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _menu[index] = product;
      _saveDataLocally();
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    _menu.removeWhere((p) => p.id == productId);
    _saveDataLocally();
    notifyListeners();
  }

  void addCategory(Category category) {
    category.sortOrder = _categories.length;
    _categories.add(category);
    notifyListeners();
  }

  void editCategory(String id, String newName, String? newImage) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].name = newName;
      _categories[index].image = newImage;
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void updateCategorySortOrder(List<Category> newOrder) {
    _categories = newOrder;
    for (int i = 0; i < _categories.length; i++) {
      _categories[i].sortOrder = i;
    }
    notifyListeners();
  }

  void addTable(String name) async {
    // We use the local cache instead of re-fetching to avoid state loss/race conditions
    int nextId = 1;
    if (_tempTables.isNotEmpty) {
      nextId = _tempTables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    
    _tempTables.add(RestaurantTable(id: nextId, name: name));
    await repository.saveTables(_tempTables);
    notifyListeners();
  }

  void removeTable(num tableNum) async {
    _tempTables.removeWhere((t) => t.id == tableNum);
    await repository.saveTables(_tempTables);
    notifyListeners();
  }

  void _saveDataLocally() {
    repository.saveMenu(_menu);
    repository.saveOrders(_orders);
  }

  Future<void> shareOrder(Order order) async {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('ORDEN - Mesa ${order.tableNumber}');
    buffer.writeln('Mesero: ${order.waiterName}');
    buffer.writeln('-------------------------');
    for (var item in order.items) {
      buffer.writeln('${item.quantity}x ${item.product.name} - \$${(item.product.price * item.quantity).toStringAsFixed(2)}');
    }
    buffer.writeln('-------------------------');
    buffer.writeln('TOTAL: \$${order.total.toStringAsFixed(2)}');

    final String message = buffer.toString();
    final String whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        await Share.share(message);
      }
    } catch (e) {
      await Share.share(message);
    }
  }

  Future<void> shareDailySummary() async {
    final summary = "Resumen del día...";
    await Share.share(summary);
  }
}
