import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/widgets/page_header.dart';
import '../widgets/order_card.dart';
import '../../core/widgets/action_button.dart';
import '../../core/utils/constants.dart';

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
        ...completed.map((o) => OrderCard(order: o, color: appGreen)),
      ],
    );
  }
}
