import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/widgets/page_header.dart';
import '../../core/utils/constants.dart';
import '../../domain/entities/product.dart';

class MenuManagerScreen extends StatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  State<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends State<MenuManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final menu = context.watch<RestaurantProvider>().menu;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: prod.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.memory(base64Decode(prod.image!),
                                    fit: BoxFit.cover)
                                : Image.memory(base64Decode(prod.image!),
                                    fit: BoxFit.cover),
                          )
                        : const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                  title: Text(prod.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${prod.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: appOrange)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.arrow_upward,
                                    size: 20, color: Colors.grey),
                                onPressed: menu.indexOf(prod) > 0
                                    ? () => context
                                        .read<RestaurantProvider>()
                                        .moveProductUp(menu.indexOf(prod))
                                    : null),
                          ),
                          Expanded(
                            child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.arrow_downward,
                                    size: 20, color: Colors.grey),
                                onPressed: menu.indexOf(prod) < menu.length - 1
                                    ? () => context
                                        .read<RestaurantProvider>()
                                        .moveProductDown(menu.indexOf(prod))
                                    : null),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
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
          onPressed: () => _showProductDialog(context, null),
          child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl =
        TextEditingController(text: product?.price.toString() ?? '');
    String? base64Image = product?.image;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product == null ? 'Nuevo Producto' : 'Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        base64Image = base64Encode(bytes);
                      });
                    }
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(base64Decode(base64Image!),
                                fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Subir Imagen',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
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
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey))),
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
                      price: price,
                      image: base64Image));
                } else {
                  context
                      .read<RestaurantProvider>()
                      .editProduct(product.id, name, price, base64Image);
                }
                Navigator.pop(dialogContext);
              },
              child:
                  const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
