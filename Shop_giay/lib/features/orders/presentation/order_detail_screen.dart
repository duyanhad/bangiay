import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
// ✅ SỬ DỤNG APP CONFIG
import '../../../core/config/app_config.dart';

class OrderDetailScreen extends StatelessWidget {
  final dynamic order;
  const OrderDetailScreen({super.key, required this.order});

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

  return "$base$cleanPath";
}

  // --- HÀM FORMAT TIỀN TỆ ---
  String _formatCurrency(dynamic price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Ép kiểu về double/int để tránh lỗi format
    return format.format(double.tryParse(price.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    // Logic sửa lỗi: Truy xuất dữ liệu lồng nhau từ Backend (populate userId)
    final List items = (order['items'] is List) ? order['items'] : [];

    // Sửa logic: Ưu tiên lấy trực tiếp từ Order (vì khi tạo đơn đã lưu name/phone/address snapshot)
    final String customerName = order['name'] ?? 
                               (order['userId'] is Map ? order['userId']['name'] : 'Khách lẻ');
    
    final String phone = order['phone'] ?? 
                        (order['userId'] is Map ? order['userId']['phone'] : '---');
    
    final String address = order['address'] ?? 
                          (order['userId'] is Map ? order['userId']['address'] : '---');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        // Sửa logic: Hiển thị 6 ký tự cuối của ID cho chuyên nghiệp
        title: Text("Chi tiết đơn #${order['_id']?.toString().substring(order['_id'].toString().length - 6).toUpperCase() ?? ''}"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Trạng thái (Logic check trạng thái lcase)
            _buildStatusHeader(order['status']?.toString().toLowerCase() ?? 'pending'),

            // 2. Thông tin nhận hàng
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text("Địa chỉ nhận hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(phone, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 5),
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
                  if (items.isEmpty) 
                    const Center(child: Text("Không có sản phẩm nào", style: TextStyle(fontStyle: FontStyle.italic))),
                  
                  ...items.map((item) {
                     String imgUrl = "";

  // Ưu tiên ảnh snapshot trong Order
  if (item['image'] != null && item['image'].toString().isNotEmpty) {
    imgUrl = item['image'];
  }

  // Nếu không có thì lấy từ product populate
  final product = item['product'];
  if (imgUrl.isEmpty &&
      product != null &&
      product['images'] != null &&
      product['images'] is List &&
      product['images'].isNotEmpty) {
    imgUrl = _getValidImageUrl(product['images'][0]);
  }

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 70, height: 70,
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
                                Text(item['name'] ?? 'Sản phẩm', 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                // Sửa logic: Check null cho size
                                Text("Size: ${item['size'] ?? 'Free'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("x${item['qty'] ?? 1}", style: const TextStyle(fontSize: 13)),
                                    Text(_formatCurrency(item['price']), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // 4. Thanh toán
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 30),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _rowPrice("Phương thức thanh toán", _mapPaymentMethod(order['paymentMethod'])),
                  const SizedBox(height: 10),
                  _rowPrice("Tổng tiền hàng", _formatCurrency(order['total'])),
                  _rowPrice("Phí vận chuyển", "Miễn phí"),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Thành tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        _formatCurrency(order['total']),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
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

  // --- WIDGET CON & HELPER ---

  Widget _rowPrice(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _mapPaymentMethod(String? method) {
    final m = method?.toLowerCase() ?? 'cod';
    if (m == 'cod') return 'Thanh toán khi nhận hàng (COD)';
    if (m == 'vnpay') return 'Ví điện tử VNPAY';
    return m.toUpperCase();
  }

  Widget _buildStatusHeader(String status) {
    Color color;
    String text;
    IconData icon;

    // Logic: Khớp với Enum trong order.model.js của bạn
    switch (status) {
      case 'done':
        color = const Color(0xFF00C853);
        text = "Hoàn thành";
        icon = Icons.check_circle;
        break;
      case 'shipping':
        color = Colors.blue;
        text = "Đang giao hàng";
        icon = Icons.local_shipping;
        break;
      case 'confirmed':
        color = const Color.fromARGB(255, 3, 20, 207);
        text = "Đã xác nhận";
        icon = Icons.thumb_up;
        break;
      case 'cancelled':
        color = Colors.red;
        text = "Đã hủy";
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFFFFAB00);
        text = "Chờ xử lý";
        icon = Icons.hourglass_top;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Cảm ơn bạn đã mua sắm tại cửa hàng", style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}