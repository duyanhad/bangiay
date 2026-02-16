import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- CORE & CONFIG ---
import 'core/theme/app_theme.dart';
import 'core/api/dio_client.dart';
import 'router/app_router.dart';

// --- FEATURE: AUTH ---
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/auth_controller.dart';

// --- FEATURE: CART ---
import 'features/cart/domain/cart_controller.dart';
import 'features/cart/data/cart_api.dart';
import 'features/cart/data/cart_repository.dart';

// --- FEATURE: ADMIN (MỚI) ---
// Đảm bảo đường dẫn này đúng với nơi bạn lưu file admin_controller.dart
import 'features/admin/presentation/admin_controller.dart';

void main() {
  // Đảm bảo binding được khởi tạo trước
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Auth Provider (Xử lý đăng nhập/đăng ký)
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthApi())..init(),
        ),

        // 2. Cart Provider (Giỏ hàng)
        ChangeNotifierProvider(
          create: (_) => CartController(
            CartRepository(CartApi(DioClient.dio)),
          )..loadCart(),
        ),

        // 3. Admin Provider (QUAN TRỌNG: Để trang Admin Dashboard hoạt động)
        ChangeNotifierProvider(
          create: (_) => AdminController(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'E-Commerce App',
        theme: AppTheme.light(),
        routerConfig: AppRouter.router, // Sử dụng GoRouter từ app_router.dart
      ),
    );
  }
}