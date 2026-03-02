import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/table.dart';
import '../../application/restaurant_provider.dart';
import '../../core/utils/constants.dart';

void showNewOrderDialog(
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

  String? selectedCategory;
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Image.asset(appLogo, height: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                existingOrder == null
                    ? 'Nueva Orden - $tableName'
                    : 'Modificar Orden #${existingOrder.orderNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Menú', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  if (selectedCategory != null)
                    TextButton.icon(
                      onPressed: () => setState(() => selectedCategory = null),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Categorías'),
                      style: TextButton.styleFrom(foregroundColor: appOrange),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedCategory == null)
                // Categorías Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return InkWell(
                      onTap: () => setState(() => selectedCategory = cat.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (cat.image?.isNotEmpty ?? false)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(cat.image!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Icon(Icons.category, size: 40, color: appColor),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                // Productos de la categoría seleccionada
                Column(
                  children: provider.menu
                      .where((p) => p.categoryId == selectedCategory)
                      .map((product) => _buildProductItem(product, selectedItems, setState))
                      .toList(),
                ),
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

Widget _buildProductItem(Product product, Map<Product, int> selectedItems,
    void Function(void Function()) setState) {
  int qty = selectedItems.entries
      .firstWhere((e) => e.key.id == product.id,
          orElse: () => MapEntry(product, 0))
      .value;
  return ListTile(
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: product.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(base64Decode(product.image!), fit: BoxFit.cover),
            )
          : const Icon(Icons.fastfood, color: Colors.grey),
    ),
    title: Text(product.name),
    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: qty > 0
                ? () {
                    setState(() {
                      var actualProductKey = selectedItems.keys.firstWhere(
                          (k) => k.id == product.id,
                          orElse: () => product);
                      selectedItems[actualProductKey] = qty - 1;
                    });
                  }
                : null),
        Text('$qty', style: const TextStyle(fontSize: 16)),
        IconButton(
            icon: const Icon(Icons.add_circle, color: appGreen),
            onPressed: () {
              setState(() {
                var actualProductKey = selectedItems.keys.firstWhere(
                    (k) => k.id == product.id,
                    orElse: () => product);
                selectedItems[actualProductKey] = qty + 1;
              });
            }),
      ],
    ),
  );
}
