// Loyalty points system removed (aligned with portal).
// This class remains only as a compatibility shim so existing Get.find calls
// resolve. Wallet AED balance is owned by [WalletController].

import 'package:get/get.dart';

import '../models/loyaltyPoints_model.dart';
import '../models/wallets_model.dart';
import 'wallet_controller.dart';

@Deprecated('Loyalty removed — use WalletController')
class LoyaltyController extends GetxController {
  WalletController get _wallet {
    if (Get.isRegistered<WalletController>()) {
      return Get.find<WalletController>();
    }
    return Get.put(WalletController(), permanent: true);
  }

  final Rx<LoyaltyConfig?> _loyaltyConfig = Rx<LoyaltyConfig?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxList<dynamic> _pendingRewards = <dynamic>[].obs;
  final RxBool _showRewardsDialog = false.obs;

  LoyaltyConfig? get loyaltyConfig => null;
  CustomerWallet? get customerWallet => _wallet.customerWallet.value;
  List<dynamic> get transactions => const [];
  bool get isLoading => _wallet.isLoading.value || _isLoading.value;
  String get errorMessage => _wallet.errorMessage.value;
  int get availablePoints => 0;
  List<dynamic> get pendingRewards => _pendingRewards;
  bool get showRewardsDialog => false;
  bool get hasPendingRewards => false;
  double get monetaryValue => _wallet.balanceAed;
  String get formattedMonetaryValue => _wallet.formattedBalance;
  bool get canRedeem => false;
  int get pointsNeededForRedemption => 0;
  double get redemptionProgress => 0;

  @override
  void onInit() {
    super.onInit();
    // No loyalty init — wallet controller handles auth-driven loads.
  }

  Future<void> initializeLoyaltySystem() async {}

  Future<void> loadLoyaltyConfig() async {
    _loyaltyConfig.value = null;
  }

  int calculatePointsForAmount(double amount) => 0;

  Future<bool> redeemPointsForOrder({
    required String customerId,
    required int points,
    required double orderAmount,
    required String orderId,
    required int itemCount,
    required double pointsDiscount,
    String? branchName,
    Map<String, dynamic>? metadata,
  }) async {
    return false;
  }

  Future<bool> redeemPointsForBookingPayment({
    required String customerId,
    required int points,
    required double bookingAmount,
    required String bookingId,
    required String serviceName,
    required double pointsDiscount,
    String? bookingType,
    String? branchName,
    Map<String, dynamic>? metadata,
  }) async {
    return false;
  }

  Future<void> awardRegistrationBonus(String customerId) async {}

  Future<void> awardBirthdayBonus({
    required String customerId,
    required String customerName,
    String? branchId,
    String? branchName,
  }) async {}

  Future<void> awardProductPurchasePoints({
    required String customerId,
    required String purchaseId,
    required double amount,
    String? productName,
    String? branchId,
    String? branchName,
    Map<String, dynamic>? metadata,
  }) async {}

  Future<void> awardServiceBookingPoints({
    required String customerId,
    required String bookingId,
    required double amount,
    String? serviceName,
    String? branchId,
    String? branchName,
    Map<String, dynamic>? metadata,
  }) async {}

  Future<void> awardFeedbackPoints({
    required String customerId,
    required String feedbackId,
    required int points,
    String? branchName,
  }) async {}

  Future<void> loadCustomerWallet(String customerId) async {
    await _wallet.loadWallet(customerId);
  }

  Future<void> loadTransactions(String customerId, {int limit = 20}) async {}

  Future<void> checkAndExpirePoints(String customerId) async {}

  Future<void> refreshWalletAfterPayment(String customerId) async {
    await _wallet.loadWallet(customerId);
  }

  Future<void> checkPendingRewardsManually() async {}

  Future<void> checkAndShowRewards() async {}

  Future<void> showRewardsConfirmationDialog() async {}

  void clearCustomerData() {
    _wallet.customerWallet.value = null;
  }

  void hideRewardsDialog() {
    _showRewardsDialog.value = false;
  }
}
