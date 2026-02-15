import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- Imports correct path based on your project structure ---
import 'package:shop_giay/features/cart/domain/cart_controller.dart'; 

import 'vnpay_web_view.dart'; 
import '../../orders/data/order_api.dart';
import 'package:flutter/foundation.dart'; // Thêm dòng này
import 'package:url_launcher/url_launcher.dart'; // Thêm dòng này
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Giả định OrderApi đã được cấu hình Dio bên trong hoặc là Singleton
  final OrderApi _orderApi = OrderApi();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _paymentMethod = 'cod'; // Default
  Map<String, String>? _selectedBank;
  bool _isProcessing = false;

  // Danh sách ngân hàng mẫu
  final List<Map<String, String>> _vnBanks = [
    {'name': 'BIDV', 'stk': '1234567890', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/BIDV.png', 'id': 'BIDV'},
    {'name': 'Techcombank', 'stk': '0987654321', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/TCB.png', 'id': 'TCB'},
    {'name': 'Vietinbank', 'stk': '1010101010', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/ICB.png', 'id': 'ICB'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- LOGIC: CHỌN NGÂN HÀNG ---
  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chọn ngân hàng thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            // Sử dụng Expanded nếu danh sách dài, ở đây dùng shrinkWrap
            ListView.builder(
              shrinkWrap: true,
              itemCount: _vnBanks.length,
              itemBuilder: (context, index) {
                final bank = _vnBanks[index];
                return ListTile(
                  leading: Image.network(bank['logo']!, width: 40, errorBuilder: (_,__,___) => const Icon(Icons.account_balance)),
                  title: Text(bank['name']!),
                  subtitle: Text("STK: ${bank['stk']}"),
                  onTap: () {
                    setState(() {
                      _selectedBank = bank;
                      _paymentMethod = 'bank';
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC: ĐẶT HÀNG ---
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartCtrl = context.read<CartController>();
    if (cartCtrl.items.isEmpty) {
      _showSnackBar("Giỏ hàng trống!", Colors.red);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Chuẩn bị dữ liệu gửi Backend
      // LƯU Ý: Backend Order Model của bạn chỉ chấp nhận enum ["cod", "vnpay"].
      // Nên nếu khách chọn 'bank' (thủ công), ta vẫn gửi là 'cod' (Pending) 
      // hoặc bạn phải sửa Backend thêm enum 'transfer'. Ở đây mình map về 'cod'.
      final String methodToSend = (_paymentMethod == 'bank') ? 'cod' : _paymentMethod;

      final orderData = {
        "items": cartCtrl.items.map((e) => {
          "productId": e.productId,
          "qty": e.quantity,
          "size": e.selectedSize,
          "price": e.price
        }).toList(),
        "total": cartCtrl.total,
        "paymentMethod": methodToSend,
        "shippingInfo": {
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "address": _addressController.text.trim(),
        },
      };

      // 2. Xử lý theo phương thức
      if (_paymentMethod == 'vnpay') {
        // 1. Gọi API lấy link
        final String? url = await _orderApi.createVnpayPayment(orderData);
        
        if (url == null || url.isEmpty) throw "Lỗi link thanh toán";
        if (!mounted) return;

        // --- BẮT ĐẦU ĐOẠN CODE MỚI ---
        if (kIsWeb) {
          // Nếu là WEB: Mở tab mới
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            _showWebPaymentDialog(); // Gọi popup thông báo
          }
        } else {
          // Nếu là MOBILE: Mở WebView trong App (như cũ)
          final bool? success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VnpayWebView(url: url)),
          );
          if (success == true) _handleSuccess("Thanh toán thành công!");
        }

      } else {
        // --- COD / BANK MANUAL FLOW ---
        await _orderApi.createOrder(orderData);
        _handleSuccess(_paymentMethod == 'bank' 
            ? "Đặt hàng thành công! Vui lòng chuyển khoản." 
            : "Đặt hàng thành công!");
      }

    } catch (e) {
      _showSnackBar("Lỗi: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleSuccess(String message) {
    final cartCtrl = context.read<CartController>();
    // Load lại cart để backend trả về mảng rỗng (sau khi đã xóa session cart)
    // Hoặc gọi hàm cartCtrl.clearLocalCart() nếu bạn có viết.
    cartCtrl.loadCart(); 
    
    _showSnackBar(message, Colors.green);
    
    // Điều hướng về Home và xóa các màn hình trước đó
    context.go('/'); 
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
// Hàm hiển thị thông báo riêng cho Web
  void _showWebPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Đang thanh toán..."),
        content: const Text("Cửa sổ thanh toán đã mở. Sau khi thanh toán xong, hãy bấm nút dưới đây."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSuccess("Đã ghi nhận đơn hàng!");
            },
            child: const Text("Tôi đã thanh toán xong"),
          )
        ],
      ),
    );
  }
  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final cartCtrl = context.watch<CartController>();
    final totalAmount = cartCtrl.total;

    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection("Người nhận hàng"),
              _inputField(_nameController, "Họ tên", Icons.person),
              _inputField(_phoneController, "Số điện thoại", Icons.phone, isPhone: true),
              _inputField(_addressController, "Địa chỉ chi tiết", Icons.location_on),

              const SizedBox(height: 20),
              _buildSection("Thông tin đơn hàng"),
              _buildOrderItems(cartCtrl),

              const SizedBox(height: 20),
              _buildSection("Phương thức thanh toán"),
              _payOption('cod', "Tiền mặt (COD)", Icons.local_shipping_outlined),
              _payOption('vnpay', "Cổng VNPay (Thẻ/QR)", Icons.qr_code_scanner),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Radio(
                  value: 'bank',
                  groupValue: _paymentMethod,
                  activeColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                       _paymentMethod = val.toString();
                       // Nếu chưa chọn ngân hàng thì hiện popup luôn
                       if(_selectedBank == null) _showBankSelection();
                    });
                  },
                ),
                title: const Text("Chuyển khoản Ngân hàng"),
                subtitle: Text(
                  _selectedBank != null 
                    ? "Đã chọn: ${_selectedBank!['name']}" 
                    : "Bấm để chọn ngân hàng",
                  style: TextStyle(color: _selectedBank != null ? Colors.blue : Colors.grey)
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _showBankSelection,
                ),
                onTap: () {
                  setState(() => _paymentMethod = 'bank');
                  _showBankSelection();
                },
              ),

              // Hiển thị thông tin chuyển khoản & QR nếu chọn Bank Manual
              if (_paymentMethod == 'bank' && _selectedBank != null)
                _buildBankCard(totalAmount),

              const SizedBox(height: 100), // Khoảng trống cho nút đặt hàng
            ],
          ),
        ),
      ),
      bottomSheet: _buildPayButton(totalAmount),
    );
  }

  // Widget hiển thị danh sách sản phẩm
  Widget _buildOrderItems(CartController cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ...cart.items.map((item) => ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.image, 
                width: 40, height: 40, fit: BoxFit.cover, 
                errorBuilder: (_,__,___) => const Icon(Icons.image)
              )
            ),
            title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text("Size: ${item.selectedSize} | x${item.quantity}"),
            trailing: Text("${(item.price * item.quantity).toStringAsFixed(0)}đ"),
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng cộng:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${cart.total.toStringAsFixed(0)}đ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị QR Code và thông tin chuyển khoản
  Widget _buildBankCard(double amount) {
    // Tạo link VietQR động
    String qrUrl = "https://api.vietqr.io/image/${_selectedBank!['id']}-${_selectedBank!['stk']}-compact2.jpg?amount=${amount.toInt()}&addInfo=ThanhToanDonHang";
    
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.network(_selectedBank!['logo']!, width: 40, errorBuilder: (_,__,___)=>const Icon(Icons.account_balance)),
                const SizedBox(width: 12),
                const Text("Thông tin thụ hưởng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _rowDetail("Ngân hàng:", _selectedBank!['name']!),
            _rowDetail("Số tài khoản:", _selectedBank!['stk']!),
            _rowDetail("Chủ tài khoản:", _selectedBank!['owner']!),
            _rowDetail("Số tiền:", "${amount.toStringAsFixed(0)}đ"),
            const SizedBox(height: 15),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Image.network(qrUrl, height: 180, errorBuilder: (_,__,___) => const Text("Lỗi tải mã QR")),
            ),
            const SizedBox(height: 8),
            const Text("Quét mã QR bằng ứng dụng ngân hàng", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPayButton(double total) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Colors.white, 
      border: Border(top: BorderSide(color: Colors.black12)),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, 
        minimumSize: const Size(double.infinity, 50), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      ),
      onPressed: _isProcessing ? null : () => _placeOrder(),
      child: _isProcessing 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
        : Text("XÁC NHẬN ĐẶT HÀNG (${total.toStringAsFixed(0)}đ)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );

  Widget _buildSection(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12), 
    child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))
  );
  
  Widget _inputField(TextEditingController c, String l, IconData i, {bool isPhone = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: l, 
        prefixIcon: Icon(i, size: 20), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập $l" : null,
    ),
  );

  Widget _payOption(String v, String t, IconData i) => RadioListTile(
    value: v, 
    groupValue: _paymentMethod, 
    title: Text(t), 
    secondary: Icon(i), 
    activeColor: Colors.black,
    contentPadding: EdgeInsets.zero,
    onChanged: (val) => setState(() { 
      _paymentMethod = val!; 
      if(val != 'bank') _selectedBank = null; 
    }),
  );
}