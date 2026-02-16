import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Đảm bảo đường dẫn này đúng với project của bạn (giống trong ProductDetail)
import '../../../core/config/app_config.dart'; 

class OrderDetailScreen extends StatelessWidget {
  final dynamic order;
  const OrderDetailScreen({super.key, required this.order});

  // Hàm xử lý link ảnh chuẩn theo AppConfig
  String _getValidImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;

    // Lấy BaseURL từ AppConfig giống ProductDetail
    String base = AppConfig.baseUrl;

    // FIX LỖI ANDROID: Nếu chạy máy ảo, localhost phải đổi thành 10.0.2.2
    if (base.contains('localhost')) {
      base = base.replaceFirst('localhost', '10.0.2.2');
    }

    // Xử lý dấu gạch chéo để tránh bị // hoặc thiếu /
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String cleanPath = path.startsWith('/') ? path : '/$path';

    return "$base$cleanPath";
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final List items = order['items'] ?? [];
    
    // Lấy thông tin người nhận
    final String customerName = order['name'] ?? order['userId']?['name'] ?? 'Khách lẻ';
    final String phone = order['phone'] ?? order['userId']?['phone'] ?? '---';
    final String address = order['address'] ?? order['userId']?['address'] ?? '---';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Chi tiết đơn hàng"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Trạng thái
            _buildStatusHeader(order['status'] ?? 'pending'),

            // 2. Địa chỉ
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text("Địa chỉ nhận hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(phone, style: const TextStyle(color: Colors.black54)),
                  Text(address, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),

            // 3. Danh sách sản phẩm
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    // --- GỌI HÀM XỬ LÝ ẢNH ---
                    String imgUrl = _getValidImageUrl(item['image']);
                    // -------------------------

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 60, height: 60,
                              color: Colors.grey.shade100,
                              child: imgUrl.isNotEmpty
                                  ? Image.network(
                                      imgUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? 'Sản phẩm', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text("Size: ${item['size'] ?? 'Free'} | x${item['qty'] ?? 1}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(currencyFormat.format(item['price'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // 4. Tổng tiền
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 30),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _rowPrice("Phương thức", (order['paymentMethod'] ?? 'COD').toString().toUpperCase()),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Thành tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currencyFormat.format(order['total'] ?? 0), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowPrice(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value)]);
  }

  Widget _buildStatusHeader(String status) {
    // Giữ nguyên logic màu sắc status của bạn
    Color color = Colors.orange;
    String text = "Đang xử lý";
    if (status == 'success' || status == 'done') { color = Colors.green; text = "Hoàn thành"; }
    else if (status == 'shipping') { color = Colors.blue; text = "Đang giao"; }
    else if (status == 'cancelled') { color = Colors.red; text = "Đã hủy"; }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), color: color,
      child: Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}