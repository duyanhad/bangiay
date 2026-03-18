import 'package:dio/dio.dart';
import '../storage/secure_store.dart';

class DioClient {
  static const String _productionHost = 'https://bangiay-a6e9.onrender.com';

  // 1. TẠO HÀM DÙNG CHUNG ĐỂ LẤY HOST (Dùng cho cả API và Load Ảnh)
  static String get hostUrl {
    return _productionHost;
  }

  // 2. CẤU HÌNH DIO SỬ DỤNG HOST TRÊN
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl:
                '$hostUrl/api/v1', // Tự động nối thêm /api/v1 cho các request
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
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
