import 'package:flutter/material.dart';
import '../data/admin_api.dart';
import '../data/admin_models.dart';

class AdminController extends ChangeNotifier {
  final AdminApi _api = AdminApi();

  AdminStats? stats;
  List<dynamic> orders = [];

  List<dynamic> products = [];
  List<dynamic> _allProducts = [];

  // ================= CATEGORY =================
  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;

  List<dynamic> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;

  bool isLoading = false;
  String? error;

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void _setCategoryLoading(bool val) {
    _isLoadingCategories = val;
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
  // ✅ 3 BIẾN QUẢN LÝ PHÂN TRANG
  int _currentPage = 1;
  bool hasMore = true; 
  bool isLoadingMore = false;

  // HÀM TẢI LẦN ĐẦU / LÀM MỚI (Hỗ trợ lọc trạng thái)
  Future<void> loadOrders({String? status}) async {
    _currentPage = 1;
    hasMore = true;
    _setLoading(true);
    
    try {
      // Gọi API tải trang 1 và truyền kèm trạng thái lọc
      final data = await _api.getAllOrders(page: _currentPage, limit: 20, status: status);
      
      // Đề phòng API trả về Map {orders: [], total: ...} thay vì List thuần
      List<dynamic> fetchedOrders = data is Map ? data['orders'] ?? [] : data;

      orders = List.from(fetchedOrders);
      
      // Nếu số đơn lấy về nhỏ hơn 20 -> Đã hết đơn hàng
      if (fetchedOrders.length < 20) {
        hasMore = false;
      }
      error = null;
    } catch (e) {
      error = "Lỗi tải đơn hàng: $e";
    } finally {
      _setLoading(false);
    }
  }

  // HÀM TẢI THÊM ĐƠN KHI VUỐT CHẠM ĐÁY (Hỗ trợ lọc trạng thái)
  Future<void> loadMoreOrders({String? status}) async { 
    // Nếu đang tải dở hoặc đã hết đơn thì không gọi API nữa
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    _currentPage++;
    notifyListeners(); // Hiện vòng xoay loading ở đáy danh sách

    try {
      // Gọi API tải trang tiếp theo (vẫn giữ trạng thái đang lọc)
      final data = await _api.getAllOrders(page: _currentPage, limit: 20, status: status);
      List<dynamic> fetchedOrders = data is Map ? data['orders'] ?? [] : data;

      if (fetchedOrders.isEmpty || fetchedOrders.length < 20) {
        hasMore = false; // Đã đến trang cuối
      }

      // Nối thêm đơn hàng mới vào cuối danh sách hiện tại
      orders.addAll(fetchedOrders);
      error = null;
    } catch (e) {
      error = "Lỗi tải thêm đơn hàng: $e";
      _currentPage--; // Lỗi thì lùi lại trang cũ để vuốt lại
    } finally {
      isLoadingMore = false;
      notifyListeners(); // Tắt vòng xoay loading
    }
  }

  // HÀM UPDATE STATUS
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

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      bool success = await _api.createProduct(data);
      if (success) await loadProducts();
      return success;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      bool success = await _api.updateProduct(id, data);
      if (success) await loadProducts();
      return success;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

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

  // ================= CATEGORY =================

  Future<void> loadCategories() async {
    _setCategoryLoading(true);
    try {
      _categories = await _api.getAllCategories();
    } catch (e) {
      debugPrint("Load categories error: $e");
    } finally {
      _setCategoryLoading(false);
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      bool success = await _api.createCategory(data);
      if (success) await loadCategories();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      bool success = await _api.updateCategory(id, data);
      if (success) await loadCategories();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      bool success = await _api.deleteCategory(id);
      if (success) await loadCategories();
    } catch (e) {
      debugPrint("Delete category error: $e");
    }
  }
}