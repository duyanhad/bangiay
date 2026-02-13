import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../cart/domain/cart_controller.dart';
import '../../orders/data/order_api.dart';
import 'vnpay_web_view.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderApi _orderApi = OrderApi();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _paymentMethod = 'cod'; 
  Map<String, String>? _selectedBank;
  bool _isProcessing = false;

  final List<Map<String, String>> _vnBanks = [
    {'name': 'BIDV', 'stk': '1234567890', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/BIDV.png', 'id': 'BIDV'},
    {'name': 'Techcombank', 'stk': '0987654321', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/TCB.png', 'id': 'TCB'},
    {'name': 'Vietinbank', 'stk': '1010101010', 'owner': 'NGUYEN VAN A', 'logo': 'https://api.vietqr.io/img/ICB.png', 'id': 'ICB'},
  ];

  void _showBankSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chọn ngân hàng thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ..._vnBanks.map((bank) => ListTile(
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
            )),
          ],
        ),
      ),
    );
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    final cartCtrl = context.read<CartController>();
    if (cartCtrl.items.isEmpty) return; 

    setState(() => _isProcessing = true);

    try {
      final orderData = {
        "items": cartCtrl.items.map((e) => {
          "productId": e.productId, 
          "qty": e.quantity,
          "size": e.selectedSize,
        }).toList(),
        "total": cartCtrl.total,    
        "paymentMethod": _paymentMethod,
        "shippingInfo": {
          "name": _nameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "address": _addressController.text.trim(),
        },
      };

      if (_paymentMethod == 'vnpay') {
        final String? url = await _orderApi.createVnpayPayment(orderData);
        if (url == null || url.isEmpty) throw "Không tạo được link VNPay";

        if (!mounted) return;
        final bool? success = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VnpayWebView(url: url)),
        );

        if (success == true) _handleSuccess("Thanh toán thành công!");
      } else {
        await _orderApi.createOrder(orderData);
        _handleSuccess("Đặt hàng thành công!");
      }
    } catch (e) {
      _showSnackBar("Lỗi: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleSuccess(String message) {
    context.read<CartController>().loadCart(); 
    _showSnackBar(message, Colors.green);
    context.go('/'); 
  }

  // Đã thêm hàm _showSnackBar ở đây
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCtrl = context.watch<CartController>();
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: Form(
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
            _payOption('vnpay', "Cổng VNPay (Xử lý tự động)", Icons.qr_code_scanner),
            
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
              title: const Text("Chuyển khoản Ngân hàng (Manual)"),
              subtitle: Text(_selectedBank != null ? "Đã chọn: ${_selectedBank!['name']}" : "Bấm để chọn ngân hàng Việt Nam"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showBankSelection,
            ),

            if (_paymentMethod == 'bank' && _selectedBank != null)
              _buildBankCard(cartCtrl.total),

            const SizedBox(height: 120), 
          ],
        ),
      ),
      bottomSheet: _buildPayButton(cartCtrl.total),
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
              child: Image.network(item.image, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image))
            ),
            title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text("Số lượng: ${item.quantity}"),
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
                const Text("ThôngInfo thụ hưởng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            _rowDetail("Ngân hàng:", _selectedBank!['name']!),
            _rowDetail("Số tài khoản:", _selectedBank!['stk']!),
            _rowDetail("Số tiền:", "${amount.toStringAsFixed(0)}đ"),
            const SizedBox(height: 15),
            Image.network(qrUrl, height: 180),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]),
  );

  Widget _buildPayButton(double total) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: _isProcessing ? null : _placeOrder,
      child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildSection(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)));
  
  Widget _inputField(TextEditingController c, String l, IconData i, {bool isPhone = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập $l" : null,
    ),
  );

  Widget _payOption(String v, String t, IconData i) => RadioListTile(
    value: v, groupValue: _paymentMethod, 
    title: Text(t), secondary: Icon(i), 
    onChanged: (val) => setState(() { _paymentMethod = val!; if(val != 'bank') _selectedBank = null; }),
  );
}