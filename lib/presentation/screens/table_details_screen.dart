import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/table.dart';
import '../../application/restaurant_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/action_button.dart';
import '../widgets/order_card.dart';
import '../widgets/order_dialog.dart';

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
                      showNewOrderDialog(context, tableId, provider)),
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
                          showNewOrderDialog(context, tableId, provider)),
                ],
              ),
            )
          else
            ...orders.map((o) => OrderCard(order: o, color: appYellow)),
        ],
      ),
    );
  }
}
