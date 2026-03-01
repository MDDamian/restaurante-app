import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/widgets/page_header.dart';
import '../../core/utils/constants.dart';

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
        MetricCard(
            title: 'VENTAS TOTALES',
            value: '\$${totalVendido.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: appOrange),
        MetricCard(
            title: 'PEDIDOS COMPLETADOS',
            value: '${provider.completedOrders.length}',
            icon: Icons.shopping_bag_outlined,
            color: appGreen),
        MetricCard(
            title: 'PEDIDOS PENDIENTES',
            value: '${provider.pendingOrders.length}',
            icon: Icons.access_time,
            color: appYellow),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard(
      {super.key,
      required this.title,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
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
