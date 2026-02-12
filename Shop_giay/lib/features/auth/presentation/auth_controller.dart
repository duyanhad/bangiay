import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_store.dart';
import '../data/auth_api.dart';
import '../domain/auth_models.dart';

class AuthController extends ChangeNotifier {
  final AuthApi _api;

  AuthController(this._api);

  AppUser? user;
  bool isLoading = false;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    final token = await SecureStore.getToken();
    if (token == null || token.isEmpty) return;

    try {
      user = await _api.me();
      notifyListeners();
    } catch (_) {
      await SecureStore.clearToken();
      user = null;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _api.login(email: email, password: password);
      await SecureStore.saveToken(result.token);
      user = result.user;
      notifyListeners(); 
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _api.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );
      await SecureStore.saveToken(result.token);
      user = result.user;
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SecureStore.clearToken();
    user = null;
    notifyListeners();
  }
}
