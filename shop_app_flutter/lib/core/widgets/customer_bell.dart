import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

class CustomerBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const CustomerBell({super.key, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.notifications),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: AppColors.danger,
                child: Text("$count", style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
            )
        ],
      ),
    );
  }
}
