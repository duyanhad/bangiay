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

  // Validate Email
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
    // Dùng watch để lắng nghe state (loading)
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
                  // --- EMAIL INPUT ---
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // --- PASSWORD INPUT ---
                  TextFormField(
                    controller: _pass,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu >= 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- LOGIN BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              // 1. Validate Form
                              if (!_formKey.currentState!.validate()) return;

                              // In log bắt đầu
                              print('>>> [LOGIN] Bắt đầu đăng nhập...');

                              // 2. Gọi API Login (Dùng context.read cho hành động)
                              final controller = context.read<AuthController>();
                              
                              final err = await controller.login(
                                _email.text.trim(),
                                _pass.text.trim(),
                              );

                              if (!context.mounted) return;

                              // 3. Xử lý kết quả
                              if (err != null) {
                                print('>>> [LOGIN] Thất bại: $err');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $err'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                // --- PHÂN LUỒNG QUAN TRỌNG ---
                                final user = controller.user;
                                
                                // LOG KIỂM TRA DỮ LIỆU
                                print('>>> [LOGIN] Thành công! Đang kiểm tra Role...');
                                print('>>> [LOGIN] User Data: ${user.toString()}');
                                print('>>> [LOGIN] Raw Role from DB: "${user?.role}"');

                                // Xử lý role an toàn: Bỏ khoảng trắng thừa, chuyển về chữ thường
                                final safeRole = user?.role.trim().toLowerCase();
                                print('>>> [LOGIN] Processed Role: "$safeRole"');

                                if (safeRole == 'admin') {
                                  print('>>> [LOGIN] => Là ADMIN. Chuyển hướng /admin/dashboard');
                                  try {
                                    context.go('/admin/dashboard');
                                  } catch (e) {
                                    print('>>> [LOGIN] ❌ LỖI ROUTER: $e');
                                    print('>>> Hãy kiểm tra lại file app_router.dart xem có path "/admin/dashboard" chưa');
                                  }
                                } else {
                                  print('>>> [LOGIN] => Là USER. Chuyển hướng /');
                                  context.go('/');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- REGISTER LINK ---
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Chưa có tài khoản? Đăng ký ngay'),
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