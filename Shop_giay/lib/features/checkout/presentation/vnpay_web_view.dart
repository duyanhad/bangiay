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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
         onNavigationRequest: (request) {
  if (request.url.contains('vnpay_return')) { // Backend của bạn phải trả về link có chứa từ này
    final uri = Uri.parse(request.url);
    final code = uri.queryParameters['vnp_ResponseCode'];
    
    // Đóng webview và trả kết quả true nếu code là '00'
    Navigator.pop(context, code == '00'); 
    return NavigationDecision.prevent;
  }
  return NavigationDecision.navigate;
},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cổng thanh toán VNPay")),
      body: WebViewWidget(controller: _controller),
    );
  }
}