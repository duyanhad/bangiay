// lib/features/admin/widgets/admin_drawer.dart

import 'package:flutter/material.dart';
import '../../../core/theme/admin_colors.dart'; 

// ✅ 1. Import đúng đường dẫn tương đối (từ widgets ra presentation)
import '../presentation/admin_dashboard_screen.dart';
import '../presentation/products_manage_screen.dart'; // File có thật trong ảnh
import '../presentation/comments_manage_screen.dart'; // File có thật trong ảnh
import '../presentation/orders_manage_screen.dart';   // File có thật trong ảnh
import '../presentation/categories_manage_screen.dart';
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. Header: Thông tin Admin
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AdminColors.header1, // ✅ Đã sửa thành header1
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AdminColors.header1),
            ),
            accountName: const Text("Admin Shop", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text("admin@shop.com"),
          ),

          // 2. Danh sách Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  onTap: () {
                     Navigator.pop(context);
                     Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                     );
                  },
                ),
                
                const Divider(), 

                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: "Quản lý Sản phẩm",
                  onTap: () {
                    Navigator.pop(context);
                    // ✅ SỬA LỖI: Gọi đúng tên Class ProductsManageScreen
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ProductsManageScreen()),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: "Quản lý Đơn hàng",
                  onTap: () {
                    Navigator.pop(context);
                    // ✅ Đã mở comment vì thấy bạn có file orders_manage_screen.dart
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const OrdersManageScreen())
                    );
                  },
                ),
                
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
                
                _buildMenuItem(
                  context,
                  icon: Icons.comment_outlined,
                  title: "Quản lý Bình luận",
                  onTap: () {
                    Navigator.pop(context);
                    // ✅ SỬA LỖI: Gọi đúng tên Class CommentsManageScreen
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const CommentsManageScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. Footer
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            onTap: () {
              // Xử lý đăng xuất
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}