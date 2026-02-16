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
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _address = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _changePassword() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: dialogKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập' : null,
              ),
              TextFormField(
                controller: newPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Tối thiểu 6 ký tự' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (!dialogKey.currentState!.validate()) return;
              final err = await context.read<AuthController>().changePassword(oldPass.text, newPass.text);
              if (!ctx.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              auth.logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: auth.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                      const SizedBox(height: 20),
                      Text(user?.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Không được để trống' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final err = await auth.updateProfile({
                              'name': _name.text,
                              'phone': _phone.text,
                              'address': _address.text,
                            });
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err ?? 'Cập nhật thành công'))
                            );
                          },
                          child: const Text('LƯU THÔNG TIN'),
                        ),
                      ),
                      TextButton(
                        onPressed: _changePassword,
                        child: const Text('Bạn muốn đổi mật khẩu?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}