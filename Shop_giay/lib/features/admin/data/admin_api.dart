import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../data/admin_models.dart';

class AdminApi {
  final Dio _dio = DioClient.dio;

  Future<AdminStats> getStats() async {
    final res = await _dio.get(Endpoints.adminStats);
    // Backend trả về: { ok: true, data: { ...stats... } }
    final data = res.data['data'] as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }
}