import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_store.dart';

class DioClient {
  static const String _productionHost = 'https://bangiay-a6e9.onrender.com';
  static const String _localHost = 'http://10.0.2.2:8080';

  // 🔥 HÀM LẤY HOST DỰA VÀO ENVIRONMENT
  static String get hostUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return kDebugMode ? _localHost : _productionHost;
    }
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
