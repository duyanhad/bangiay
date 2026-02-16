import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  // Tối ưu hàm lấy index để đảm bảo luôn sáng đúng nút dưới thanh menu
  int _indexFromLocation(String location) {
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Mặc định là trang Shop (/)
  }

  @override
  Widget build(BuildContext context) {
    // Lấy full path để so sánh chính xác hơn
    final String location = GoRouterState.of(context).matchedLocation;
    final int index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        // Giữ nguyên logic điều hướng của bạn
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/cart');
              break;
            case 2:
              context.go('/orders');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined), 
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined), 
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined), 
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }
}