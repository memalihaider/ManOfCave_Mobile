// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../models/notification_model.dart';
// import '../models/payment_model.dart';
// import '../models/payment_intent_model.dart';
// import 'auth_controller.dart';
// import 'notification_controller.dart';
//
// class PaymentController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthController _authController = Get.find<AuthController>();
//   final NotificationController _notificationController = Get.find<NotificationController>();
//
//   // Firebase Functions instance (automatically uses authenticated user)
//   final FirebaseFunctions _functions = FirebaseFunctions.instance;
//
//   final RxBool _isProcessing = false.obs;
//   final RxString _errorMessage = ''.obs;
//   final RxList<Payment> _paymentHistory = <Payment>[].obs;
//
//   bool get isProcessing => _isProcessing.value;
//   String get errorMessage => _errorMessage.value;
//   List<Payment> get paymentHistory => _paymentHistory;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadPaymentHistory();
//   }
//
//   Future<void> _loadPaymentHistory() async {
//     final userId = _authController.currentUser.value?.uid;
//     if (userId == null) return;
//
//     final querySnapshot = await _firestore
//         .collection('payments')
//         .where('userId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .limit(50)
//         .get();
//
//     _paymentHistory.assignAll(
//         querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList()
//     );
//   }
//
//   Future<Payment> createPaymentRecord({
//     required PaymentType type,
//     required String referenceId,
//     required double amount,
//     String? description,
//   }) async {
//     final userId = _authController.currentUser.value?.uid;
//     if (userId == null) throw Exception('User not authenticated');
//
//     final payment = Payment(
//       id: _firestore.collection('payments').doc().id,
//       userId: userId,
//       transactionId: _generateTransactionId(),
//       status: PaymentStatus.pending,
//       type: type,
//       referenceId: referenceId,
//       amount: amount,
//       currency: 'AED',
//       description: description,
//       createdAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//     );
//
//     await _firestore
//         .collection('payments')
//         .doc(payment.id)
//         .set(payment.toFirestore());
//
//     return payment;
//   }
//
//   Future<void> updatePaymentStatus({
//     required String paymentId,
//     required PaymentStatus status,
//     String? errorMessage,
//     Map<String, dynamic>? stripeData,
//   }) async {
//     try {
//       final updates = {
//         'status': status.toString().split('.').last,
//         'updatedAt': FieldValue.serverTimestamp(),
//         if (errorMessage != null) 'errorMessage': errorMessage,
//         if (stripeData != null) 'stripeData': stripeData,
//         if (status == PaymentStatus.succeeded) 'completedAt': FieldValue.serverTimestamp(),
//       };
//
//       await _firestore
//           .collection('payments')
//           .doc(paymentId)
//           .update(updates);
//
//       if (status == PaymentStatus.succeeded) {
//         _notificationController.showInAppNotification(
//           title: 'Payment Successful! 💳',
//           message: 'Your payment was successful.',
//           type: NotificationType.payment,
//           data: {'paymentId': paymentId},
//         );
//       } else if (status == PaymentStatus.failed) {
//         _notificationController.showInAppNotification(
//           title: 'Payment Failed ❌',
//           message: errorMessage ?? 'Payment failed. Please try again.',
//           type: NotificationType.payment,
//           data: {'paymentId': paymentId},
//         );
//       }
//     } catch (e) {
//       print('Error updating payment status: $e');
//     }
//   }
//
//   // 🔥 SECURE: Using Firebase Callable Function (no URL exposed)
//   Future<PaymentIntent?> createStripePaymentIntent({
//     required double amount,
//     required PaymentType type,
//     required String referenceId,
//   }) async {
//     try {
//       _isProcessing.value = true;
//       _errorMessage.value = '';
//
//       final payment = await createPaymentRecord(
//         type: type,
//         referenceId: referenceId,
//         amount: amount,
//       );
//
//       // Call the secure callable function
//       final HttpsCallableResult result = await _functions
//           .httpsCallable('createStripePaymentIntent')
//           .call({
//         'amount': amount,
//         'currency': 'AED',
//         'paymentId': payment.id,
//         'referenceId': referenceId,
//         'type': type.toString().split('.').last,
//       });
//
//       final data = result.data as Map<String, dynamic>;
//       return PaymentIntent.fromJson(data);
//
//     } catch (e) {
//       _errorMessage.value = 'Error: $e';
//       print('Stripe payment intent error: $e');
//       return null;
//     } finally {
//       _isProcessing.value = false;
//     }
//   }
//
//   String _generateTransactionId() {
//     return 'TXN_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 10000}';
//   }
//
//   void clearError() {
//     _errorMessage.value = '';
//   }
// }