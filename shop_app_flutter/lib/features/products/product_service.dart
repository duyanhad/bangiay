import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import 'product_model.dart';

class ProductService {
  ProductService(this._api);
  final ApiClient _api;

  Future<List<String>> fetchBrands() async {
    final res = await _api.dio.get(Endpoints.brands);
    return List<String>.from(res.data);
  }

  Future<List<Product>> fetchProducts({String? brand}) async {
    final res = await _api.dio.get(
      Endpoints.products,
      queryParameters: brand != null ? {"brand": brand} : null,
    );

    return (res.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> fetchDetail(String id) async {
    final res = await _api.dio.get("${Endpoints.products}/$id");
    return Product.fromJson(res.data);
  }
}
