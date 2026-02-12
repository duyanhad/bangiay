import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>(
      create: (_) => AuthController(AuthApi())..init(),
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthController>();
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
