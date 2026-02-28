import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../storage/secure_store.dart';

class DioClient {
  // 1. TẠO HÀM DÙNG CHUNG ĐỂ LẤY HOST (Dùng cho cả API và Load Ảnh)
  static String get hostUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (e) {}
    // Thay IP này bằng IP Wifi máy tính của bạn nếu chạy trên máy thật
    return 'http://192.168.1.100:8080'; 
  }

  // 2. CẤU HÌNH DIO SỬ DỤNG HOST TRÊN
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: '$hostUrl/api/v1', // Tự động nối thêm /api/v1 cho các request
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
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