import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/product_list_screen.dart';
import '../shell/app_shell.dart';

class AppRouter {
  static final router = GoRouter(
    
    initialLocation: '/',
    routes: [
      
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const ProductListScreen()),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
          ),

          // Placeholder (bước sau mình làm Cart/Orders/Profile)
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
    return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: Text('Sẽ làm ở bước sau')));
  }
}
