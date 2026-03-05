import 'package:flutter/material.dart';
import '../data/admin_api.dart';
import '../data/admin_models.dart';

class AdminController extends ChangeNotifier {
  final AdminApi _api = AdminApi();

  AdminStats? stats;

  List<dynamic> orders = [];

  List<dynamic> products = [];
  List<dynamic> _allProducts = [];

  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;

  List<dynamic> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;

  bool isLoading = false;
  bool isLoadingMore = false;

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

  Future<void> loadStats({String chartType = 'week'}) async {
    _setLoading(true);

    try {
      stats = await _api.getStats(chartType: chartType);
      error = null;
    } catch (e) {
      error = "Lỗi tải dashboard";
      debugPrint("loadStats error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ================= ORDERS =================

  int _currentPage = 1;
  bool hasMore = true;

  Future<void> loadOrders({String? status}) async {
    _currentPage = 1;
    hasMore = true;

    _setLoading(true);

    try {
      final data =
          await _api.getAllOrders(page: _currentPage, limit: 20, status: status);

      orders = List.from(data);

      if (data.length < 20) {
        hasMore = false;
      }

      error = null;
    } catch (e) {
      error = "Lỗi tải đơn hàng";
      debugPrint(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreOrders({String? status}) async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    _currentPage++;

    notifyListeners();

    try {
      final data =
          await _api.getAllOrders(page: _currentPage, limit: 20, status: status);

      if (data.isEmpty || data.length < 20) {
        hasMore = false;
      }

      orders.addAll(data);
    } catch (e) {
      _currentPage--;
      debugPrint(e.toString());
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      bool success = await _api.updateOrderStatus(id, status);

      if (success) {
        int index = orders.indexWhere((o) => (o['_id'] ?? o['id']) == id);

        if (index != -1 && orders[index] is Map) {
          orders[index]['status'] = status;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      debugPrint(e.toString());
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
      error = "Lỗi tải sản phẩm";
    } finally {
      _setLoading(false);
    }
  }

  void searchProducts(String keyword) {
    if (keyword.isEmpty) {
      products = List.from(_allProducts);
    } else {
      products = _allProducts.where((p) {
        final name =
            (p['name'] ?? "").toString().toLowerCase();

        return name.contains(keyword.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      _setLoading(true);

      bool success = await _api.createProduct(data);

      if (success) {
        await loadProducts();
      }

      return success;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      _setLoading(true);

      bool success = await _api.updateProduct(id, data);

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

  Future<bool> deleteProduct(String id) async {
    try {
      bool success = await _api.deleteProduct(id);

      if (success) {
        _allProducts.removeWhere((p) => (p['_id'] ?? p['id']) == id);
        products.removeWhere((p) => (p['_id'] ?? p['id']) == id);

        notifyListeners();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  // ================= COMMENTS =================

  List<dynamic> _adminComments = [];
  List<dynamic> get adminComments => _adminComments;

  Future<void> loadAdminComments() async {
    _setLoading(true);

    try {
      final res = await _api.getAllComments();

      _adminComments = List.from(res);

      error = null;
    } catch (e) {
      error = "Không thể tải bình luận";
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> handleReply(String id, String content) async {
    try {
      bool success = await _api.replyComment(id, content);

      if (success) {
        await loadAdminComments();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> handleHide(String id, bool isHidden) async {
    try {
      bool success = await _api.toggleHideComment(id, isHidden);

      if (success) {
        int index =
            _adminComments.indexWhere((item) => (item['_id'] ?? item['id']) == id);

        if (index != -1) {
          _adminComments[index]['isHidden'] = isHidden;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteComment(String id) async {
    try {
      bool success = await _api.deleteComment(id);

      if (success) {
        _adminComments.removeWhere(
            (item) => (item['_id']?.toString() ?? item['id']?.toString()) == id);

        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
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

      if (success) {
        await loadCategories();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      bool success = await _api.updateCategory(id, data);

      if (success) {
        await loadCategories();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      bool success = await _api.deleteCategory(id);

      if (success) {
        await loadCategories();
      }
    } catch (e) {
      debugPrint("Delete category error: $e");
    }
  }
}