import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/widgets/page_header.dart';
import '../widgets/order_card.dart';
import '../../core/utils/constants.dart';

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
        ...pending.map((o) => OrderCard(order: o, color: appYellow)),
      ],
    );
  }
}
