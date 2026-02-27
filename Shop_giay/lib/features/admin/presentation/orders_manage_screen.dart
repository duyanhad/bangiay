import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/admin_colors.dart';
import '../widgets/admin_drawer.dart';
import '../presentation/admin_controller.dart';
import '../../orders/presentation/order_detail_screen.dart'; 

class OrdersManageScreen extends StatefulWidget {
  const OrdersManageScreen({super.key});

  @override
  State<OrdersManageScreen> createState() => _OrdersManageScreenState();
}

class _OrdersManageScreenState extends State<OrdersManageScreen> {
  String _selectedStatus = 'All'; // Trạng thái đang được lọc
  bool _isNewestFirst = true; // Cờ sắp xếp theo ngày

  // ✅ Khai báo ScrollController để theo dõi thao tác vuốt
  final ScrollController _scrollController = ScrollController();
  
  // ✅ THÊM: Khai báo bộ điều khiển cho thanh tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Danh sách các tab lọc
  final List<Map<String, String>> _statusFilters = [
    {'value': 'All', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ xử lý'},
    {'value': 'confirmed', 'label': 'Đã xác nhận'},
    {'value': 'shipping', 'label': 'Đang giao'},
    {'value': 'done', 'label': 'Hoàn thành'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminController>().loadOrders());

    // Lắng nghe thao tác vuốt, nếu vuốt gần chạm đáy thì gọi tải thêm
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        context.read<AdminController>().loadMoreOrders(status: _selectedStatus);
      }
    });
  }

  // Thêm hàm dispose để hủy ScrollController và SearchController khi thoát màn hình
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose(); // ✅ THÊM: Giải phóng RAM của ô tìm kiếm
    super.dispose();
  }

  // Lấy ra danh sách đơn hàng đã được LỌC, TÌM KIẾM và SẮP XẾP
  List<dynamic> _getFilteredAndSortedOrders(List<dynamic> allOrders) {
    // Dùng List.from() để tạo một bản sao độc lập, không làm hỏng list gốc
    List<dynamic> filtered = List.from(allOrders);

    // 1. Lọc theo trạng thái
    if (_selectedStatus != 'All') {
      filtered = filtered.where((o) => 
          o['status'].toString().toLowerCase() == _selectedStatus.toLowerCase()
      ).toList();
    }

    // ✅ THÊM: Lọc theo từ khóa tìm kiếm (Mã đơn, Tên khách, Số điện thoại)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((o) {
        final id = o['_id']?.toString().toLowerCase() ?? '';
        final name = o['name']?.toString().toLowerCase() ?? '';
        final phone = o['phone']?.toString().toLowerCase() ?? '';
        
        // Nếu query khớp một phần với Mã đơn, Tên, hoặc SĐT thì giữ lại
        return id.contains(query) || name.contains(query) || phone.contains(query);
      }).toList();
    }

    // 2. Sắp xếp theo ngày (createdAt)
    filtered.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      DateTime dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return _isNewestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    return filtered;
  }

  // Hiển thị Dialog đổi trạng thái đơn hàng
  void _showUpdateStatusDialog(BuildContext context, String orderId, String currentStatus) {
    String newStatus = ['pending', 'confirmed', 'shipping', 'done', 'cancelled'].contains(currentStatus) 
        ? currentStatus 
        : 'pending';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Cập nhật trạng thái", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(
            value: newStatus,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text("Chờ xử lý")),
              DropdownMenuItem(value: 'confirmed', child: Text("Đã xác nhận")),
              DropdownMenuItem(value: 'shipping', child: Text("Đang giao")),
              DropdownMenuItem(value: 'done', child: Text("Hoàn thành")),
              DropdownMenuItem(value: 'cancelled', child: Text("Đã hủy")),
            ],
            onChanged: (val) {
              if (val != null) newStatus = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
           ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.header1),
              onPressed: () async {
                Navigator.pop(ctx);
                // Gọi hàm update từ controller
                final success = await context.read<AdminController>().updateStatus(orderId, newStatus);
                
                if (mounted) {
                  // Ép App tải lại toàn bộ đơn hàng từ Database để đồng bộ cấu trúc
                  if (success) {
                    await context.read<AdminController>().loadOrders();
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? "Cập nhật thành công!" : "Cập nhật thất bại!"),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final displayOrders = _getFilteredAndSortedOrders(controller.orders);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text("Quản lý Đơn hàng", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Nút đảo chiều sắp xếp (Mới nhất / Cũ nhất)
          IconButton(
            icon: Icon(_isNewestFirst ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.blue),
            tooltip: _isNewestFirst ? "Đang xem: Mới nhất" : "Đang xem: Cũ nhất",
            onPressed: () {
              setState(() {
                _isNewestFirst = !_isNewestFirst;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // ✅ THÊM: GIAO DIỆN THANH TÌM KIẾM
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm mã đơn, tên, SĐT...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _searchQuery = ''; });
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),

          // THANH LỌC TRẠNG THÁI
          Container(
            height: 50,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    selectedColor: AdminColors.header1.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AdminColors.header1 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatus = filter['value']!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // DANH SÁCH ĐƠN HÀNG
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadOrders(),
              child: controller.isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : displayOrders.isEmpty
                      ? const Center(child: Text("Không có đơn hàng nào!"))
                      : ListView.builder(
                          // Gắn cái ống nghe vuốt vào ListView
                          controller: _scrollController, 
                          padding: const EdgeInsets.all(10),
                          
                          // Tăng itemCount thêm 1 nếu đang load, để chừa chỗ vẽ vòng xoay ở đáy
                          itemCount: displayOrders.length + (controller.isLoadingMore ? 1 : 0),
                          
                          itemBuilder: (context, index) {
                            // Nếu chạy đến index cuối cùng (vị trí dư ra) -> Vẽ cục Loading
                            if (index == displayOrders.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final order = displayOrders[index];
                            return _buildOrderCard(context, order);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Bấm vào card để xem chi tiết
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kiểm tra độ dài an toàn trước khi dùng substring để tránh lỗi RangeError
                  Text(
                    "Mã đơn: ${(order['_id'] != null && order['_id'].toString().length >= 6) ? order['_id'].toString().substring(order['_id'].toString().length - 6).toUpperCase() : (order['_id'] ?? 'LỖI MÃ')}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  // BẤM VÀO CHIP NÀY ĐỂ ĐỔI TRẠNG THÁI
                  GestureDetector(
                    onTap: () => _showUpdateStatusDialog(
                        context, 
                        order['_id']?.toString() ?? '', 
                        order['status']?.toString() ?? 'pending'
                    ),
                    child: _buildStatusChip(order['status']?.toString() ?? 'pending'),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text("Khách hàng: ${order['name'] ?? 'Không rõ'}", style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text("SĐT: ${order['phone'] ?? 'Không rõ'}", style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dùng tryParse thay vì parse để chống Crash App nếu ngày bị lỗi
                  Text(
                    "Ngày đặt: ${() {
                      try {
                        return order['createdAt'] != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['createdAt'].toString()).toLocal()) 
                            : '...';
                      } catch (e) {
                        return 'Không rõ';
                      }
                    }()}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  
                  // Ép về double trước khi format tiền để chống lỗi chuỗi String
                  Text(
                    NumberFormat.currency(locale: 'vi', symbol: '₫').format(
                        double.tryParse(order['total']?.toString() ?? '0') ?? 0
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; text = "Chờ xử lý"; break;
      case 'confirmed': color = Colors.blue; text = "Đã xác nhận"; break;
      case 'shipping': color = Colors.indigo; text = "Đang giao"; break;
      case 'done': color = Colors.green; text = "Hoàn thành"; break;
      case 'cancelled': color = Colors.red; text = "Đã hủy"; break;
      default: color = Colors.grey; text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 12, color: color) // Thêm icon edit nhỏ để báo hiệu bấm được
        ],
      ),
    );
  }
}