import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/product_list_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../shell/app_shell.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/orders/presentation/orders_history_screen.dart';
import '../features/orders/presentation/order_success_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      /// ✅ AUTH, CHECKOUT & SUCCESS (Full màn hình, không menu dưới)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),

      // ĐƯA RA NGOÀI SHELL: Để trang này chiếm toàn màn hình, không bị kẹt bởi BottomBar
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          // Kiểm tra và lấy dữ liệu an toàn
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text("Lỗi: Không tìm thấy thông tin đơn hàng")));
          }
          return OrderSuccessScreen(
            totalAmount: extra['totalAmount'] ?? 0.0,
            paymentMethod: extra['paymentMethod'] ?? 'cod',
            orderItems: extra['orderItems'] ?? [],
          );
        },
      ),

      /// ✅ APP SHELL (Những trang có Bottom Bar)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ProductListScreen()),
          
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['id']!,
            ),
          ),

          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),

          // ĐƯA ORDERS VÀO ĐÂY ĐỂ HIỆN BOTTOM BAR
          GoRoute(
            path: '/orders', 
            builder: (context, state) => const OrderHistoryScreen(),
          ),

          GoRoute(
            path: '/profile',
            builder: (_, __) => const _Placeholder(title: 'Tài khoản'),
          ),
        ],
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đây là màn hình $title'),
            const SizedBox(height: 20),
            if (title == 'Tài khoản')
              ElevatedButton(
                onPressed: () => context.push('/orders'), 
                child: const Text("Xem Lịch sử đơn hàng"),
              ),
          ],
        ),
      ),
    );
  }
}