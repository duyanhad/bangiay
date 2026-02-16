import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ✅ 1. Import đúng file màu vừa tạo
import '../../../core/theme/admin_colors.dart';

// ✅ 2. Import Controller và Model (kiểm tra lại đường dẫn nếu bạn lưu khác)
import '../presentation/admin_controller.dart';
import '../data/admin_models.dart'; // File này chứa class AdminStats và SimpleProduct

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
                      _buildHeader(),
                      _buildRevenue(stats),
                      _buildStats(stats),
                      _buildLowStock(stats),
                      _buildTopSelling(stats),
                      const SizedBox(height: 50), // Khoảng trống dưới cùng
                    ],
                  ),
                ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity, // Full chiều ngang
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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
            "Dashboard Admin",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Tổng quan tình hình kinh doanh",
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

  // ✅ Đã sửa lỗi logic map dữ liệu ở đây
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
              children: items.map((product) { // Đổi tên biến e thành product cho dễ hiểu
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isLowStock ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Icon(
                      isLowStock ? Icons.warning_amber_rounded : Icons.whatshot,
                      color: isLowStock ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  // ✅ SỬA LỖI: Dùng product.name thay vì product["name"]
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
                      // ✅ SỬA LỖI: Truy cập thuộc tính object
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