import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/styles/app_spacing.dart';
import 'cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          children: [
            Expanded(
              child: cart.items.isEmpty
                  ? const Center(child: Text("Giỏ hàng trống"))
                  : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (_, i) {
                        final item = cart.items[i];

                        return ListTile(
                          leading: item.image != null
                              ? Image.network(item.image!, width: 48, height: 48, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                              : const Icon(Icons.image),
                          title: Text(item.name),
                          subtitle: Text(
                            "${item.price.toStringAsFixed(0)} ₫ x ${item.qty}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => cart.decrease(item.productId),
                              ),
                              Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => cart.increase(item.productId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Tổng tiền: ${cart.total.toStringAsFixed(0)} ₫",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        // ✅ Đi đúng flow dự án: sang màn checkout
                        context.go("/checkout");
                      },
                child: const Text("Thanh toán"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
