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
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: product.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(base64Decode(product.image!),
                                fit: BoxFit.cover),
                          )
                        : const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                  ),
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
                          icon: const Icon(Icons.add_circle, color: appGreen),
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
