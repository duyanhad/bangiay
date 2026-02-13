import 'package:flutter/material.dart';
import '../data/cart_repository.dart';
import '../data/models/cart_item_model.dart';

class CartController extends ChangeNotifier {
  final CartRepository repo;
  CartController(this.repo);

  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  double get total => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("🛒 DEBUG: Đang gọi API lấy giỏ hàng...");
      _items = await repo.fetchCart();
      // Kiểm tra xem Server trả về bao nhiêu món
      debugPrint("✅ DEBUG: Lấy về thành công ${_items.length} sản phẩm");
    } catch (e) {
      debugPrint("❌ DEBUG LỖI LOAD CART: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, int qty) async {
    try {
      debugPrint("➕ DEBUG: Đang thêm SP $productId vào giỏ...");
      await repo.addToCart(productId, qty);
      await loadCart(); // Load lại ngay để UI cập nhật
    } catch (e) {
      debugPrint("❌ DEBUG LỖI ADD TO CART: $e");
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int newQty) async {
    try {
      if (newQty < 1) {
        await repo.removeItem(productId);
      } else {
        await repo.updateQty(productId, newQty);
      }
      await loadCart();
    } catch (e) {
      debugPrint("❌ DEBUG LỖI UPDATE QTY: $e");
    }
  }

  Future<void> remove(String productId) async {
    try {
      await repo.removeItem(productId);
      await loadCart();
    } catch (e) {
      debugPrint("❌ DEBUG LỖI REMOVE: $e");
    }
  }
}