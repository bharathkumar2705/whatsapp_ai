import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/innovation_provider.dart';

class GroceryListWidget extends StatefulWidget {
  final String chatId;
  final String messageId;
  final List<dynamic> items;

  const GroceryListWidget({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.items,
  });

  @override
  State<GroceryListWidget> createState() => _GroceryListWidgetState();
}

class _GroceryListWidgetState extends State<GroceryListWidget> {
  final TextEditingController _itemController = TextEditingController();

  void _addItem() {
    if (_itemController.text.trim().isEmpty) return;
    
    final newItems = List.from(widget.items);
    newItems.add({
      'name': _itemController.text.trim(),
      'isDone': false,
    });
    
    context.read<InnovationProvider>().updateGroceryItems(
      chatId: widget.chatId,
      messageId: widget.messageId,
      items: newItems,
    );
    _itemController.clear();
  }

  void _toggleItem(int index) {
    final newItems = List.from(widget.items);
    newItems[index]['isDone'] = !newItems[index]['isDone'];
    
    context.read<InnovationProvider>().updateGroceryItems(
      chatId: widget.chatId,
      messageId: widget.messageId,
      items: newItems,
    );
  }

  void _removeItem(int index) {
    final newItems = List.from(widget.items);
    newItems.removeAt(index);
    
    context.read<InnovationProvider>().updateGroceryItems(
      chatId: widget.chatId,
      messageId: widget.messageId,
      items: newItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF25D366), // WhatsApp Green
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("Shared Grocery List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return ListTile(
                  dense: true,
                  leading: Checkbox(
                    value: item['isDone'],
                    onChanged: (_) => _toggleItem(index),
                    activeColor: const Color(0xFF25D366),
                  ),
                  title: Text(
                    item['name'],
                    style: TextStyle(
                      decoration: item['isDone'] ? TextDecoration.lineThrough : null,
                      color: item['isDone'] ? Colors.grey : Colors.black87,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onPressed: () => _removeItem(index),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    onSubmitted: (_) => _addItem(),
                    decoration: InputDecoration(
                      hintText: "Add item...",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF25D366)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
