import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/styles/app_spacing.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtl = TextEditingController(text: "duy@gmail.com");
  final passCtl = TextEditingController(text: "123456");

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("DEBUG LOGIN", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 24),

            // 🔥 NÚT DEBUG – BẤM LÀ PHẢI LOG
            ElevatedButton(
              onPressed: () async {
                print("🔥 CLICK LOGIN BUTTON");
                print("EMAIL: ${emailCtl.text}");
                print("PASS: ${passCtl.text}");

                try {
                  await auth.login(
                    emailCtl.text.trim(),
                    passCtl.text.trim(),
                  );

                  print("✅ LOGIN SUCCESS → GO HOME");

                  if (mounted) context.go("/home");
                } catch (e) {
                  print("❌ LOGIN ERROR: $e");
                }
              },
              child: const Text("LOGIN (DEBUG)"),
            ),
          ],
        ),
      ),
    );
  }
}
