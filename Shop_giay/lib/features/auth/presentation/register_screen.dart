import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập email';
    final email = v.trim();
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!ok) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập số điện thoại';
    final p = v.trim();
    if (!RegExp(r'^\d{9,11}$').hasMatch(p)) return 'SĐT không hợp lệ (9-11 số)';
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Họ tên'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ' : null,
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập lại mật khẩu';
                        if (v != _pass.text) return 'Mật khẩu nhập lại không khớp';
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

                                final err = await context.read<AuthController>().register(
                                      name: _name.text.trim(),
                                      email: _email.text.trim(),
                                      password: _pass.text.trim(),
                                      phone: _phone.text.trim(),
                                      address: _address.text.trim(),
                                    );

                                if (!context.mounted) return;

                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Register lỗi: $err')),
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
                            : const Text('Tạo tài khoản'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Đã có tài khoản? Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
