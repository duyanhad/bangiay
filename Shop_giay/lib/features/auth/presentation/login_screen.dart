import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập email';
    final email = v.trim();
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!ok) return 'Email không hợp lệ';
    return null;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu >= 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final err = await context.read<AuthController>().login(
                                    _email.text.trim(),
                                    _pass.text.trim(),
                                  );

                              if (!context.mounted) return;

                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login lỗi: $err')),
                                );
                              } else {
                                context.go('/'); // về home
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
