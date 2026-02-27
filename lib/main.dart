import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (context) => RestaurantProvider(prefs),
      child: const RestauranteApp(),
    ),
  );
}

class RestauranteApp extends StatelessWidget {
  const RestauranteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFB7317),
          primary: const Color(0xFFFB7317),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

// ================= MODELOS DE DATOS ================= //

class Product {
  String id;
  String name;
  double price;
  Product({required this.id, required this.name, required this.price});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
      );
}

class OrderItem {
  Product product;
  int quantity;
  String note;
  OrderItem({required this.product, required this.quantity, this.note = ""});
  double get total => product.price * quantity;
  Map<String, dynamic> toJson() => {'product': product.toJson(), 'quantity': quantity, 'note': note};
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        product: Product.fromJson(json['product']),
        quantity: json['quantity'] as int,
        note: json['note'] ?? "",
      );
}

class Order {
  String id;
  int tableNumber;
  String waiterName;
  List<OrderItem> items;
  bool isCompleted;
  DateTime timestamp;
  Order({
    required this.id,
    required this.tableNumber,
    required this.waiterName,
    required this.items,
    this.isCompleted = false,
    required this.timestamp,
  });
  double get total => items.fold(0, (sum, item) => sum + item.total);
  Map<String, dynamic> toJson() => {
        'id': id,
        'tableNumber': tableNumber,
        'waiterName': waiterName,
        'items': items.map((i) => i.toJson()).toList(),
        'isCompleted': isCompleted,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        tableNumber: json['tableNumber'] as int,
        waiterName: json['waiterName'] as String,
        items: List<OrderItem>.from(json['items'].map((x) => OrderItem.fromJson(x))),
        isCompleted: json['isCompleted'] as bool,
        timestamp: DateTime.parse(json['timestamp']),
      );
}

// ================= PROVEEDOR DE ESTADO ================= //

class RestaurantProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  List<int> tables = [1, 2];

  List<Product> menu = [
    Product(id: '1', name: 'Hamburguesa Clásica', price: 12.99),
    Product(id: '2', name: 'Papas Fritas', price: 3.50),
    Product(id: '3', name: 'Gaseosa Mediana', price: 2.50),
  ];

  List<Order> orders = [];

  RestaurantProvider(this.prefs) {
    _loadData();
  }

  void _loadData() {
    try {
      final tablesJson = prefs.getString('tables');
      if (tablesJson != null) {
        tables = List<int>.from(jsonDecode(tablesJson));
      }

      final menuJson = prefs.getString('menu');
      if (menuJson != null) {
        Iterable l = jsonDecode(menuJson);
        menu = List<Product>.from(l.map((model) => Product.fromJson(model)));
      }

      final ordersJson = prefs.getString('orders');
      if (ordersJson != null) {
        Iterable l = jsonDecode(ordersJson);
        orders = List<Order>.from(l.map((model) => Order.fromJson(model)));
      }
    } catch (e) {
      print("Error loading data from SharedPreferences: $e");
    }
  }

  List<Order> get pendingOrders => orders.where((o) => !o.isCompleted).toList();
  List<Order> get completedOrders => orders.where((o) => o.isCompleted).toList();

  void _saveDataLocally() {
    prefs.setString('tables', jsonEncode(tables));
    prefs.setString('menu', jsonEncode(menu.map((e) => e.toJson()).toList()));
    prefs.setString('orders', jsonEncode(orders.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void addTable() {
    int next = tables.isEmpty ? 1 : tables.reduce((a, b) => a > b ? a : b) + 1;
    tables.add(next);
    _saveDataLocally();
  }

  void removeTable(int tableNum) {
    tables.remove(tableNum);
    _saveDataLocally();
  }

  void addOrder(int table, String waiter, List<OrderItem> items) {
    orders.add(Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: table,
      waiterName: waiter,
      items: items,
      timestamp: DateTime.now(),
    ));
    _saveDataLocally();
  }

  void completeOrder(String orderId) {
    final order = orders.firstWhere((o) => o.id == orderId);
    order.isCompleted = true;
    _saveDataLocally();
  }

  void addProduct(Product product) {
    menu.add(product);
    _saveDataLocally();
  }

  void editProduct(String id, String newName, double newPrice) {
    final index = menu.indexWhere((p) => p.id == id);
    if (index != -1) {
      menu[index].name = newName;
      menu[index].price = newPrice;
      _saveDataLocally();
    }
  }

  void deleteProduct(String id) {
    menu.removeWhere((p) => p.id == id);
    _saveDataLocally();
  }

  List<Order> getPendingOrdersForTable(int table) {
    return pendingOrders.where((o) => o.tableNumber == table).toList();
  }
}

// ================= UTILS ================= //

String formatShortDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

final Color appOrange = const Color(0xFFFB7317);
final Color appGreen = const Color(0xFF26C25B);
final Color appRed = const Color(0xFFE54A4A);
final Color appYellow = const Color(0xFFF5B01B);

// ================= NAVEGADOR PRINCIPAL ================= //

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const TablesScreen(),
    const PendingOrdersScreen(),
    const CompletedOrdersScreen(),
    const StatsScreen(),
    const MenuManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: appOrange, size: 28),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Kitchen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1)),
                        Text('Commander', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1)),
                      ],
                    ),
                    const Spacer(),
                    _buildNavItem(0, Icons.home_outlined),
                    _buildNavItem(1, Icons.assignment_outlined),
                    _buildNavItem(2, Icons.check_circle_outline),
                    _buildNavItem(3, Icons.bar_chart),
                    _buildNavItem(4, Icons.restaurant_menu),
                  ],
                ),
              ),
              Container(height: 2, color: appOrange),
            ],
          ),
        ),
      ),
      body: _pages[_currentIndex],
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? appOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
}

// ================= LAYOUT Y COMPONENTES ================= //

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeader({Key? key, required this.title, required this.subtitle, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const ActionButton({Key? key, required this.text, required this.onPressed, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: appOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      icon: Icon(icon ?? Icons.add, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }
}

// ================= PANTALLA 1: MESAS ================= //

class TablesScreen extends StatelessWidget {
  const TablesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Mesas del Restaurante',
          subtitle: 'Gestiona las mesas y sus pedidos',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: ActionButton(
            text: 'CREAR NUEVA MESA',
            onPressed: () => provider.addTable(),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: provider.tables.length,
          itemBuilder: (context, index) {
            final tableNum = provider.tables[index];
            final orders = provider.getPendingOrdersForTable(tableNum);
            final isOccupied = orders.isNotEmpty;
            final color = isOccupied ? appRed : appGreen;

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TableDetailsScreen(tableId: tableNum),
                ));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      border: Border(left: BorderSide(color: color, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mesa $tableNum',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            if (!isOccupied)
                              GestureDetector(
                                onTap: () => provider.removeTable(tableNum),
                                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            isOccupied ? 'OCUPADA' : 'LIBRE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ================= DETALLE DE MESA ================= //

class TableDetailsScreen extends StatelessWidget {
  final int tableId;
  const TableDetailsScreen({Key? key, required this.tableId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final orders = provider.getPendingOrdersForTable(tableId);
    final isOccupied = orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: appOrange, height: 2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mesa $tableId', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: isOccupied ? appRed : appGreen, borderRadius: BorderRadius.circular(4)),
                          child: Text(isOccupied ? 'OCUPADA' : 'LIBRE', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('${orders.length} pedido(s)', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              ActionButton(text: 'NUEVO\nPEDIDO', onPressed: () => _showNewOrderDialog(context, tableId, provider)),
            ],
          ),
          const SizedBox(height: 30),
          if (orders.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No hay pedidos registrados para\nesta mesa', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ActionButton(text: 'CREAR PRIMER PEDIDO', onPressed: () => _showNewOrderDialog(context, tableId, provider)),
                ],
              ),
            )
          else
            ...orders.map((o) => _OrderCard(order: o, color: appYellow)),
        ],
      ),
    );
  }

  void _showNewOrderDialog(BuildContext context, int table, RestaurantProvider provider) {
    String waiterName = "";
    Map<Product, int> selectedItems = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Nueva Orden - Mesa $table'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Nombre del Mesero', prefixIcon: Icon(Icons.person)),
                  onChanged: (val) => waiterName = val,
                ),
                const SizedBox(height: 15),
                const Text('Menú', style: TextStyle(fontWeight: FontWeight.bold)),
                ...provider.menu.map((product) {
                  int qty = selectedItems[product] ?? 0;
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: qty > 0 ? () => setState(() => selectedItems[product] = qty - 1) : null),
                        Text('$qty', style: const TextStyle(fontSize: 16)),
                        IconButton(icon: Icon(Icons.add_circle, color: appGreen), onPressed: () => setState(() => selectedItems[product] = qty + 1)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appOrange),
              onPressed: () {
                if (waiterName.isEmpty) return;
                List<OrderItem> items = selectedItems.entries.where((e) => e.value > 0).map((e) => OrderItem(product: e.key, quantity: e.value)).toList();
                if (items.isEmpty) return;
                provider.addOrder(table, waiterName, items);
                Navigator.pop(context);
              },
              child: const Text('Crear Pedido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TARJETA DE ORDEN ================= //

class _OrderCard extends StatelessWidget {
  final Order order;
  final Color color;
  const _OrderCard({required this.order, required this.color});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RestaurantProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mesa ${order.tableNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Mesero: ${order.waiterName} • ${formatShortDate(order.timestamp)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!order.isCompleted)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appGreen, foregroundColor: Colors.white,
                        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('COMPLETAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => provider.completeOrder(order.id),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: appGreen, borderRadius: BorderRadius.circular(4)),
                      child: const Text('COMPLETADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFEEEEEE))),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${i.quantity}x ${i.product.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            Text('\$${i.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: appOrange)),
                          ],
                        ),
                        if (i.note.isNotEmpty) Text('Nota: ${i.note}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                    ),
                  )),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFEEEEEE))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${order.total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: appOrange)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================= ESTADÍSTICAS Y OTRAS PANTALLAS ================= //

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    double totalVendido = provider.completedOrders.fold(0, (sum, o) => sum + o.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(title: 'Estadísticas del Día', subtitle: 'Resumen de ventas y actividad'),
        _MetricCard(title: 'VENTAS TOTALES', value: '\$${totalVendido.toStringAsFixed(2)}', icon: Icons.attach_money, color: appOrange),
        _MetricCard(title: 'PEDIDOS COMPLETADOS', value: '${provider.completedOrders.length}', icon: Icons.shopping_bag_outlined, color: appGreen),
        _MetricCard(title: 'PEDIDOS PENDIENTES', value: '${provider.pendingOrders.length}', icon: Icons.access_time, color: appYellow),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingOrdersScreen extends StatelessWidget {
  const PendingOrdersScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pending = context.watch<RestaurantProvider>().pendingOrders;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(title: 'Pedidos Pendientes', subtitle: 'Pedidos en preparación'),
        if (pending.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay pedidos pendientes.', style: TextStyle(color: Colors.grey)))),
        ...pending.map((o) => _OrderCard(order: o, color: appYellow)),
      ],
    );
  }
}

class CompletedOrdersScreen extends StatelessWidget {
  const CompletedOrdersScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final completed = context.watch<RestaurantProvider>().completedOrders;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(title: 'Historial de Pedidos', subtitle: 'Pedidos completados del día'),
        if (completed.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay pedidos completados.', style: TextStyle(color: Colors.grey)))),
        ...completed.map((o) => _OrderCard(order: o, color: appGreen)),
      ],
    );
  }
}

class MenuManagerScreen extends StatelessWidget {
  const MenuManagerScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final menu = context.watch<RestaurantProvider>().menu;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PageHeader(title: 'Menú', subtitle: 'Administración de platillos'),
          ...menu.map((prod) => Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${prod.price.toStringAsFixed(2)}', style: TextStyle(color: appOrange)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => {}),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => context.read<RestaurantProvider>().deleteProduct(prod.id)),
                    ],
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: appOrange, child: const Icon(Icons.add, color: Colors.white), onPressed: () => {}),
    );
  }
}
