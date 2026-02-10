import 'package:flutter/material.dart';
import 'cart_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  void addItem(CartItem item) {
    if (_items.containsKey(item.productId)) {
      _items[item.productId]!.qty++;
    } else {
      _items[item.productId] = item;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void increase(String productId) {
    _items[productId]!.qty++;
    notifyListeners();
  }

  void decrease(String productId) {
    final item = _items[productId];
    if (item == null) return;

    if (item.qty > 1) {
      item.qty--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  double get total =>
      items.fold(0, (sum, e) => sum + e.price * e.qty);

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
