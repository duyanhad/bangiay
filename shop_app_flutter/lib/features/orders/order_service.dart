import 'package:dio/dio.dart';

class OrderService {
  final Dio dio;
  OrderService(this.dio);

  Future<void> createOrder({
    required String token,
    required int userId,
    required String customerName,
    required String phoneNumber,
    required String shippingAddress,
    required num totalAmount,
    required List<Map<String, dynamic>> items,
    String paymentMethod = "COD",
    String? notes,
  }) async {
    await dio.post(
      "/api/orders",
      data: {
        "userId": userId,
        "customerName": customerName,
        "phoneNumber": phoneNumber,
        "shippingAddress": shippingAddress,
        "paymentMethod": paymentMethod,
        "totalAmount": totalAmount,
        "items": items,
        "notes": notes ?? "",
      },
      options: Options(
        headers: {
          // ✅ FIX QUAN TRỌNG
          "Authorization": "Bearer $token",
        },
      ),
    );
  }
}
