import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:totalpay_checkout_sdk/totalpay_checkout_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:get/get.dart';

class TotalPayController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initiates a payment session and returns the redirect URL.
  Future<PaymentResponse?> initiatePayment({
    required String orderId,
    required double amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String referenceType,
    required String referenceId,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // 1. Create a pending payment record (customerId required by Firestore rules)
      final paymentRef = await _firestore.collection('payments').add({
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'referenceType': referenceType,
        'referenceId': referenceId,
        if (uid != null) 'customerId': uid,
        if (uid != null) 'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Build the payment request (with valid URLs and phone)
      final paymentRequest = PaymentRequest(
        merchantKey: TotalPaySdk().merchantKey,
        operation: 'purchase',
        methods: ['card'],
        // ✅ Use real HTTPS URLs (they don't need to exist, WebView will intercept)
        successUrl: 'https://example.com/payment-success',
        cancelUrl: 'https://example.com/payment-cancel',
        urlTarget: '_parent',
        hash: '', // auto‑generated
        order: Order(
          number: orderId,
          amount: amount.toStringAsFixed(2),
          currency: currency,
          description: 'Payment for $referenceType #$referenceId',
        ),
        customer: Customer(
          name: customerName,
          email: customerEmail,
        ),
        billingAddress: BillingAddress(
          country: 'AE',
          city: 'Dubai',
          state: 'Dubai',
          address: 'N/A',
          phone: '0000000000',      // ✅ Valid numeric string
        ),
      );

      final response = await PaymentService().initiatePayment(paymentRequest);
      return response;
    } catch (e) {
      print('Error initiating payment: $e');
      return null;
    }
  }

  /// Verifies the final payment status after the WebView closes.
  Future<bool> verifyPaymentStatus(String sessionId) async {
    try {
      final paymentQuery = await _firestore
          .collection('payments')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (paymentQuery.docs.isNotEmpty) {
        final paymentData = paymentQuery.docs.first.data();
        return paymentData['status'] == 'succeeded';
      }
      return false;
    } catch (e) {
      print('Error verifying payment status: $e');
      return false;
    }
  }

  /// Updates Firestore records after a successful payment.
  Future<void> updatePaymentStatus({
    required String referenceType,
    required String referenceId,
    required String status,
    required String transactionId,
  }) async {
    try {
      // Update the payment document
      final paymentQuery = await _firestore
          .collection('payments')
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();

      if (paymentQuery.docs.isNotEmpty) {
        await paymentQuery.docs.first.reference.update({
          'status': status,
          'gatewayTransactionId': transactionId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update the associated booking or order
      final targetCollection = referenceType == 'booking' ? 'bookings' : 'orders';
      await _firestore.collection(targetCollection).doc(referenceId).update({
        'paymentStatus': status == 'succeeded' ? 'paid' : 'failed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }
}