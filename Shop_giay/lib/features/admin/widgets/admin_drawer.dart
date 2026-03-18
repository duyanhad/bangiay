// lib/features/admin/widgets/admin_drawer.dart

import 'package:flutter/material.dart';
import '../../../core/theme/admin_colors.dart';
import 'package:shop_giay/features/auth/presentation/login_screen.dart';

// Screens
import '../presentation/admin_dashboard_screen.dart';
import '../presentation/products_manage_screen.dart';
import '../presentation/comments_manage_screen.dart';
import '../presentation/orders_manage_screen.dart';
import '../presentation/categories_manage_screen.dart';
import '../presentation/charts_manage_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [

          /// ==============================
          /// HEADER ADMIN
          /// ==============================
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AdminColors.header1,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AdminColors.header1),
            ),
            accountName: Text(
              "Admin Shop",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("admin@shop.com"),
          ),

          /// ==============================
          /// MENU LIST
          /// ==============================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [

                /// DASHBOARD
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                /// CHARTS
                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: "Thống kê & Biểu đồ",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ChartsManageScreen(),
                      ),
                    );
                  },
                ),

                /// PRODUCTS
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: "Quản lý Sản phẩm",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ProductsManageScreen(),
                      ),
                    );
                  },
                ),

                /// ORDERS
                _buildMenuItem(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: "Quản lý Đơn hàng",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const OrdersManageScreen(),
                      ),
                    );
                  },
                ),

                /// CATEGORIES
                _buildMenuItem(
                  context,
                  icon: Icons.category_outlined,
                  title: "Quản lý Danh mục",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesManageScreen(),
                      ),
                    );
                  },
                ),

                /// COMMENTS
                _buildMenuItem(
                  context,
                  icon: Icons.comment_outlined,
                  title: "Quản lý Bình luận",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const CommentsManageScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          /// ==============================
          /// FOOTER LOGOUT
          /// ==============================
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {

              /// đóng drawer
              Navigator.pop(context);

              /// chuyển về login và xóa toàn bộ stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ==============================
  /// MENU ITEM WIDGET
  /// ==============================
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}