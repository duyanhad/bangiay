import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_providers.dart';
import 'app/app_router.dart';
import 'core/styles/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: buildProviders(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
