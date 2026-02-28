import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF47B25),
          primary: const Color(0xFFF47B25),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
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
  Map<String, dynamic> toJson() =>
      {'product': product.toJson(), 'quantity': quantity, 'note': note};
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        product: Product.fromJson(json['product']),
        quantity: json['quantity'] as int,
        note: json['note'] ?? "",
      );
}

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

// ================= PROVEEDOR DE ESTADO ================= //

class RestaurantProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  List<RestaurantTable> tables = [];
  int orderCounter = 1;

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
        Iterable l = jsonDecode(tablesJson);
        if (l.isNotEmpty && l.first is int) {
          tables = l
              .map((numValue) =>
                  RestaurantTable(id: numValue, name: 'Mesa $numValue'))
              .toList();
        } else {
          tables = List<RestaurantTable>.from(
              l.map((model) => RestaurantTable.fromJson(model)));
        }
      } else {
        tables = [
          RestaurantTable(id: 1, name: 'Mesa 1'),
          RestaurantTable(id: 2, name: 'Mesa 2')
        ];
      }

      orderCounter = prefs.getInt('orderCounter') ?? 1;

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
      debugPrint("Error loading data from SharedPreferences: $e");
    }
  }

  List<Order> get pendingOrders => orders.where((o) => !o.isCompleted).toList();
  List<Order> get completedOrders =>
      orders.where((o) => o.isCompleted).toList();
  List<String> get knownWaiters =>
      orders.map((o) => o.waiterName).toSet().toList();

  void _saveDataLocally() {
    prefs.setString(
        'tables', jsonEncode(tables.map((e) => e.toJson()).toList()));
    prefs.setInt('orderCounter', orderCounter);
    prefs.setString('menu', jsonEncode(menu.map((e) => e.toJson()).toList()));
    prefs.setString(
        'orders', jsonEncode(orders.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void addTable(String name) {
    int nextId = tables.isEmpty
        ? 1
        : tables.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    tables.add(RestaurantTable(id: nextId, name: name));
    _saveDataLocally();
  }

  void removeTable(int tableId) {
    tables.removeWhere((t) => t.id == tableId);
    _saveDataLocally();
  }

  void editTableName(int tableId, String newName) {
    var index = tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      tables[index].name = newName;
      _saveDataLocally();
    }
  }

  void addOrder(int table, String waiter, String? clientName, String? clientDoc,
      List<OrderItem> items) {
    orders.add(Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: orderCounter++,
      tableNumber: table,
      waiterName: waiter,
      clientName: clientName,
      clientDocument: clientDoc,
      items: items,
      timestamp: DateTime.now(),
    ));
    _saveDataLocally();
  }

  void updateOrder(String orderId, String waiter, String? clientName,
      String? clientDoc, List<OrderItem> items) {
    var index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index].waiterName = waiter;
      orders[index].clientName = clientName;
      orders[index].clientDocument = clientDoc;
      orders[index].items = items;
      _saveDataLocally();
    }
  }

  void completeOrder(String orderId) {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index].isCompleted = true;
      _saveDataLocally();
    }
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

  Future<void> shareDailySummary() async {
    final list = completedOrders;
    if (list.isEmpty) return;
    final total = list.fold(0.0, (sum, o) => sum + o.total);
    final now = DateTime.now();
    final String dateString = '${now.day}/${now.month}/${now.year}';

    StringBuffer sb = StringBuffer();
    sb.writeln('*Reporte de Ventas Diarias*');
    sb.writeln('Fecha: $dateString');
    sb.writeln('Total Vendido: \$${total.toStringAsFixed(2)}');
    sb.writeln('Total Pedidos: ${list.length}');
    sb.writeln('--------------------');
    for (var o in list) {
      final tableName = tables
          .firstWhere((t) => t.id == o.tableNumber,
              orElse: () => RestaurantTable(
                  id: o.tableNumber, name: 'Mesa ${o.tableNumber}'))
          .name;
      sb.writeln('Pedido #${o.orderNumber} - $tableName');
      sb.writeln(
          'Hora: ${o.timestamp.hour.toString().padLeft(2, '0')}:${o.timestamp.minute.toString().padLeft(2, '0')}');
      sb.writeln('Mesero: ${o.waiterName}');
      if (o.clientName != null && o.clientName!.isNotEmpty) {
        sb.writeln('Cliente: ${o.clientName}');
      }
      sb.writeln('Total Pedido: \$${o.total.toStringAsFixed(2)}');
      for (var item in o.items) {
        sb.writeln('  - ${item.quantity}x ${item.product.name}');
      }
      sb.writeln('--------------------');
    }

    final message = sb.toString();
    final whatsappUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await Share.share(message, subject: 'Reporte de Ventas $dateString');
      }
    } catch (_) {
      await Share.share(message, subject: 'Reporte de Ventas $dateString');
    }
  }
}

// ================= UTILS ================= //

String formatShortDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

final Color appOrange = const Color(0xFFF47B25); // Primary #f47b25
final Color appGreen =
    const Color(0xFF10B981); // Modern emerald for success/in-stock
final Color appRed = const Color(0xFFEF4444); // Modern red
final Color appYellow = const Color(0xFFF5A623); // Secondary amber

// ================= NAVEGADOR PRINCIPAL ================= //

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Kitchen Commander',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: appOrange,
        elevation: 1,
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: appOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Mesas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: 'Pendientes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Completados'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ventas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Menú'),
        ],
      ),
    );
  }
}

// ================= LAYOUT Y COMPONENTES ================= //

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeader(
      {super.key, required this.title, required this.subtitle, this.trailing});

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
                Text(title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
  final bool isSecondary;
  final bool isOutline;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: appOrange,
          side: BorderSide(color: appOrange, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      );
    }

    final bgColor = isSecondary ? appYellow : appOrange;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0, // Flat look is more modern
      ),
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text,
          style:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
      onPressed: onPressed,
    );
  }
}

// ================= PANTALLA 1: MESAS ================= //

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

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
            onPressed: () {
              final nameCtrl = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Nueva Mesa'),
                  content: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText:
                            'Nombre de la mesa (Ej: Balcón, Reserva...)'),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: appOrange),
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          provider.addTable(nameCtrl.text.trim());
                        } else {
                          provider
                              .addTable("Mesa ${provider.tables.length + 1}");
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Crear',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
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
            final table = provider.tables[index];
            final tableNum = table.id;
            final orders = provider.getPendingOrdersForTable(tableNum);
            final isOccupied = orders.isNotEmpty;
            final color = isOccupied ? appRed : appGreen;

            String? clientStr;
            if (isOccupied) {
              final firstOrder = orders.first;
              if (firstOrder.clientName != null &&
                  firstOrder.clientName!.isNotEmpty) {
                clientStr = firstOrder.clientName;
              }
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TableDetailsScreen(tableId: tableNum),
                    ));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      border: Border(left: BorderSide(color: color, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                table.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isOccupied)
                              GestureDetector(
                                onTap: () => provider.removeTable(tableNum),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                              ),
                          ],
                        ),
                        if (clientStr != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(clientStr,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            isOccupied ? 'OCUPADA' : 'LIBRE',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5),
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
  const TableDetailsScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final orders = provider.getPendingOrdersForTable(tableId);
    final isOccupied = orders.isNotEmpty;
    final tableName = provider.tables
        .firstWhere((t) => t.id == tableId,
            orElse: () => RestaurantTable(id: tableId, name: 'Mesa $tableId'))
        .name;

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
                decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tableName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: isOccupied ? appRed : appGreen,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(isOccupied ? 'OCUPADA' : 'LIBRE',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('${orders.length} pedido(s)',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              ActionButton(
                  text: 'NUEVO\nPEDIDO',
                  onPressed: () =>
                      _showNewOrderDialog(context, tableId, provider)),
            ],
          ),
          const SizedBox(height: 30),
          if (orders.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No hay pedidos registrados para\nesta mesa',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ActionButton(
                      text: 'CREAR PRIMER PEDIDO',
                      onPressed: () =>
                          _showNewOrderDialog(context, tableId, provider)),
                ],
              ),
            )
          else
            ...orders.map((o) => _OrderCard(order: o, color: appYellow)),
        ],
      ),
    );
  }
}

void _showNewOrderDialog(
    BuildContext context, int tableId, RestaurantProvider provider,
    {Order? existingOrder}) {
  final tableName = provider.tables
      .firstWhere((t) => t.id == tableId,
          orElse: () => RestaurantTable(id: tableId, name: 'Mesa $tableId'))
      .name;
  String waiterName = existingOrder?.waiterName ?? "";
  bool showWaiterError = false;
  String clientName = existingOrder?.clientName ?? "";
  String clientDocument = existingOrder?.clientDocument ?? "";
  Map<Product, int> selectedItems = {};

  if (existingOrder != null) {
    for (var item in existingOrder.items) {
      selectedItems[item.product] = item.quantity;
    }
  }

  final TextEditingController waiterCtrl =
      TextEditingController(text: waiterName);
  final TextEditingController clientCtrl =
      TextEditingController(text: clientName);
  final TextEditingController docCtrl =
      TextEditingController(text: clientDocument);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existingOrder == null
            ? 'Nueva Orden - $tableName'
            : 'Modificar Orden #${existingOrder.orderNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: waiterName),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return provider.knownWaiters.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    waiterName = selection;
                    waiterCtrl.text = selection;
                    showWaiterError = false;
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  // Sincronizar controladores si se inicializó con un valor existente
                  if (waiterCtrl.text.isNotEmpty &&
                      textEditingController.text.isEmpty) {
                    textEditingController.text = waiterCtrl.text;
                  }
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Mesero',
                      prefixIcon: const Icon(Icons.person),
                      errorText: showWaiterError
                          ? 'Debe ingresar el nombre del mesero'
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {
                        waiterName = val;
                        waiterCtrl.text = val;
                        if (val.trim().isNotEmpty) showWaiterError = false;
                      });
                    },
                  );
                },
              ),
              TextField(
                controller: clientCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cliente (Nombre/Alias opcional)',
                    prefixIcon: Icon(Icons.person_outline)),
                onChanged: (val) => clientName = val,
              ),
              TextField(
                controller: docCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cédula / RUC (Opcional)',
                    prefixIcon: Icon(Icons.badge)),
                onChanged: (val) => clientDocument = val,
              ),
              const SizedBox(height: 15),
              const Text('Menú', style: TextStyle(fontWeight: FontWeight.bold)),
              ...provider.menu.map((product) {
                int qty = selectedItems.entries
                    .firstWhere((e) => e.key.id == product.id,
                        orElse: () => MapEntry(product, 0))
                    .value;
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: qty > 0
                              ? () {
                                  setState(() {
                                    var actualProductKey = selectedItems.keys
                                        .firstWhere((k) => k.id == product.id,
                                            orElse: () => product);
                                    selectedItems[actualProductKey] = qty - 1;
                                  });
                                }
                              : null),
                      Text('$qty', style: const TextStyle(fontSize: 16)),
                      IconButton(
                          icon: Icon(Icons.add_circle, color: appGreen),
                          onPressed: () {
                            setState(() {
                              var actualProductKey = selectedItems.keys
                                  .firstWhere((k) => k.id == product.id,
                                      orElse: () => product);
                              selectedItems[actualProductKey] = qty + 1;
                            });
                          }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appOrange),
            onPressed: () {
              if (waiterName.trim().isEmpty) {
                setState(() => showWaiterError = true);
                return;
              }
              List<OrderItem> items = selectedItems.entries
                  .where((e) => e.value > 0)
                  .map((e) => OrderItem(product: e.key, quantity: e.value))
                  .toList();
              if (items.isEmpty) return;

              if (existingOrder == null) {
                provider.addOrder(tableId, waiterName.trim(), clientName.trim(),
                    clientDocument.trim(), items);
              } else {
                provider.updateOrder(existingOrder.id, waiterName.trim(),
                    clientName.trim(), clientDocument.trim(), items);
              }
              Navigator.pop(context);
            },
            child: Text(
                existingOrder == null ? 'Crear Pedido' : 'Guardar Cambios',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// ================= TARJETA DE ORDEN ================= //

class _OrderCard extends StatelessWidget {
  final Order order;
  final Color color;
  const _OrderCard({required this.order, required this.color});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RestaurantProvider>();
    final tableName = provider.tables
        .firstWhere((t) => t.id == order.tableNumber,
            orElse: () => RestaurantTable(
                id: order.tableNumber, name: 'Mesa ${order.tableNumber}'))
        .name;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4))),
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
                        Text('Pedido #${order.orderNumber} - $tableName',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            'Mesero: ${order.waiterName} • ${formatShortDate(order.timestamp)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        if (order.clientName != null &&
                            order.clientName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                'Cliente: ${order.clientName}${order.clientDocument != null && order.clientDocument!.isNotEmpty ? ' (${order.clientDocument})' : ''}',
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 14)),
                          ),
                      ],
                    ),
                  ),
                  if (!order.isCompleted) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => _showNewOrderDialog(
                          context, order.tableNumber, provider,
                          existingOrder: order),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('COMPLETAR',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => provider.completeOrder(order.id),
                    )
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: appGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('COMPLETADO',
                          style: TextStyle(
                              color: appGreen,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    )
                ],
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFEEEEEE))),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${i.quantity}x ${i.product.name}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            Text('\$${i.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: appOrange)),
                          ],
                        ),
                        if (i.note.isNotEmpty)
                          Text('Nota: ${i.note}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey)),
                      ],
                    ),
                  )),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFEEEEEE))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: appOrange)),
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
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    double totalVendido =
        provider.completedOrders.fold(0, (sum, o) => sum + o.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
            title: 'Estadísticas del Día',
            subtitle: 'Resumen de ventas y actividad'),
        _MetricCard(
            title: 'VENTAS TOTALES',
            value: '\$${totalVendido.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: appOrange),
        _MetricCard(
            title: 'PEDIDOS COMPLETADOS',
            value: '${provider.completedOrders.length}',
            icon: Icons.shopping_bag_outlined,
            color: appGreen),
        _MetricCard(
            title: 'PEDIDOS PENDIENTES',
            value: '${provider.pendingOrders.length}',
            icon: Icons.access_time,
            color: appYellow),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 16),
              Text(value,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingOrdersScreen extends StatelessWidget {
  const PendingOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pending = context.watch<RestaurantProvider>().pendingOrders;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
            title: 'Pedidos Pendientes', subtitle: 'Pedidos en preparación'),
        if (pending.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No hay pedidos pendientes.',
                      style: TextStyle(color: Colors.grey)))),
        ...pending.map((o) => _OrderCard(order: o, color: appYellow)),
      ],
    );
  }
}

class CompletedOrdersScreen extends StatelessWidget {
  const CompletedOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final completed = provider.completedOrders;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Historial de Pedidos',
          subtitle: 'Pedidos completados del día',
          trailing: completed.isNotEmpty
              ? ActionButton(
                  text: 'COMPARTIR',
                  icon: Icons.share,
                  isOutline: true,
                  onPressed: () => provider.shareDailySummary())
              : null,
        ),
        if (completed.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No hay pedidos completados.',
                      style: TextStyle(color: Colors.grey)))),
        ...completed.map((o) => _OrderCard(order: o, color: appGreen)),
      ],
    );
  }
}

class MenuManagerScreen extends StatelessWidget {
  const MenuManagerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final menu = context.watch<RestaurantProvider>().menu;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PageHeader(
              title: 'Menú', subtitle: 'Administración de platillos'),
          ...menu.map((prod) => Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(prod.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${prod.price.toStringAsFixed(2)}',
                      style: TextStyle(color: appOrange)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductDialog(context, prod)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => context
                              .read<RestaurantProvider>()
                              .deleteProduct(prod.id)),
                    ],
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: appOrange,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showProductDialog(context, null)),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl =
        TextEditingController(text: product?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product == null ? 'Nuevo Producto' : 'Editar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre del producto')),
            TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appOrange),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price =
                  double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
              if (name.isEmpty || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Ingrese un nombre de producto y precio válido'),
                    backgroundColor: Colors.red));
                return;
              }

              if (product == null) {
                context.read<RestaurantProvider>().addProduct(Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    price: price));
              } else {
                context
                    .read<RestaurantProvider>()
                    .editProduct(product.id, name, price);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
