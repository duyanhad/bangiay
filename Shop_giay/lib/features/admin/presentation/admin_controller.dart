import 'package:flutter/material.dart';
import '../data/admin_api.dart';
import '../data/admin_models.dart';

class AdminController extends ChangeNotifier {
  final AdminApi _api = AdminApi();

  AdminStats? stats;
  List<dynamic> orders = []; 
  bool isLoading = false;
  String? error;

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

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

  // Load đơn hàng
  Future<void> loadOrders() async {
    _setLoading(true);
    try {
      orders = await _api.getAllOrders();
      error = null;
    } catch (e) {
      error = "Lỗi tải đơn hàng: $e";
      print(error);
    } finally {
      _setLoading(false);
    }
  }

  // Cập nhật trạng thái
  Future<bool> updateStatus(String id, String status) async {
    try {
      bool success = await _api.updateOrderStatus(id, status);
      if (success) {
        // Cập nhật local để giao diện đổi ngay lập tức
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
}