import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart'; // Đảm bảo đường dẫn này đúng với cấu trúc dự án của bạn

class OrderApi {
  // 1. Tạo đơn hàng thường (COD)
  Future<void> createOrder(Map<String, dynamic> data) async {
    try {
      await DioClient.dio.post('/orders', data: data);
    } on DioException catch (e) {
      // Lấy message lỗi từ backend trả về (nếu có)
      String errorMsg = e.response?.data['message'] ?? e.message ?? "Lỗi kết nối";
      throw errorMsg;
    }
  }

  // 2. Tạo URL thanh toán VNPAY
  Future<String> createVnpayPayment(Map<String, dynamic> data) async {
    try {
      // Backend: exports.createVnpayPayment => res.json({ ok: true, data: paymentUrl })
      final response = await DioClient.dio.post('/orders/vnpay', data: data);
      
      if (response.data['data'] != null) {
        return response.data['data'].toString();
      } else {
        throw "Không nhận được link thanh toán";
      }
      
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? "Lỗi tạo link thanh toán";
      throw errorMsg;
    }
  }

  // 3. Lấy danh sách lịch sử đơn hàng của tôi (PHẦN MỚI THÊM)
  
  Future<List<dynamic>> fetchMyOrders() async {
    try {
      // Gọi đến router.get('/my-orders', ...) trong backend của bạn
      final response = await DioClient.dio.get('/orders/my-orders');
      
      if (response.data['ok'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? "Không thể tải lịch sử đơn hàng";
      throw errorMsg;
    } catch (e) {
      throw "Lỗi hệ thống: $e";
    }
  }
  // 4. Tra cứu chi tiết một đơn hàng theo ID (Mới thêm)
  Future<dynamic> getOrderById(String orderId) async {
  try {
    // Kiểm tra nếu ID rỗng thì không gọi API
    if (orderId.trim().isEmpty) return null;

    final response = await DioClient.dio.get('/orders/$orderId');
    
    if (response.data['ok'] == true) {
      return response.data['data'];
    }
    return null;
  } on DioException catch (e) {
    // Ghi đè thông báo lỗi cụ thể hơn
    if (e.response?.statusCode == 404) {
      throw "Mã đơn hàng không tồn tại trên hệ thống";
    }
    throw e.response?.data['message'] ?? "Lỗi tra cứu đơn hàng";
  }
}
}
