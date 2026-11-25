// services/totalpay_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:totalpay_checkout_sdk/totalpay_checkout_sdk.dart';

class TotalPayService {
  static Future<void> init() async {
    // dotenv is loaded once in main(); avoid a second disk read on cold start.
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }
    TotalPaySdk().init(
      key: dotenv.env['TOTALPAY_MERCHANT_KEY']!,
      password: dotenv.env['TOTALPAY_MERCHANT_PASSWORD']!,
    );
  }
}