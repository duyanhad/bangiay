import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
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
      /// ✅ FULL SCREEN ROUTES
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),

      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(body: Center(child: Text("Lỗi dữ liệu đơn hàng")));
          }
          return OrderSuccessScreen(
            totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: extra['paymentMethod'] ?? 'cod',
            orderItems: extra['orderItems'] ?? [],
          );
        },
      ),

      /// ✅ SHELL ROUTES (Có Bottom Bar)
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

          GoRoute(
            path: '/orders', 
            builder: (context, state) => const OrderHistoryScreen(),
          ),

          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}