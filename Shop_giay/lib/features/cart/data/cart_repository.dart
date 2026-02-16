import 'package:flutter/foundation.dart';
import 'cart_api.dart';
import 'models/cart_item_model.dart';

class CartRepository {
  final CartApi api;
  CartRepository(this.api);

  Future<List<CartItem>> fetchCart() async {
    try {
      final data = await api.getCart();
      
      if (data['ok'] == true && data['cart'] != null) {
        final List itemsJson = data['cart']['items'] ?? [];
        debugPrint("📦 Số món hàng từ Server: ${itemsJson.length}");
        return itemsJson.map((e) => CartItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Lỗi Repository: $e");
      return [];
    }
  }

  // CẬP NHẬT: Thêm tham số size cho cả 3 hàm dưới đây
  Future<void> addToCart(String productId, int qty, String size) => 
      api.addToCart(productId, qty, size);

  Future<void> updateQty(String productId, int qty, String size) => 
      api.updateQty(productId, qty, size);

  Future<void> removeItem(String productId, String size) => 
      api.removeItem(productId, size);
}