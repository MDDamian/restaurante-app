import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/table.dart';
import '../../application/restaurant_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';
import 'order_dialog.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Color color;
  const OrderCard({super.key, required this.order, required this.color});

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
              color: Colors.black.withOpacity(0.05),
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
                      onPressed: () => showNewOrderDialog(
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
                          color: appGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('COMPLETADO',
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
                            Row(
                              children: [
                                if (i.product.image != null)
                                  Container(
                                    width: 35,
                                    height: 35,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      image: DecorationImage(
                                        image: MemoryImage(base64Decode(i.product.image!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Text('${i.quantity}x ${i.product.name}',
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text('\$${i.total.toStringAsFixed(2)}',
                                style: const TextStyle(
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
                      style: const TextStyle(
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
