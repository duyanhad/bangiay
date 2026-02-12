import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/auth_models.dart';

class AuthApi {
  final Dio _dio = DioClient.dio;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? address,
  }) async {
    final res = await _dio.post(
      Endpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      },
    );

    final data = (res.data['data'] ?? {}) as Map<String, dynamic>;
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      Endpoints.authLogin,
      data: {'email': email, 'password': password},
    );

    final data = (res.data['data'] ?? {}) as Map<String, dynamic>;
    return AuthResult.fromJson(data);
  }

  Future<AppUser> me() async {
    final res = await _dio.get(Endpoints.authMe);
    final data = (res.data['data'] ?? {}) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }
}
