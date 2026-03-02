import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../application/restaurant_provider.dart';
import '../../core/widgets/page_header.dart';
import '../../core/utils/constants.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

class MenuManagerScreen extends StatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  State<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends State<MenuManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantProvider>();
    final menu = provider.menu;
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: TabBar(
          controller: _tabController,
          labelColor: appOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: appOrange,
          tabs: const [
            Tab(text: 'Platillos'),
            Tab(text: 'Categorías'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Platillos
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(title: 'Platillos', subtitle: 'Administración de menú'),
              ...categories.map((category) {
                final categoryProducts = menu.where((p) => p.categoryId == category.id).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        category.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appOrange),
                      ),
                    ),
                    if (categoryProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No hay productos en esta categoría', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ),
                    ...categoryProducts.map((prod) => _buildProductCard(context, prod, menu)),
                  ],
                );
              }),
            ],
          ),
          // Tab Categorías
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(title: 'Categorías', subtitle: 'Organiza tus platillos'),
              ...categories.map((cat) => Card(
                color: Colors.white,
                child: ListTile(
                  leading: (cat.image?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(base64Decode(cat.image!), width: 40, height: 40, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.category, color: appColor),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(context, cat)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => provider.deleteCategory(cat.id)),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: appOrange,
          onPressed: () {
            if (_tabController.index == 0) {
              _showProductDialog(context, null);
            } else {
              _showCategoryDialog(context, null);
            }
          },
          child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  void _showCategoryDialog(BuildContext context, Category? category) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    String? base64Image = category?.image;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() => base64Image = base64Encode(bytes));
                  }
                },
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: base64Image != null && base64Image!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(base64Image!), fit: BoxFit.cover))
                      : const Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Categoría')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appOrange),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (category == null) {
                  context.read<RestaurantProvider>().addCategory(Category(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    image: base64Image ?? '',
                    sortOrder: 0,
                  ));
                } else {
                  context.read<RestaurantProvider>().editCategory(category.id, name, base64Image ?? '');
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final provider = context.read<RestaurantProvider>();
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    String? selectedCategoryId = product?.categoryId ?? (provider.categories.isNotEmpty ? provider.categories.first.id : null);
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
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() => base64Image = base64Encode(bytes));
                    }
                  },
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: base64Image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(base64Image!), fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio')),
                const SizedBox(height: 16),
                if (provider.categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => selectedCategoryId = val),
                  )
                else
                  const Text('Debe crear una categoría primero', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appOrange),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (name.isEmpty || price <= 0 || selectedCategoryId == null) return;

                if (product == null) {
                  provider.addProduct(Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    price: price,
                    categoryId: selectedCategoryId!,
                    image: base64Image,
                  ));
                } else {
                  provider.editProduct(Product(
                    id: product.id,
                    name: name,
                    price: price,
                    categoryId: selectedCategoryId!,
                    image: base64Image,
                  ));
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product prod, List<Product> menu) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
          child: prod.image != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(prod.image!), fit: BoxFit.cover))
              : const Icon(Icons.fastfood, color: Colors.grey),
        ),
        title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\$${prod.price.toStringAsFixed(2)}', style: const TextStyle(color: appOrange)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(context, prod)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => context.read<RestaurantProvider>().deleteProduct(prod.id)),
          ],
        ),
      ),
    );
  }
}
