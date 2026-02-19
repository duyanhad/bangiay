import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ✅ 1. Import đúng file màu
import '../../../core/theme/admin_colors.dart';

// ✅ 2. Import Controller và Model
import '../presentation/admin_controller.dart';
import '../data/admin_models.dart';

// ✅ 3. Import Drawer (Menu bên trái)
import '../widgets/admin_drawer.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dữ liệu ngay khi vào màn hình
    Future.microtask(() =>
        context.read<AdminController>().loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final stats = controller.stats;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      
      // 🔥 THÊM DÒNG NÀY ĐỂ HIỆN MENU TRÁI
      drawer: const AdminDrawer(), 
      
      appBar: AppBar(
        title: const Text("Dashboard Admin", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black), // Màu icon menu (3 gạch)
      ),

      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.error ?? "Không có dữ liệu"),
                      ElevatedButton(
                        onPressed: () => context.read<AdminController>().loadStats(),
                        child: const Text("Thử lại"),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(), // Header màu xanh
                      _buildRevenue(stats),
                      _buildStats(stats),
                      _buildLowStock(stats),
                      _buildTopSelling(stats),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AdminColors.header1, AdminColors.header2],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Xin chào, Admin!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Tổng quan tình hình kinh doanh hôm nay",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenue(AdminStats stats) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AdminColors.accent, AdminColors.header2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AdminColors.accent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            const Text("TỔNG DOANH THU",
                style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Text(
              NumberFormat.currency(locale: 'vi', symbol: '₫').format(stats.revenue),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStats(AdminStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statItem("Đơn hàng", stats.orderCount, Icons.shopping_bag_outlined),
          const SizedBox(width: 10),
          _statItem("Sản phẩm", stats.productCount, Icons.inventory_2_outlined),
          const SizedBox(width: 10),
          _statItem("Tồn kho", stats.totalStock, Icons.warehouse_outlined),
        ],
      ),
    );
  }

  Widget _statItem(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AdminColors.accent, size: 28),
            const SizedBox(height: 8),
            Text(
              "$value",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.header1),
            ),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStock(AdminStats stats) {
    return _listSection("⚠️ Sắp hết hàng", stats.lowStock, isLowStock: true);
  }

  Widget _buildTopSelling(AdminStats stats) {
    return _listSection("🔥 Bán chạy nhất", stats.topSelling, isLowStock: false);
  }

  Widget _listSection(String title, List<SimpleProduct> items, {required bool isLowStock}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AdminColors.header1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: items.map((product) { 
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  
                  // Hiển thị ảnh thay vì icon
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                      image: DecorationImage(
                        image: (product.images.isNotEmpty)
                          ? NetworkImage(product.images.first)
                          : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                        fit: BoxFit.cover
                      )
                    ),
                  ),
                  
                  title: Text(product.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLowStock
                          ? "SL: ${product.stock}"
                          : "Đã bán: ${product.soldCount}",
                      style: TextStyle(
                        color: isLowStock ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}