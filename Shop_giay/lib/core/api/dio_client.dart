import 'package:dio/dio.dart';
import '../storage/secure_store.dart';

class DioClient {
  // Web:    --dart-define=API_BASE_URL=http://localhost:8080/api/v1
  // Android emulator: --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
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
