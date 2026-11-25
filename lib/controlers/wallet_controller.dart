import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/wallets_model.dart';
import '../utils/safe_firestore.dart';

/// Read-only e-wallet access aligned with the portal.
/// Source of truth: `wallets/{customerId}.balance` (AED).
/// Does not write wallets, loyalty points, or ledger docs.
class WalletController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rxn<CustomerWallet> customerWallet = Rxn<CustomerWallet>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  double get balanceAed => (customerWallet.value?.balance ?? 0).toDouble();

  String get formattedBalance {
    final value = balanceAed;
    return 'AED ${value.toStringAsFixed(2)}';
  }

  @override
  void onInit() {
    super.onInit();
    // Clear cache on logout; load on demand (profile/checkout) or after login frame.
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        customerWallet.value = null;
        return;
      }
      // Defer so splash/login stay responsive when Firestore is slow.
      Future.microtask(() => loadWallet(user.uid));
    });
  }

  Future<void> loadWallet(String customerId) async {
    if (customerId.isEmpty) return;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final direct = await SafeFirestore.getDoc(
        _firestore.collection('wallets').doc(customerId),
      );
      if (direct.exists) {
        customerWallet.value = CustomerWallet.fromFirestore(direct);
        return;
      }

      final linked = await SafeFirestore.getQuery(
        _firestore
            .collection('wallets')
            .where('customerId', isEqualTo: customerId)
            .limit(1),
      );

      if (linked.docs.isNotEmpty) {
        customerWallet.value = CustomerWallet.fromFirestore(linked.docs.first);
      } else {
        customerWallet.value = CustomerWallet(
          id: customerId,
          customerId: customerId,
          balance: 0,
          totalPointsEarned: 0,
          totalPointsRedeemed: 0,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error loading wallet: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) await loadWallet(uid);
  }
}
