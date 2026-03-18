import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../data/admin_models.dart';

class AdminApi {
  final Dio _dio = DioClient.dio;

  // ======================================================
  // 1. DASHBOARD STATS
  // ======================================================
  Future<AdminStats?> getStats({String chartType = 'day'}) async {
    try {
      final res = await _dio.get(
        Endpoints.adminStats,
        queryParameters: {'type': chartType},
      );

      if (res.data == null) return null;

      final data = res.data['data'];
      if (data == null) return null;

      return AdminStats.fromJson(data);
    } catch (e) {
      debugPrint("Lỗi API getStats: $e");
      return null;
    }
  }

  // ======================================================
  // 2. ORDERS MANAGEMENT
  // ======================================================
  Future<List<dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      if (status != null && status != 'All' && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final res = await _dio.get('/admin/orders', queryParameters: queryParams);

      final rawData = res.data?['data'];

      if (rawData is List) return rawData;

      if (rawData is Map) {
        if (rawData.containsKey('docs')) return rawData['docs'];
        if (rawData.containsKey('orders')) return rawData['orders'];
        if (rawData.containsKey('items')) return rawData['items'];
      }

      return [];
    } catch (e) {
      debugPrint("Lỗi API getAllOrders: $e");
      return [];
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final res = await _dio.put(
        '/admin/orders/$id/status',
        data: {'status': status},
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API updateOrderStatus: $e");
      return false;
    }
  }

  // ======================================================
  // 3. PRODUCTS MANAGEMENT
  // ======================================================
  Future<List<dynamic>> getAllProducts({String? search}) async {
    try {
      final res = await _dio.get(
        '/admin/products',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final rawData = res.data?['data'];

      if (rawData is List) return rawData;

      if (rawData is Map) {
        if (rawData.containsKey('docs')) return rawData['docs'];
        if (rawData.containsKey('items')) return rawData['items'];
      }

      return [];
    } catch (e) {
      debugPrint("Lỗi API getAllProducts: $e");
      return [];
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/admin/products', data: data);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi API createProduct: $e");
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/admin/products/$id', data: data);

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API updateProduct: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final res = await _dio.delete('/admin/products/$id');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API deleteProduct: $e");
      return false;
    }
  }

  // ======================================================
  // 4. CATEGORY MANAGEMENT
  // ======================================================
  Future<List<dynamic>> getAllCategories() async {
    try {
      final res = await _dio.get('/admin/categories');

      final rawData = res.data?['data'];

      if (rawData is List) return rawData;

      if (rawData is Map) {
        if (rawData.containsKey('docs')) return rawData['docs'];
        if (rawData.containsKey('items')) return rawData['items'];
      }

      return [];
    } catch (e) {
      debugPrint("Lỗi API getAllCategories: $e");
      return [];
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/admin/categories', data: data);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("Lỗi API createCategory: $e");
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/admin/categories/$id', data: data);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API updateCategory: $e");
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final res = await _dio.delete('/admin/categories/$id');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API deleteCategory: $e");
      return false;
    }
  }

  // ======================================================
  // 5. COMMENTS MANAGEMENT
  // ======================================================
  Future<List<dynamic>> getAllComments() async {
    try {
      final res = await _dio.get('/admin/comments');

      final rawData = res.data?['data'];

      if (rawData is List) return rawData;

      if (rawData is Map && rawData.containsKey('docs')) {
        return rawData['docs'];
      }

      return [];
    } catch (e) {
      debugPrint("Lỗi API getAllComments: $e");
      return [];
    }
  }

  Future<bool> replyComment(String commentId, String content) async {
    try {
      final res = await _dio.patch(
        '/admin/comments/$commentId/reply',
        data: {'content': content},
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API replyComment: $e");
      return false;
    }
  }

  Future<bool> toggleHideComment(String commentId, bool isHidden) async {
    try {
      final res = await _dio.patch(
        '/admin/comments/$commentId/hide',
        data: {'isHidden': isHidden},
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API toggleHideComment: $e");
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final res = await _dio.delete('/admin/comments/$commentId');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi API deleteComment: $e");
      return false;
    }
  }
}
