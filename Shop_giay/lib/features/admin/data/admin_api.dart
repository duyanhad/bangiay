import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../data/admin_models.dart';

class AdminApi {
  final Dio _dio = DioClient.dio;

  // 1. Lấy thống kê Dashboard
  Future<AdminStats> getStats() async {
    final res = await _dio.get(Endpoints.adminStats);
    final data = res.data['data'] as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }

  // 2. Lấy toàn bộ đơn hàng (Cho Admin) - ĐÃ FIX LỖI JSONMAP
  Future<List<dynamic>> getAllOrders() async {
    try {
      final res = await _dio.get('/admin/orders'); 
      if (res.data['ok'] == true) {
        final rawData = res.data['data'];

        // TRƯỜNG HỢP 1: Backend trả thẳng về Mảng (List)
        if (rawData is List) {
          return rawData;
        } 
        // TRƯỜNG HỢP 2: Backend trả về Object/Map (Thường gặp khi có phân trang)
        else if (rawData is Map) {
          // Thử lấy danh sách từ các key phổ biến (docs, orders, data, items...)
          if (rawData.containsKey('docs')) return rawData['docs'] as List<dynamic>;
          if (rawData.containsKey('orders')) return rawData['orders'] as List<dynamic>;
          if (rawData.containsKey('data')) return rawData['data'] as List<dynamic>;
          if (rawData.containsKey('items')) return rawData['items'] as List<dynamic>;
          
          print("⚠️ Cấu trúc dữ liệu chưa xác định từ Backend: $rawData");
          return [];
        }
      }
      return [];
    } catch (e) {
      print("Lỗi API getAllOrders: $e");
      rethrow;
    }
  }

  // 3. Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final res = await _dio.put('/admin/orders/$id/status', data: {'status': status});
      return res.data['ok'] == true;
    } catch (e) {
      print("Lỗi API updateOrderStatus: $e");
      return false;
    }
  }
}