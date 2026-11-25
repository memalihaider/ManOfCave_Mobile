// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:get/get.dart';
// import '../controlers/payment_controller.dart';
// import '../models/payment_model.dart';
//
// class StripePaymentWidget extends StatefulWidget {
//   final double amount;
//   final PaymentType paymentType;
//   final String referenceId;
//   final Function(bool success, String? paymentId) onPaymentComplete;
//
//   const StripePaymentWidget({
//     super.key,
//     required this.amount,
//     required this.paymentType,
//     required this.referenceId,
//     required this.onPaymentComplete,
//   });
//
//   @override
//   State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
// }
//
// class _StripePaymentWidgetState extends State<StripePaymentWidget> {
//   final PaymentController _paymentController = Get.find<PaymentController>();
//   bool _isInitializing = true;
//   String? _paymentIntentClientSecret;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeStripe();
//   }
//
//   Future<void> _initializeStripe() async {
//     try {
//       // Set Stripe publishable key
//       Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
//
//       // Create payment intent
//       final paymentIntent = await _paymentController.createStripePaymentIntent(
//         amount: widget.amount,
//         type: widget.paymentType,
//         referenceId: widget.referenceId,
//       );
//
//       if (paymentIntent != null) {
//         _paymentIntentClientSecret = paymentIntent.clientSecret;
//
//         // Initialize payment sheet
//         await Stripe.instance.initPaymentSheet(
//           paymentSheetParameters: SetupPaymentSheetParameters(
//             paymentIntentClientSecret: paymentIntent.clientSecret,
//             merchantDisplayName: 'Jam Beauty Lounge',
//             style: ThemeMode.light,
//             appearance: PaymentSheetAppearance(
//               colors: PaymentSheetAppearanceColors(
//                 primary: const Color(0xFFC5A059),
//               ),
//             ),
//           ),
//         );
//
//         setState(() => _isInitializing = false);
//
//         // Present payment sheet immediately
//         await _presentPaymentSheet();
//       } else {
//         widget.onPaymentComplete(false, null);
//       }
//     } catch (e) {
//       print('Error initializing Stripe: $e');
//       widget.onPaymentComplete(false, null);
//     }
//   }
//
//   Future<void> _presentPaymentSheet() async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//
//       // Payment successful
//       widget.onPaymentComplete(true, _paymentIntentClientSecret);
//
//     } catch (e) {
//       print('Payment failed: $e');
//
//       if (e is StripeException) {
//         if (e.error.localizedMessage!.contains('canceled')) {
//           // User cancelled
//           Get.back();
//         } else {
//           widget.onPaymentComplete(false, null);
//         }
//       } else {
//         widget.onPaymentComplete(false, null);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isInitializing) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const CircularProgressIndicator(
//                 color: Color(0xFFC5A059),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Loading payment...',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return const SizedBox.shrink();
//   }
// }