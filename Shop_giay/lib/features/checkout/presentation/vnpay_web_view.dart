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

  static const String _returnPath = '/api/v1/orders/vnpay-return';

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
    _checkPaymentStatus(url);
  }

  bool _checkPaymentStatus(String url) {
    if (_isCompleted) return true;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final isReturnUrl = uri.path.contains(_returnPath);
    if (!isReturnUrl) return false;

    final code = uri.queryParameters['vnp_ResponseCode'];
    _finish(code == '00');
    return true;
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
      body: WebViewWidget(controller: _controller),
    );
  }
}