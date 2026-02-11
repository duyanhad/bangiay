import 'package:dio/dio.dart';

class DioClient {
  // Dùng dart-define để đổi baseUrl theo web/android:
  // Web:    --dart-define=API_BASE_URL=http://localhost:8080/api/v1
  // Android emulator: --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
}
