import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/storage/secure_store.dart';

class CartApi {
  final Dio dio;

  CartApi(this.dio) {
    // Auto attach token vào header
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStore.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getCart() async {
    final res = await dio.get(Endpoints.cart);
    return res.data;
  }

  Future<void> addToCart(String productId, int qty) async {
    await dio.post(
      Endpoints.cartAdd,
      data: {
        "productId": productId,
        "quantity": qty,
      },
    );
  }

  Future<void> updateQty(String productId, int qty) async {
    await dio.put(
      "${Endpoints.cart}/item/$productId",
      data: {"quantity": qty},
    );
  }

  Future<void> removeItem(String productId) async {
    await dio.delete("${Endpoints.cart}/item/$productId");
  }
}
