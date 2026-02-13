import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../domain/cart_controller.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load giỏ hàng ngay khi vào màn hình
    Future.microtask(() => context.read<CartController>().loadCart());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<CartController>(
        builder: (context, controller, child) {
          if (controller.isLoading) return const Center(child: CircularProgressIndicator());
          
          if (controller.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Giỏ hàng của bạn đang trống", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("TIẾP TỤC MUA SẮM", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.items.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return CartItemTile(
                item: item,
                onUpdateQty: (qty) => controller.updateQuantity(item.productId, qty),
                onRemove: () => controller.remove(item.productId),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final controller = context.watch<CartController>();
    if (controller.items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tổng thanh toán", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    "${controller.total.toStringAsFixed(0)}đ",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                // ✅ Dùng context.push theo đường dẫn đã định nghĩa trong AppRouter
                onPressed: () => context.push('/checkout'),
                child: const Text(
                  "THANH TOÁN",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}