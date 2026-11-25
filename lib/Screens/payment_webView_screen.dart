import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_colors.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String? cookieHeader;
  final Function(bool success) onPaymentComplete;

  const PaymentWebviewScreen({
    super.key,
    required this.checkoutUrl,
    this.cookieHeader,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    // Create and configure the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url?.contains('https://example.com/payment-success') == true) {
              widget.onPaymentComplete(true);
              if (mounted) Navigator.pop(context);
            } else if (url?.contains('https://example.com/payment-cancel') == true) {
              widget.onPaymentComplete(false);
              if (mounted) Navigator.pop(context);
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    // Set cookie in request headers if provided (no CookieManager needed)
    final headers = <String, String>{};
    if (widget.cookieHeader != null && widget.cookieHeader!.isNotEmpty) {
      headers['Cookie'] = widget.cookieHeader!;
    }

    await _controller.loadRequest(
      Uri.parse(widget.checkoutUrl),
      headers: headers,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        title: Text(
          'Secure Payment',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onPaymentComplete(false);
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}