import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class OrderApi {
  Future<void> createOrder(Map<String, dynamic> data) async {
    try {
      await DioClient.dio.post('/orders', data: data);
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? e.message;
      throw errorMsg;
    }
  }

  Future<String> createVnpayPayment(Map<String, dynamic> data) async {
    try {
      final response = await DioClient.dio.post('/orders/vnpay', data: data);
      // Đảm bảo lấy đúng trường 'data' chứa link từ Backend
      return response.data['data'].toString(); 
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? "Lỗi kết nối VNPay";
    }
  }
}