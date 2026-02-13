import 'package:flutter/material.dart';
import 'package:shop_giay/core/storage/secure_store.dart';
import 'package:shop_giay/features/auth/presentation/login_screen.dart';

class AuthGuard {
  static Future<bool> check(BuildContext context) async {
    final token = await SecureStore.getToken();

    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }

    return true;
  }
}
