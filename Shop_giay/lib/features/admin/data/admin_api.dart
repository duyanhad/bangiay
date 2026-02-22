import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../data/admin_models.dart';

class AdminApi {
  final Dio _dio = DioClient.dio;

  // ======================================================
  // 1. DASHBOARD STATS
  // ======================================================
  Future<AdminStats> getStats() async {
    final res = await _dio.get(Endpoints.adminStats);
    final data = res.data['data'] as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }

  // ======================================================
  // 2. ORDERS MANAGEMENT
  // ======================================================
  Future<List<dynamic>> getAllOrders() async {
    try {
      final res = await _dio.get('/admin/orders');

      if (res.data['ok'] == true) {
        final rawData = res.data['data'];

        if (rawData is List) return rawData;

        if (rawData is Map) {
          if (rawData.containsKey('docs')) return rawData['docs'];
          if (rawData.containsKey('orders')) return rawData['orders'];
          if (rawData.containsKey('data')) return rawData['data'];
          if (rawData.containsKey('items')) return rawData['items'];
        }
      }

      return [];
    } catch (e) {
      print("Lỗi API getAllOrders: $e");
      rethrow;
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final res = await _dio.put(
        '/admin/orders/$id/status',
        data: {'status': status},
      );

      return res.data['ok'] == true ||
          res.statusCode == 200;
    } catch (e) {
      print("Lỗi API updateOrderStatus: $e");
      return false;
    }
  }

  // ======================================================
  // 3. PRODUCTS MANAGEMENT
  // ======================================================

  /// GET PRODUCTS (optional search)
  Future<List<dynamic>> getAllProducts({String? search}) async {
    try {
      final res = await _dio.get(
        Endpoints.products,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (res.data['ok'] == true ||
          res.statusCode == 200) {
        final rawData = res.data['data'];

        if (rawData is List) return rawData;

        if (rawData is Map) {
          if (rawData.containsKey('docs')) return rawData['docs'];
          if (rawData.containsKey('data')) return rawData['data'];
          if (rawData.containsKey('items')) return rawData['items'];
        }
      }

      return [];
    } catch (e) {
      print("Lỗi API getAllProducts: $e");
      return [];
    }
  }

  /// CREATE PRODUCT
  Future<bool> createProduct(
      Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        Endpoints.products,
        data: data,
      );

      return res.data['ok'] == true ||
          res.statusCode == 200 ||
          res.statusCode == 201;
    } catch (e) {
      print("Lỗi API createProduct: $e");
      return false;
    }
  }

  /// UPDATE PRODUCT
  Future<bool> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('${Endpoints.products}/$id', data: data);

      return res.data['ok'] == true ||
          res.statusCode == 200;
    } catch (e) {
      print("Lỗi API updateProduct: $e");
      return false;
    }
  }

  /// DELETE PRODUCT
  Future<bool> deleteProduct(String id) async {
    try {
      final res =
          await _dio.delete('${Endpoints.products}/$id');

      return res.data['ok'] == true ||
          res.statusCode == 200;
    } catch (e) {
      print("Lỗi API deleteProduct: $e");
      return false;
    }
  }
  // ======================================================
// 4. CATEGORY MANAGEMENT
// ======================================================

Future<List<dynamic>> getAllCategories() async {
  try {
    final res = await _dio.get('/admin/categories');

    if (res.data['ok'] == true || res.statusCode == 200) {
      final rawData = res.data['data'];

      if (rawData is List) return rawData;

      if (rawData is Map) {
        if (rawData.containsKey('docs')) return rawData['docs'];
        if (rawData.containsKey('data')) return rawData['data'];
        if (rawData.containsKey('items')) return rawData['items'];
      }
    }

    return [];
  } catch (e) {
    print("Lỗi API getAllCategories: $e");
    return [];
  }
}

Future<bool> createCategory(Map<String, dynamic> data) async {
  try {
    final res = await _dio.post(
      '/admin/categories',
      data: data,
    );

    return res.data['ok'] == true ||
        res.statusCode == 200 ||
        res.statusCode == 201;
  } catch (e) {
    print("Lỗi API createCategory: $e");
    return false;
  }
}

Future<bool> updateCategory(
    String id, Map<String, dynamic> data) async {
  try {
    final res =
        await _dio.put('/admin/categories/$id', data: data);

    return res.data['ok'] == true ||
        res.statusCode == 200;
  } catch (e) {
    print("Lỗi API updateCategory: $e");
    return false;
  }
}

Future<bool> deleteCategory(String id) async {
  try {
    final res =
        await _dio.delete('/admin/categories/$id');

    return res.data['ok'] == true ||
        res.statusCode == 200;
  } catch (e) {
    print("Lỗi API deleteCategory: $e");
    return false;
  }
}
}
