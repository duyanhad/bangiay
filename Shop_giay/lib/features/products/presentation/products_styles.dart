import 'package:flutter/material.dart';
import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/app_radius.dart';

class ProductsStyles {
  static const pagePadding = EdgeInsets.all(S.md);
  static const cardRadius = BorderRadius.all(Radius.circular(R.md));

  // 🎨 Màu chủ đạo (bạn đổi tùy thích)
  static const primary = Color(0xFF00796B); // teal
  static const bg = Color(0xFFF6F7F8);
  static const border = Color(0xFFEAEAEA);

  static TextStyle price(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900);

  static ButtonStyle primaryBtn() => FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
      );

  static ButtonStyle outlineBtn() => OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
      );
}
