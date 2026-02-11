import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/product_model.dart';

class ProductApi {
  /// Used by ProductListScreen which expects pagination params.
  /// If your backend ignores paging, it will still work.
  Future<List<Product>> fetchProducts({int page = 1, int limit = 60}) async {
    final Response res = await DioClient.dio.get(
      Endpoints.products,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = res.data;

    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Backwards compatible alias (nếu chỗ khác còn gọi getProducts()).
  Future<List<Product>> getProducts() async {
    return fetchProducts(page: 1, limit: 60);
  }

  Future<Product> getDetail(String id) async {
    final Response res = await DioClient.dio.get('${Endpoints.products}/$id');
    final data = res.data;

    if (data is Map && data['data'] is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data['data']));
    }
    if (data is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid product detail response');
  }
}
