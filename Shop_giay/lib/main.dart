import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'router/app_router.dart';

import 'features/cart/domain/cart_controller.dart';
import 'features/cart/data/cart_api.dart';
import 'features/cart/data/cart_repository.dart';
import 'core/api/dio_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(AuthApi())..init()),
        ChangeNotifierProvider(
          create: (_) => CartController(
            CartRepository(CartApi(DioClient.dio)),
          )..loadCart(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}