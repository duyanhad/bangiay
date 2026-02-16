import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Để mở link Web

// --- 1. CART (GIỎ HÀNG) ---
// Đảm bảo đường dẫn import đúng với cấu trúc dự án của bạn
import '../../cart/domain/cart_controller.dart'; 
import '../../cart/data/models/cart_item_model.dart'; 
import 'package:go_router/go_router.dart';
// --- 2. ORDER (ĐƠN HÀNG) ---
import '../../orders/data/order_api.dart';

// --- 3. THANH TOÁN ---
// File này dùng để hiển thị Webview trên Mobile (Android/iOS)
import 'vnpay_web_view.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // API xử lý đơn hàng
  final OrderApi _orderApi = OrderApi();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _paymentMethod = 'cod'; // Mặc định là COD
  Map<String, String>? _selectedBank;
  bool _isProcessing = false; // Trạng thái đang xử lý (loading)

  // Danh sách ngân hàng mẫu (Demo QR Code)
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

  // --- LOGIC 1: HIỂN THỊ CHỌN NGÂN HÀNG ---
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

  // --- LOGIC 2: XỬ LÝ ĐẶT HÀNG (CORE) ---
  Future<void> _placeOrder() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) return;

    // 2. Kiểm tra giỏ hàng
    final cartCtrl = context.read<CartController>();
    if (cartCtrl.items.isEmpty) {
      _showSnackBar("Giỏ hàng trống!", Colors.red);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Chuẩn bị dữ liệu gửi lên Server
      // Nếu chọn Bank thì gửi lên server là 'cod' để server tạo đơn bình thường, việc chuyển khoản xử lý ở Client
      final String methodToSend = (_paymentMethod == 'bank') ? 'cod' : _paymentMethod;

      final orderData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "items": cartCtrl.items.map((e) => {
          "productId": e.productId,
          "qty": e.quantity,
          "size": e.size, 
          "price": e.price
        }).toList(),
        "total": cartCtrl.total,
        "paymentMethod": methodToSend,
        "note": _paymentMethod == 'bank' ? "CK ngân hàng: ${_selectedBank?['name']}" : "",
      };

      // 3. Xử lý theo phương thức thanh toán
      if (_paymentMethod == 'vnpay') {
        // --- CỔNG VNPAY ---
        final String? url = await _orderApi.createVnpayPayment(orderData);
        if (url == null || url.isEmpty) throw "Lỗi: Không lấy được link thanh toán VNPay";
        
        if (kIsWeb) {
          // Xử lý cho Web: Mở tab mới
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            _showWebPaymentDialog(); // Hiện popup chờ xác nhận
          }
        } else {
          // Xử lý cho Mobile: Mở WebView trong app
          if (!mounted) return;
          final bool? success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VnpayWebView(url: url)),
          );
          if (success == true) _handleSuccess("Thanh toán thành công!");
        }
      } else {
        // --- COD HOẶC BANK TRANSFER ---
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

  // --- LOGIC 3: XỬ LÝ KHI THÀNH CÔNG ---
  void _handleSuccess(String message) {
    if (!mounted) return;
    
    final cartCtrl = context.read<CartController>();
    
    // Copy dữ liệu để hiển thị trang Success
    final List<CartItem> itemsBought = List.from(cartCtrl.items);
    final double totalPaid = cartCtrl.total;
    final String method = _paymentMethod;

    // Xóa giỏ hàng
    cartCtrl.loadCart(); // Hàm này load lại (thường sẽ reset nếu API trả về rỗng) hoặc dùng hàm clearCart() nếu bạn có
    
    // Chuyển trang và xóa sạch lịch sử navigation trước đó
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(
          totalAmount: totalPaid,
          paymentMethod: method,
          orderItems: itemsBought,
        ),
      ),
      (route) => false, 
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // Popup xác nhận cho Web sau khi mở tab VNPay
  void _showWebPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Đang thanh toán..."),
        content: const Text("Cửa sổ thanh toán đã mở tab mới.\nSau khi thanh toán xong, hãy bấm xác nhận."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSuccess("Đã ghi nhận thanh toán!");
            },
            child: const Text("Tôi đã thanh toán xong"),
          )
        ],
      ),
    );
  }

  // --- UI PART ---
  @override
  Widget build(BuildContext context) {
    // Dùng watch để UI tự cập nhật khi giỏ hàng thay đổi
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

              // Nếu chọn bank thì hiện QR
              if (_paymentMethod == 'bank' && _selectedBank != null)
                _buildBankCard(totalAmount),

              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
      bottomSheet: _buildPayButton(totalAmount),
    );
  }

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
            subtitle: Text("Size: ${item.size} | x${item.quantity}"),
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

  Widget _buildBankCard(double amount) {
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

// --- MÀN HÌNH THÀNH CÔNG (NẰM CÙNG FILE ĐỂ TIỆN GỌI) ---
class OrderSuccessScreen extends StatelessWidget {
  final double totalAmount;
  final String paymentMethod;
  final List<CartItem> orderItems;

  const OrderSuccessScreen({
    super.key,
    required this.totalAmount,
    required this.paymentMethod,
    required this.orderItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "ĐẶT HÀNG THÀNH CÔNG!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              Text(
                "Tổng thanh toán: ${totalAmount.toStringAsFixed(0)}đ",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Hình thức: ${paymentMethod == 'cod' ? 'Tiền mặt' : paymentMethod == 'vnpay' ? 'VNPay' : 'Chuyển khoản'}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
         onPressed: () {
  // Lệnh này sẽ đưa người dùng về trang chủ (path '/')
  // GoRouter sẽ tự động hiển thị AppShell và thanh menu cho bạn
  context.go('/'); 
},
                  child: const Text("Tiếp tục mua sắm", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}