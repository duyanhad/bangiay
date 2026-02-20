import 'package:flutter/material.dart';
import '../data/admin_api.dart';
import '../data/admin_models.dart';

class AdminController extends ChangeNotifier {
  final AdminApi _api = AdminApi();

  AdminStats? stats;
  List<dynamic> orders = [];

  List<dynamic> products = [];
  List<dynamic> _allProducts = [];

  bool isLoading = false;
  String? error;

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  // ================= DASHBOARD =================
  Future<void> loadStats() async {
    _setLoading(true);
    try {
      stats = await _api.getStats();
      error = null;
    } catch (e) {
      error = "Lỗi tải thống kê: $e";
    } finally {
      _setLoading(false);
    }
  }

  // ================= ORDERS =================
  Future<void> loadOrders() async {
    _setLoading(true);
    try {
      orders = await _api.getAllOrders();
      error = null;
    } catch (e) {
      error = "Lỗi tải đơn hàng: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      bool success = await _api.updateOrderStatus(id, status);
      if (success) {
        int index = orders.indexWhere((o) => o['_id'] == id);
        if (index != -1) {
          orders[index]['status'] = status;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ================= PRODUCTS =================

  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      final data = await _api.getAllProducts();

      _allProducts = List.from(data);
      products = List.from(data);

      error = null;
    } catch (e) {
      error = "Lỗi tải sản phẩm: $e";
    } finally {
      _setLoading(false);
    }
  }

  // 🔥 SEARCH REALTIME
  void searchProducts(String keyword) {
    if (keyword.isEmpty) {
      products = List.from(_allProducts);
    } else {
      products = _allProducts.where((p) {
        final name = p['name'].toString().toLowerCase();
        return name.contains(keyword.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }

  // ================= CREATE PRODUCT =================
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      _setLoading(true);

      bool success = await _api.createProduct(data);

      if (success) {
        await loadProducts();
      }

      return success;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= UPDATE PRODUCT =================
  Future<bool> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);

      bool success =
          await _api.updateProduct(id, data);

      if (success) {
        await loadProducts();
      }

      return success;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= DELETE PRODUCT =================
  Future<bool> deleteProduct(String id) async {
    try {
      bool success = await _api.deleteProduct(id);

      if (success) {
        _allProducts.removeWhere((p) => p['_id'] == id);
        products.removeWhere((p) => p['_id'] == id);
        notifyListeners();
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}
