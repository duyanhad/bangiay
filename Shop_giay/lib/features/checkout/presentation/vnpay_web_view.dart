import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VnpayWebView extends StatefulWidget {
  final String url;
  const VnpayWebView({super.key, required this.url});

  @override
  State<VnpayWebView> createState() => _VnpayWebViewState();
}

class _VnpayWebViewState extends State<VnpayWebView> {
  late final WebViewController _controller;
  Timer? _timer;
  bool _isCompleted = false;
  
  // Biến này để hiện link lên màn hình cho bạn xem
  String _currentUrl = "Đang khởi tạo..."; 

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => _updateUrlAndCheck(url),
          onPageFinished: (url) => _updateUrlAndCheck(url),
          onNavigationRequest: (request) {
            if (_checkPaymentStatus(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Timer quét mỗi 0.5s
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_isCompleted) {
        timer.cancel();
        return;
      }
      final url = await _controller.currentUrl();
      if (url != null) {
        _updateUrlAndCheck(url);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateUrlAndCheck(String url) {
    // Cập nhật link lên màn hình để debug
    if (mounted && _currentUrl != url) {
      setState(() {
        _currentUrl = url;
      });
    }
    _checkPaymentStatus(url);
  }

  bool _checkPaymentStatus(String url) {
    if (_isCompleted) return true;

    // Kiểm tra nếu URL chứa vnp_ResponseCode=00 hoặc vnpay_return (thanh toán thành công)
    if (url.contains('vnp_ResponseCode=00') || url.contains('vnpay_return')) {
      _finish(true);
      return true;
    }
    
    return false;
  }

  void _finish(bool isSuccess) {
    if (_isCompleted) return;
    _isCompleted = true;
    _timer?.cancel();
    
    if (mounted) {
      // ✅ Trả lại kết quả cho CheckoutScreen
      Navigator.pop(context, isSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán VNPAY")),
      body: Stack(
        children: [
          // 1. WebView
          WebViewWidget(controller: _controller),

          // 2. KHUNG HIỂN THỊ LINK DEBUG (MÀU ĐỎ)
          Positioned(
            bottom: 0, 
            left: 0, 
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🔴 CHẾ ĐỘ DEBUG: Link hiện tại:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_currentUrl, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _finish(true),
                    child: const Text("Bấm vào đây để GIẢ LẬP THÀNH CÔNG"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}