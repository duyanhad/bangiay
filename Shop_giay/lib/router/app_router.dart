import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/product_list_screen.dart';
import '../shell/app_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // ✅ Auth routes (để ngoài Shell để không dính bottom nav)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ✅ App shell routes
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['id']!,
            ),
          ),

          GoRoute(path: '/cart', builder: (_, __) => const _Placeholder(title: 'Giỏ hàng')),
          GoRoute(path: '/orders', builder: (_, __) => const _Placeholder(title: 'Đơn hàng')),
          GoRoute(path: '/profile', builder: (_, __) => const _Placeholder(title: 'Tài khoản')),
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
