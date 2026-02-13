import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/product_list_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../shell/app_shell.dart';
import '../features/checkout/presentation/checkout_screen.dart';
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      /// ✅ AUTH
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      /// ✅ APP SHELL
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          /// HOME
          GoRoute(
            path: '/',
            builder: (_, __) => const ProductListScreen(),
          ),

          /// PRODUCT DETAIL
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
            GoRoute(
  path: '/checkout',
  builder: (context, state) => const CheckoutScreen(),
),
      /// ✅ CART — ĐÃ DỌN DẸP SẠCH SẼ
         GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(), 
          ),
          /// PROFILE
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
      body: const Center(child: Text('Sẽ làm ở bước sau')),
    );
  }
}
