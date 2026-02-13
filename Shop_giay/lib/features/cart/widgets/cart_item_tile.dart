import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(int) onUpdateQty;
  final VoidCallback onRemove;

  const CartItemTile({super.key, required this.item, required this.onUpdateQty, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.network(item.image, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${item.price.toStringAsFixed(0)}đ", style: const TextStyle(color: Colors.red)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => onUpdateQty(item.quantity - 1)),
                      Text("${item.quantity}"),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onUpdateQty(item.quantity + 1)),
                    ],
                  )
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}