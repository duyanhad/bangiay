import 'package:flutter/material.dart';

class AdminStyles {
  /// ===== COLORS =====
  static const primaryColor = Color(0xff1E88E5);
  static const bgColor = Color(0xffF5F6FA);
  static const cardColor = Colors.white;

  /// ===== TEXT STYLES =====
  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );

  static const price = TextStyle(
    fontSize: 15,
    color: Colors.red,
    fontWeight: FontWeight.bold,
  );

  /// ===== CARD DECORATION =====
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      )
    ],
  );

  /// ===== INPUT DECORATION =====
  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
