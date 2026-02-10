import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/styles/app_spacing.dart';
import '../cart/cart_provider.dart';
import '../orders/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _storage = const FlutterSecureStorage();

  String? errorText;
  bool loading = false;

  int? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload);
      return map['userId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    final orderService = context.read<OrderService>();

    final token = await _storage.read(key: "token");
    if (token == null || token.isEmpty) {
      setState(() => errorText = "Bạn chưa đăng nhập");
      return;
    }

    final userId = _userIdFromJwt(token);
    if (userId == null) {
      setState(() => errorText = "Token không hợp lệ");
      return;
    }

    if (_nameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty) {
      setState(() => errorText = "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      await orderService.createOrder(
        token: token,
        userId: userId,
        customerName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        shippingAddress: _addressCtrl.text.trim(),
        totalAmount: cart.total,
        items: cart.items.map((e) {
          return {
            // ✅ FIX KEY KHỚP BE
            "product_id": e.productId,
            "name": e.name,
            "price": e.price,
            "quantity": e.qty,
            "image_url": e.image ?? "",
          };
        }).toList(),
        notes: _noteCtrl.text.trim(),
      );

      cart.clear();
      if (mounted) Navigator.pushReplacementNamed(context, "/thankyou");
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Họ tên")),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Số điện thoại")),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: "Địa chỉ")),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: "Ghi chú (tuỳ chọn)")),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tổng tiền: ${cart.total.toStringAsFixed(0)} ₫",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đặt hàng"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
