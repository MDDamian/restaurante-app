import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/action_button.dart';
import 'table_details_screen.dart';

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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
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
                              color: color.withOpacity(0.15),
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
