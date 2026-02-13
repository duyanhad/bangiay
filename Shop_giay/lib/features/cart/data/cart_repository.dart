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
        
        // Debug để bạn thấy số lượng món hàng thực tế
        debugPrint("📦 Số món hàng từ Server: ${itemsJson.length}");

        return itemsJson.map((e) => CartItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Lỗi Repository: $e");
      return [];
    }
  }

  Future<void> addToCart(String productId, int qty) => api.addToCart(productId, qty);
  Future<void> updateQty(String productId, int qty) => api.updateQty(productId, qty);
  Future<void> removeItem(String productId) => api.removeItem(productId);
}