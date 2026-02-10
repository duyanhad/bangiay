import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../../core/storage/token_storage.dart';

class AuthService {
  AuthService(this._api, this._storage);
  final ApiClient _api;
  final TokenStorage _storage;

  Future<void> login(String email, String password) async {
    print("LOGIN REQUEST: $email");

    final res = await _api.dio.post(
      Endpoints.login,
      data: {
        "email": email,
        "password": password,
      },
    );

    print("LOGIN RESPONSE: ${res.data}");

    final token = res.data["token"];
    if (token == null || token.isEmpty) {
      throw Exception("Login failed: no token");
    }

    await _storage.save(token);
  }

  Future<void> logout() => _storage.clear();
}
