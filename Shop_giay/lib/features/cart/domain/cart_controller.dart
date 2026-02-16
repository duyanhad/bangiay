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
  
  // Tính tổng tiền dựa trên danh sách items hiện có
  double get total => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("🛒 DEBUG: Đang gọi API lấy giỏ hàng...");
      _items = await repo.fetchCart();
      debugPrint("✅ DEBUG: Lấy về thành công ${_items.length} sản phẩm");
    } catch (e) {
      debugPrint("❌ DEBUG LỖI LOAD CART: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CẬP NHẬT: Thêm String size vào tham số
  Future<void> addToCart(String productId, int qty, String size) async {
    try {
      debugPrint("➕ DEBUG: Đang thêm SP $productId (Size: $size) vào giỏ...");
      await repo.addToCart(productId, qty, size);
      await loadCart(); 
    } catch (e) {
      debugPrint("❌ DEBUG LỖI ADD TO CART: $e");
      rethrow;
    }
  }

  // CẬP NHẬT: Thêm String size vào tham số
  Future<void> updateQuantity(String productId, int newQty, String size) async {
    try {
      if (newQty < 1) {
        await repo.removeItem(productId, size);
      } else {
        await repo.updateQty(productId, newQty, size);
      }
      await loadCart();
    } catch (e) {
      debugPrint("❌ DEBUG LỖI UPDATE QTY: $e");
    }
  }

  // CẬP NHẬT: Thêm String size vào tham số
  Future<void> remove(String productId, String size) async {
    try {
      await repo.removeItem(productId, size);
      await loadCart();
    } catch (e) {
      debugPrint("❌ DEBUG LỖI REMOVE: $e");
    }
  }
}