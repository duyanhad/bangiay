import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      headers: {"Content-Type": "application/json"},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;
}
