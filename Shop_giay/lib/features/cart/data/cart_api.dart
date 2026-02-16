import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/storage/secure_store.dart';

class CartApi {
  final Dio dio;

  CartApi(this.dio) {
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

  // 1. THÊM SIZE VÀO ĐÂY
  Future<void> addToCart(String productId, int qty, String size) async {
    await dio.post(
      Endpoints.cartAdd,
      data: {
        "productId": productId,
        "quantity": qty,
        "size": size, // Gửi size lên Backend
      },
    );
  }

  // 2. CẬP NHẬT CẦN CẢ SIZE ĐỂ BACKEND TÌM ĐÚNG DÒNG
  Future<void> updateQty(String productId, int qty, String size) async {
    await dio.put(
      "${Endpoints.cart}/item/$productId",
      data: {
        "quantity": qty,
        "size": size, // Gửi size trong body
      },
    );
  }

  // 3. XÓA CẦN TRUYỀN SIZE QUA QUERY (?size=...)
  Future<void> removeItem(String productId, String size) async {
    await dio.delete(
      "${Endpoints.cart}/item/$productId",
      queryParameters: {"size": size}, // Truyền vào query để req.query.size nhận được
    );
  }
}