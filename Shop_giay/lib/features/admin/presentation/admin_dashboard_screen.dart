import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';

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
    Future.microtask(() => context.read<AdminController>().loadStats());
  }

  // --- HÀM XỬ LÝ ẢNH CHUẨN ---
  String _getValidImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;

    String base = AppConfig.baseUrl;

    // CHỈ đổi localhost khi chạy ANDROID
    if (!kIsWeb && base.contains('localhost')) {
      base = base.replaceFirst('localhost', '10.0.2.2');
    }

    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String cleanPath = path.startsWith('/') ? path : '/$path';
    
    String finalUrl = "$base$cleanPath";
    // IN RA CONSOLE ĐỂ KIỂM TRA ĐƯỜNG DẪN CÓ ĐÚNG CHƯA
    debugPrint("🛠 URL Ảnh Dashboard: $finalUrl"); 
    
    return finalUrl;
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
                    children: [
                      // 1. Phần Ảnh sản phẩm
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (product.images.isNotEmpty)
                              ? Image.network(
                                  _getValidImageUrl(product.images.first),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image_not_supported, color: Colors.grey, size: 24);
                                  },
                                )
                              : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24),
                        ),
                      ),
                      
                      const SizedBox(width: 12), // Khoảng cách giữa ảnh và chữ
                      
                      // 2. Phần Tên sản phẩm
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 14,
                          ),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ),
                      
                      const SizedBox(width: 8), 
                      
                      // 3. Nhãn "Đã bán: X" hoặc "Tồn kho: X"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          // Nếu là list Sắp hết hàng thì nhãn màu đỏ/cam, Bán chạy thì màu xanh
                          color: isLowStock ? Colors.orange.shade50 : Colors.green.shade50, 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLowStock ? "Tồn kho: " : "Đã bán: ",
                              style: TextStyle(
                                fontSize: 12, 
                                color: isLowStock ? Colors.orange.shade700 : Colors.green.shade700,
                              ),
                            ),
                            Text(
                              isLowStock ? "${product.stock}" : "${product.soldCount}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: isLowStock ? Colors.orange.shade700 : Colors.green.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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