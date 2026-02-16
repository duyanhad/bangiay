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
  final nf = NumberFormat("#,###", "en_US");

  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
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
    setState(() {
      _filteredOrders = _allOrders.where((o) {
        final orderId = o['_id'].toString().toLowerCase();
        final status = (o['status'] ?? '').toString().toLowerCase();
        final total = o['total'].toString();
        final searchLower = query.toLowerCase();
        
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
      case 'success': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // --- PHẦN QUAN TRỌNG: SỬA HÀM NÀY ĐỂ BẤM VÀO ĐƯỢC ---
  void _handleOrderTap(dynamic order) async {
    // 1. Hiển thị vòng xoay loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Gọi API lấy dữ liệu chi tiết đầy đủ
      final fullOrder = await _orderApi.getOrderById(order['_id']).timeout(
        const Duration(seconds: 5), // Thêm timeout để không bị treo nếu mạng yếu
      );
      
      if (mounted) {
        // 3. ĐÓNG LOADING TRƯỚC KHI CHUYỂN TRANG
        Navigator.of(context, rootNavigator: true).pop();

        // 4. Chuyển sang trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: fullOrder ?? order),
          ),
        );
      }
    } catch (e) {
      // 5. NẾU API LỖI: Vẫn phải đóng loading và cho người dùng xem chi tiết bằng dữ liệu cũ
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); 
        
        // Vẫn mở trang detail với 'order' hiện tại để không gây ức chế cho người dùng
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Tìm mã đơn, trạng thái, giá tiền...",
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text("Đơn hàng của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.arrow_back_ios : Icons.search),
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
          : Column(
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
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final String status = order['status'] ?? 'pending';
                            final String orderIdStr = order['_id'].toString();
                            final String displayId = orderIdStr.length > 10 
                                ? orderIdStr.substring(orderIdStr.length - 8).toUpperCase() 
                                : orderIdStr;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
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
                                    "Tổng: ${nf.format(order['total'])}đ",
                                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () => _handleOrderTap(order), // Sửa ở đây
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}