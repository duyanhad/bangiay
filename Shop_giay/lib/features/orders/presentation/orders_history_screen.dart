import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/order_api.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderApi _orderApi = OrderApi();
  final TextEditingController _searchController = TextEditingController();
  
  // Format tiền VNĐ chuẩn: 1.000.000đ
  final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Chuyển thành Future để dùng được với RefreshIndicator
  Future<void> _loadOrders() async {
    try {
      final data = await _orderApi.fetchMyOrders();
      if (mounted) {
        setState(() {
          _allOrders = data;
          _filteredOrders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    final searchLower = query.toLowerCase();
    setState(() {
      _filteredOrders = _allOrders.where((o) {
        final orderId = o['_id'].toString().toLowerCase();
        final status = (o['status'] ?? '').toString().toLowerCase();
        final total = o['total'].toString();
        
        return orderId.contains(searchLower) || 
               status.contains(searchLower) || 
               total.contains(searchLower);
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipping': return Colors.purple;
      case 'delivered':
      case 'done':
      case 'success': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // --- HÀM XỬ LÝ BẤM VÀO ĐƠN HÀNG (ĐÃ FIX LỖI LOGIC) ---
  void _handleOrderTap(dynamic order) async {
    // 1. Hiển thị vòng xoay loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Gọi API lấy dữ liệu chi tiết
      final fullOrder = await _orderApi.getOrderById(order['_id']).timeout(
        const Duration(seconds: 8), 
      );
      
      // KIỂM TRA MOUNTED SAU ASYNC
      if (!mounted) return;

      // 3. ĐÓNG LOADING (Dùng rootNavigator để an toàn)
      Navigator.of(context, rootNavigator: true).pop();

      // 4. Chuyển sang trang chi tiết
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: fullOrder ?? order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // 5. NẾU LỖI: Đóng loading và vẫn cho xem bằng data cũ
      Navigator.of(context, rootNavigator: true).pop(); 
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: order),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Tìm mã đơn, trạng thái...",
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text("Đơn hàng của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredOrders = _allOrders;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Thêm vuốt để tải lại trang
              onRefresh: _loadOrders,
              child: Column(
                children: [
                  if (_isSearching)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Text(
                        "Tìm thấy ${_filteredOrders.length} đơn hàng",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  Expanded(
                    child: _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _filteredOrders.length,
                            padding: const EdgeInsets.all(12),
                            physics: const AlwaysScrollableScrollPhysics(), // Để RefreshIndicator hoạt động khi ít item
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              final String status = order['status'] ?? 'pending';
                              final String orderIdStr = order['_id'].toString();
                              final String displayId = orderIdStr.length > 8 
                                  ? orderIdStr.substring(orderIdStr.length - 8).toUpperCase() 
                                  : orderIdStr;

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  onTap: () => _handleOrderTap(order),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Mã: #$displayId", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      "Tổng: ${nf.format(order['total'])}",
                                      style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Dùng ListView để vuốt refresh được
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text("Không có dữ liệu đơn hàng", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}