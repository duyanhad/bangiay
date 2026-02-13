import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VnpayPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  const VnpayPaymentScreen({super.key, required this.paymentUrl});

  @override
  State<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends State<VnpayPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) {
            // Kiểm tra link callback của Backend để đóng Webview
            if (request.url.contains('vnpay_return')) {
              _handleReturnUrl(request.url);
              return NavigationDecision.prevent; 
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleReturnUrl(String url) {
    final uri = Uri.parse(url);
    final responseCode = uri.queryParameters['vnp_ResponseCode'];

    // Trả kết quả về màn hình Checkout
    Navigator.of(context).pop(responseCode == '00'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán VNPay"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.black)),
        ],
      ),
    );
  }
}