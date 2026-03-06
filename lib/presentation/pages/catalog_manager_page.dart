import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CatalogManagerPage extends StatelessWidget {
  const CatalogManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catalog"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: auth.getCatalog(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Your catalog is empty", style: TextStyle(color: Colors.grey)),
                  Text("Add your products or services"),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item['imageUrl']?.isNotEmpty == true
                    ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey[300], child: const Icon(Icons.image)),
                title: Text(item['name']),
                subtitle: Text("₹${item['price']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => auth.deleteCatalogItem(item['id']),
                ),
                onTap: () => _showAddItemDialog(context, item: item),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, {Map<String, dynamic>? item}) {
    final nameController = TextEditingController(text: item?['name']);
    final priceController = TextEditingController(text: item?['price']?.toString());
    final descController = TextEditingController(text: item?['description']);
    final imgController = TextEditingController(text: item?['imageUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? "Add Item" : "Edit Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item name")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
              TextField(controller: imgController, decoration: const InputDecoration(labelText: "Image URL (Optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final data = {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'description': descController.text,
                'imageUrl': imgController.text,
              };
              if (item == null) {
                auth.addCatalogItem(data);
              } else {
                auth.updateCatalogItem(item['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
