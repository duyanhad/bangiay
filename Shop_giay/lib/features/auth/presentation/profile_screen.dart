import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller cho phần cập nhật thông tin
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _address;
  late TextEditingController _email; // Email thường chỉ đọc (readonly)

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _email = TextEditingController(text: user?.email ?? '');
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _address = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  // Hàm xử lý Đổi mật khẩu
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKeyDialog = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKeyDialog,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                validator: (v) => v!.isEmpty ? 'Nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (v) => (v!.length < 6) ? 'Tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                validator: (v) {
                  if (v != newPassController.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKeyDialog.currentState!.validate()) return;
              
              // Gọi API đổi pass
              final err = await context.read<AuthController>().changePassword(
                oldPassController.text,
                newPassController.text,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx); // Đóng dialog

              if (err == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $err'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    
    // Nếu chưa đăng nhập (đề phòng) thì hiện nút bắt login
    if (!auth.isLoggedIn) {
      return Center(
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          child: const Text('Vui lòng đăng nhập'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar giả lập
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 20),

              // Email (Readonly)
              TextFormField(
                controller: _email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12,
                ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng mặc định',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Nút Cập nhật
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final err = await auth.updateProfile(
                            name: _name.text.trim(),
                            phone: _phone.text.trim(),
                            address: _address.text.trim(),
                          );

                          if (!context.mounted) return;
                          
                          if (err == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cập nhật thành công!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $err'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              
              // Nút đổi mật khẩu & Lịch sử đơn hàng
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Đổi mật khẩu'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangePasswordDialog(context),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}