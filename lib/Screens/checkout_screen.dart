// screens/checkout_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:man_of_cave/Screens/payment_webView_screen.dart';
import 'package:man_of_cave/Screens/profile_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/cart_controller.dart';
import '../controlers/customer_controller.dart';
import '../controlers/loyalty_points_controller.dart';
import '../controlers/order_controller.dart';
import '../controlers/payment_controller.dart';
import '../controlers/product_controller.dart';
import '../controlers/promo_code_controller.dart';
import '../controlers/referral_controller.dart';
import '../controlers/branches_controller.dart';
import '../controlers/totalpay_controller.dart';
import '../models/branch_model.dart';
import '../models/order_model.dart';
import '../models/promo_code_model.dart';
import '../models/payment_model.dart';
import '../widgets/booking_summary.dart';
import '../widgets/payment_option.dart';
import '../widgets/stripe_payment_card.dart';
import 'customer_shell.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Controllers
  final CartController cartController = Get.find<CartController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final LoyaltyController loyaltyController = Get.find<LoyaltyController>();
  final ProductController productController = Get.find<ProductController>();
  final TotalPayController _totalPayController = Get.find<TotalPayController>();
  final PromoCodeController promoCodeController = Get.find<PromoCodeController>();
  // final ReferralController referralController = Get.find<ReferralController>();
  final BranchController branchController = Get.find<BranchController>();
  // final PaymentController paymentController = Get.find<PaymentController>();
  late final OrderController orderController;

  // Form controllers for all users
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orderNotesController = TextEditingController();
  final _expectedPickupController = TextEditingController();

  // Pickup branch selection
  final Rx<Branch?> _selectedBranch = Rx<Branch?>(null);
  final RxList<Branch> _availableBranches = <Branch>[].obs;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Promo code related state
  final TextEditingController _promoController = TextEditingController();
  final Rx<PromoCodeModel?> _appliedPromo = Rx<PromoCodeModel?>(null);
  final RxBool _isApplyingPromo = false.obs;
  final RxString _promoMessage = ''.obs;
  final RxBool _promoSuccess = false.obs;
  double _promoDiscount = 0.0;

  // Referral code related state
  final TextEditingController _referralCodeController = TextEditingController();
  final Rx<String?> _appliedReferralCode = Rx<String?>(null);
  final RxBool _isApplyingReferral = false.obs;
  final RxString _referralMessage = ''.obs;
  final RxBool _referralSuccess = false.obs;
  double _referralDiscount = 0.0;

  // Track which discount is applied (only one at a time)
  final RxString _activeDiscountType = RxString('none'); // 'promo', 'referral', 'points'

  // Payment State
  final RxString _selectedPaymentMethod = 'cash'.obs; // Default to cash for zero amount
  final RxBool _showPointsInput = false.obs;
  final RxBool _isProcessing = false.obs;

  // Loyalty Points State (only for authenticated users)
  int availablePoints = 0;
  int pointsToUse = 0;
  double pointsValue = 0.0;
  double pointsDiscount = 0.0;
  double remainingBalance = 0.0;
  int maxPointsToUse = 0;
  double totalAmount = 0.0;

  // Base price (without any discounts)
  double get basePrice => cartController.total;

  // Price after active discount (promo or referral)
  double get priceAfterDiscount {
    if (_activeDiscountType.value == 'promo' && _promoDiscount > 0) {
      return basePrice - _promoDiscount;
    } else if (_activeDiscountType.value == 'referral' && _referralDiscount > 0) {
      return basePrice - _referralDiscount;
    }
    return basePrice;
  }

  // Final price after all applicable discounts
  double get finalPrice {
    double price = priceAfterDiscount;
    // Only apply points discount if wallet payment selected AND no other discount is active
    if (_selectedPaymentMethod.value == 'wallet' &&
        _activeDiscountType.value != 'points' &&
        pointsDiscount > 0) {
      price = price - pointsDiscount;
    }
    return price < 0 ? 0 : price;
  }

  // Check if user is authenticated
  bool get isAuthenticated => customerController.isAuthenticated;
  bool get hasPickupBranch => _selectedBranch.value != null;

  @override
  void initState() {
    super.initState();
    orderController = Get.find<OrderController>();
    _prefillCustomerDetails();
    _initializePoints();
    _loadAvailableBranches();
    _expectedPickupDate = null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orderNotesController.dispose();
    _expectedPickupController.dispose();
    _promoController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _prefillCustomerDetails() {
    final customer = customerController.currentCustomer;
    if (customer != null) {
      _fullNameController.text = customer.name;
      _emailController.text = customer.email;
      _phoneController.text = customer.phone;
    }
  }

  Future<void> _loadAvailableBranches() async {
    final allBranches = branchController.branches.where((b) => b.isActive).toList();
    _availableBranches.assignAll(allBranches);
    if (allBranches.isNotEmpty && _selectedBranch.value == null) {
      _selectedBranch.value = allBranches.first;
    }
  }

  void _initializePoints() {
    if (isAuthenticated) {
      availablePoints = loyaltyController.availablePoints;
      pointsValue = loyaltyController.loyaltyConfig?.redemptionRate ?? 0.03;
    } else {
      availablePoints = 0;
      pointsValue = 0.03;
    }
    totalAmount = cartController.total;
    maxPointsToUse = _calculateMaxPoints(availablePoints, priceAfterDiscount);
    pointsToUse = maxPointsToUse;
    _updatePointCalculations();
  }

  void _updateMaxPoints() {
    maxPointsToUse = _calculateMaxPoints(availablePoints, priceAfterDiscount);
  }

  void _updatePointCalculations() {
    pointsDiscount = pointsToUse * pointsValue;
    if (pointsDiscount > priceAfterDiscount) {
      pointsDiscount = priceAfterDiscount;
      pointsToUse = (priceAfterDiscount / pointsValue).floor();
    }
    if (mounted) setState(() {});
  }

  void _onPointsChanged(int newPoints) {
    setState(() {
      pointsToUse = newPoints;
      _updatePointCalculations();
    });
  }

  int _calculateMaxPoints(int availablePoints, double price) {
    if (!isAuthenticated || loyaltyController.loyaltyConfig == null) return 0;
    final redemptionRate = loyaltyController.loyaltyConfig!.redemptionRate;
    final maxPointsByAmount = (price / redemptionRate).ceil();
    final minimumPoints = loyaltyController.loyaltyConfig!.minimumPoints;
    if (availablePoints < minimumPoints) return 0;
    return availablePoints < maxPointsByAmount ? availablePoints : maxPointsByAmount;
  }

  // Clear all discounts
  void _clearAllDiscounts() {
    // Clear promo
    _appliedPromo.value = null;
    _promoDiscount = 0.0;
    _promoController.clear();
    _promoMessage.value = '';
    _promoSuccess.value = false;

    // Clear referral
    _appliedReferralCode.value = null;
    _referralDiscount = 0.0;
    _referralCodeController.clear();
    _referralMessage.value = '';
    _referralSuccess.value = false;

    // Clear points selection if it's active
    if (_activeDiscountType.value == 'points') {
      pointsToUse = 0;
      pointsDiscount = 0.0;
      _updatePointCalculations();
    }

    _activeDiscountType.value = 'none';
  }

  // ============================================================
  // 🔥 PROMO CODE METHODS
  // ============================================================

  Future<void> _applyPromoCode() async {
    if (_promoController.text.isEmpty) {
      _promoMessage.value = 'Please enter a promo code';
      _promoSuccess.value = false;
      return;
    }

    _isApplyingPromo.value = true;
    _promoMessage.value = '';
    _promoSuccess.value = false;

    try {
      String? branchId;
      if (_selectedBranch.value != null) {
        branchId = _selectedBranch.value!.id;
      }

      final result = await promoCodeController.validatePromoCode(
        code: _promoController.text.toUpperCase().trim(),
        branchId: branchId ?? '',
        amount: basePrice,
      );

      if (result['valid']) {
        final promo = result['promo'] as PromoCodeModel;
        final discount = result['discount'] as double;

        setState(() {
          // Clear any existing discount first
          _clearAllDiscounts();

          _appliedPromo.value = promo;
          _promoDiscount = discount;
          _activeDiscountType.value = 'promo';
          _promoMessage.value = 'Promo code applied successfully! You saved ${discount.toStringAsFixed(2)} ${AppStrings.appCurreny}';
          _promoSuccess.value = true;
        });

        _updateMaxPoints();
        if (pointsToUse > maxPointsToUse) pointsToUse = maxPointsToUse;
        _updatePointCalculations();
      } else {
        _promoMessage.value = result['message'];
        _promoSuccess.value = false;
        _appliedPromo.value = null;
        _promoDiscount = 0.0;
      }
    } catch (e) {
      _promoMessage.value = 'Error applying promo code';
      _promoSuccess.value = false;
      _appliedPromo.value = null;
      _promoDiscount = 0.0;
    } finally {
      _isApplyingPromo.value = false;
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo.value = null;
      _promoDiscount = 0.0;
      _promoController.clear();
      _promoMessage.value = '';
      _promoSuccess.value = false;
      _activeDiscountType.value = 'none';
    });
    _updateMaxPoints();
    if (pointsToUse > maxPointsToUse) pointsToUse = maxPointsToUse;
    _updatePointCalculations();
  }

  // ============================================================
  // 🔥 REFERRAL CODE METHODS
  // ============================================================

  // Future<void> _applyReferralCode() async {
  //   if (!isAuthenticated) {
  //     _referralMessage.value = 'Please login to use referral code';
  //     _referralSuccess.value = false;
  //     return;
  //   }
  //
  //   if (_referralCodeController.text.isEmpty) {
  //     _referralMessage.value = 'Please enter a referral code';
  //     _referralSuccess.value = false;
  //     return;
  //   }
  //
  //   _isApplyingReferral.value = true;
  //   _referralMessage.value = '';
  //   _referralSuccess.value = false;
  //
  //   try {
  //     final currentUserId = customerController.currentCustomer?.uid ?? '';
  //     final isValid = await referralController.validateReferralCodeForCheckout(
  //       _referralCodeController.text.trim().toUpperCase(),
  //       currentUserId,
  //     );
  //
  //     if (isValid) {
  //       final discount = referralController.getFriendDiscount(basePrice);
  //
  //       setState(() {
  //         // Clear any existing discount first
  //         _clearAllDiscounts();
  //
  //         _appliedReferralCode.value = _referralCodeController.text.trim().toUpperCase();
  //         _referralDiscount = discount;
  //         _activeDiscountType.value = 'referral';
  //         _referralMessage.value = 'Referral code applied! You saved ${discount.toStringAsFixed(2)} ${AppStrings.appCurreny}';
  //         _referralSuccess.value = true;
  //       });
  //
  //       _updateMaxPoints();
  //       if (pointsToUse > maxPointsToUse) pointsToUse = maxPointsToUse;
  //       _updatePointCalculations();
  //     } else {
  //       _referralMessage.value = 'Invalid referral code';
  //       _referralSuccess.value = false;
  //       _appliedReferralCode.value = null;
  //       _referralDiscount = 0.0;
  //     }
  //   } catch (e) {
  //     _referralMessage.value = 'Error applying referral code';
  //     _referralSuccess.value = false;
  //     _appliedReferralCode.value = null;
  //     _referralDiscount = 0.0;
  //   } finally {
  //     _isApplyingReferral.value = false;
  //   }
  // }
  //
  // void _removeReferralCode() {
  //   setState(() {
  //     _appliedReferralCode.value = null;
  //     _referralDiscount = 0.0;
  //     _referralCodeController.clear();
  //     _referralMessage.value = '';
  //     _referralSuccess.value = false;
  //     _activeDiscountType.value = 'none';
  //   });
  //   _updateMaxPoints();
  //   if (pointsToUse > maxPointsToUse) pointsToUse = maxPointsToUse;
  //   _updatePointCalculations();
  // }

  // ============================================================
  // 🔥 STRIPE PAYMENT METHOD
  // ============================================================

  // Future<void> _processStripePayment(Order order) async {
  //   // ✅ Check if amount is valid for Stripe
  //   if (order.totalAmount <= 0) {
  //     print('❌ Cannot process Stripe payment for amount 0');
  //     await _showConfirmationDialog(order);
  //     return;
  //   }
  //
  //   try {
  //     final success = await Get.to(() => StripePaymentWidget(
  //       amount: order.totalAmount,
  //       paymentType: PaymentType.order,
  //       referenceId: order.id,
  //       onPaymentComplete: (completed, paymentIntentId) async {
  //         if (completed) {
  //           // Payment successful - update order status
  //           await orderController.updatePaymentStatus(order.id, 'paid');
  //           await _showConfirmationDialog(order);
  //           Get.snackbar(
  //             'Payment Successful',
  //             'Your payment has been completed.',
  //             backgroundColor: AppColors.primaryGold,
  //             colorText: Colors.white,
  //             snackPosition: SnackPosition.BOTTOM,
  //           );
  //         }
  //         return completed;
  //       },
  //     ));
  //
  //   } catch (e) {
  //     print('Stripe payment error: $e');
  //     Get.snackbar(
  //       'Payment Error',
  //       'An error occurred during payment. Please try again.',
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Obx(() {
            return Column(
              children: [
                _buildSummaryHeader(isLandscape),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceMedium16,
                      vertical: AppSizes.spaceMedium16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildCartSummary(isLandscape),
                          SizedBox(height: AppSizes.spaceLarge24),
                          _buildCustomerInfoSection(isLandscape),
                          SizedBox(height: AppSizes.spaceLarge24),
                          _buildPickupBranchSection(isLandscape),
                          SizedBox(height: AppSizes.spaceLarge24),
                          _buildPromoCodeSection(isLandscape),
                          // SizedBox(height: AppSizes.spaceLarge24),
                          // _buildReferralCodeSection(isLandscape),
                          SizedBox(height: AppSizes.spaceLarge24),
                          if (isAuthenticated) _buildWalletBalance(isLandscape),
                          if (isAuthenticated) SizedBox(height: AppSizes.spaceLarge24),
                          _buildPaymentMethod(isLandscape),
                          if (_showPointsInput.value &&
                              _selectedPaymentMethod.value == 'wallet' &&
                              isAuthenticated &&
                              _activeDiscountType.value != 'points')
                            _buildPointsInputSection(isLandscape),
                          SizedBox(height: AppSizes.spaceLarge24),
                          _buildOrderSummary(isLandscape),
                          SizedBox(height: AppSizes.height(80)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
        },
      ),
      bottomSheet: _buildPlaceOrderButton(),
    );
  }

  Widget _buildSummaryHeader(bool isLandscape) {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceSmall8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_checkout_outlined,
            size: AppSizes.icon(20),
            color: AppColors.primaryGold,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Text(
              'Review your order details before confirming',
              style: TextStyle(
                fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            '${cartController.itemCount} items',
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Items',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Edit Cart',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ...cartController.cartItems.take(3).map((cartItem) => Padding(
                padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppSizes.width(50),
                      height: AppSizes.height(50),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        image: cartItem.productImage.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(cartItem.productImage),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: Colors.grey[100],
                      ),
                      child: cartItem.productImage.isEmpty
                          ? Icon(
                        Icons.shopping_bag_outlined,
                        size: AppSizes.icon(24),
                        color: Colors.grey[400],
                      )
                          : null,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartItem.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: AppSizes.height(4)),
                          Row(
                            children: [
                              Text(
                                '${cartItem.price.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: AppSizes.width(8)),
                              Container(
                                width: AppSizes.width(1),
                                height: AppSizes.height(12),
                                color: Colors.grey[300],
                              ),
                              SizedBox(width: AppSizes.width(8)),
                              Text(
                                'Qty: ${cartItem.quantity}',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(cartItem.price * cartItem.quantity).toStringAsFixed(2)} ${AppStrings.appCurreny}',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              if (cartController.itemCount > 3)
                Padding(
                  padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
                  child: Text(
                    '+ ${cartController.itemCount - 3} more items',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            if (!isAuthenticated)
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: !isAuthenticated ? AppColors.primaryGold : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name *',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address *',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your email'
                    : (!GetUtils.isEmail(v.trim()) ? 'Please enter a valid email' : null),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number *',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your phone number'
                    : (v.trim().length < 10 ? 'Please enter a valid phone number' : null),
              ),
              if (!isAuthenticated)
                Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppSizes.icon(14),
                        color: Colors.blue[700],
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Expanded(
                        child: Text(
                          'You are ordering as a guest. Create an account to track orders and earn loyalty points!',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.height(4)),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
            ),
            contentPadding: AppSizes.paddingSymmetric(
              horizontal: AppSizes.spaceSmall8,
              vertical: AppSizes.spaceSmall8,
            ),
            prefixIcon: Icon(icon, size: AppSizes.icon(20), color: Colors.grey[500]),
          ),
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: enabled ? AppColors.primaryDark : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  DateTime? _expectedPickupDate;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectPickupDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryGold,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _expectedPickupDate) {
      setState(() {
        _expectedPickupDate = picked;
        _expectedPickupController.text = _formatDate(picked);
      });
    }
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isDatePicker = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.height(4)),
        GestureDetector(
          onTap: isDatePicker ? () => _selectPickupDate(context) : null,
          child: AbsorbPointer(
            absorbing: isDatePicker,
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              readOnly: isDatePicker,
              onTap: isDatePicker ? () => _selectPickupDate(context) : null,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
                ),
                contentPadding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.spaceSmall8,
                ),
                prefixIcon: Icon(icon, size: AppSizes.icon(20), color: Colors.grey[500]),
                suffixIcon: isDatePicker
                    ? IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    size: AppSizes.icon(18),
                    color: AppColors.primaryGold,
                  ),
                  onPressed: () => _selectPickupDate(context),
                )
                    : null,
              ),
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupBranchSection(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Branch',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Obx(() {
            if (_availableBranches.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: AppSizes.icon(40),
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: AppSizes.spaceSmall8),
                    Text(
                      'No branches available',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Branch>(
                  value: _selectedBranch.value,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(color: AppColors.primaryGold),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
                    ),
                    labelText: 'Select Pickup Branch *',
                    prefixIcon: Icon(Icons.store_outlined, color: AppColors.primaryGold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                    contentPadding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceSmall8,
                      vertical: AppSizes.spaceSmall8,
                    ),
                  ),
                  items: _availableBranches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (branch) {
                    _selectedBranch.value = branch;
                    if (_appliedPromo.value != null) {
                      _applyPromoCode();
                    }
                  },
                  validator: (value) => value == null ? 'Please select a pickup branch' : null,
                ),
                if (_selectedBranch.value != null) ...[
                  SizedBox(height: AppSizes.spaceSmall8),
                  Container(
                    padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: AppSizes.icon(16),
                              color: AppColors.primaryGold,
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Text(
                              'Address:',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedBranch.value!.fullAddress,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSizes.spaceSmall8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: AppSizes.icon(16),
                              color: AppColors.primaryGold,
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Text(
                              'Phone:',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedBranch.value!.phone,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceSmall8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: AppSizes.icon(16),
                              color: AppColors.primaryGold,
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Text(
                              'Hours:',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedBranch.value!.businessHours,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),
                  _buildAddressField(
                    controller: _expectedPickupController,
                    label: 'Expected Pickup Date (Optional)',
                    hint: 'YYYY-MM-DD',
                    icon: Icons.calendar_today_outlined,
                    isDatePicker: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      if (!_isValidDateFormat(value)) {
                        return 'Invalid date format. Use YYYY-MM-DD';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  bool _isValidDateFormat(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
          date.isBefore(DateTime.now().add(const Duration(days: 31)));
    } catch (e) {
      return false;
    }
  }

  Widget _buildPromoCodeSection(bool isLandscape) {
    // Don't show if another discount is already applied
    if (_activeDiscountType.value != 'none' && _activeDiscountType.value != 'promo') {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: _appliedPromo.value != null ? Colors.green : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      enabled: _appliedPromo.value == null && _activeDiscountType.value == 'none',
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        prefixIcon: Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.primaryGold,
                          size: AppSizes.icon(20),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        contentPadding: AppSizes.paddingSymmetric(
                          horizontal: AppSizes.spaceSmall8,
                          vertical: AppSizes.spaceSmall8,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Obx(() {
                    if (_appliedPromo.value != null) {
                      return IconButton(
                        onPressed: _removePromoCode,
                        icon: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: AppSizes.icon(20),
                        ),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _isApplyingPromo.value ? null : _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        padding: AppSizes.paddingSymmetric(
                          horizontal: AppSizes.spaceMedium16,
                          vertical: AppSizes.spaceMedium16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        ),
                      ),
                      child: _isApplyingPromo.value
                          ? SizedBox(
                        width: AppSizes.width(20),
                        height: AppSizes.height(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              Obx(() {
                if (_promoMessage.value.isEmpty) return const SizedBox();
                return Container(
                  margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: _promoSuccess.value
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    border: Border.all(
                      color: _promoSuccess.value ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _promoSuccess.value ? Icons.check_circle : Icons.error_outline,
                        size: AppSizes.icon(16),
                        color: _promoSuccess.value ? AppColors.success : AppColors.error,
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Expanded(
                        child: Text(
                          _promoMessage.value,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: _promoSuccess.value ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Obx(() {
                if (_appliedPromo.value == null) return const SizedBox();
                return Container(
                  margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: AppSizes.icon(16),
                            color: AppColors.primaryGold,
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promo Applied: ${_appliedPromo.value!.code}',
                                  style: TextStyle(
                                    fontSize: AppSizes.textSmall12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                                Text(
                                  _appliedPromo.value!.discountDisplay,
                                  style: TextStyle(
                                    fontSize: AppSizes.textSmall12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount:',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '-${_promoDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildReferralCodeSection(bool isLandscape) {
  //   // Only show for logged-in customers
  //   if (!isAuthenticated) {
  //     return const SizedBox();
  //   }
  //
  //   // Don't show if another discount is already applied
  //   if (_activeDiscountType.value != 'none' && _activeDiscountType.value != 'referral') {
  //     return const SizedBox();
  //   }
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Referral Code',
  //         style: TextStyle(
  //           fontSize: AppSizes.textMedium14,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.primaryDark,
  //         ),
  //       ),
  //       SizedBox(height: AppSizes.spaceSmall8),
  //       Container(
  //         padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
  //         decoration: BoxDecoration(
  //           color: AppColors.white,
  //           borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
  //           border: Border.all(
  //             color: _appliedReferralCode.value != null ? Colors.green : Colors.grey[200]!,
  //           ),
  //         ),
  //         child: Column(
  //           children: [
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: TextField(
  //                     controller: _referralCodeController,
  //                     enabled: _appliedReferralCode.value == null && _activeDiscountType.value == 'none',
  //                     decoration: InputDecoration(
  //                       hintText: 'Enter referral code',
  //                       prefixIcon: Icon(
  //                         Icons.card_giftcard_outlined,
  //                         color: AppColors.primaryGold,
  //                         size: AppSizes.icon(20),
  //                       ),
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                         borderSide: BorderSide(color: Colors.grey[300]!),
  //                       ),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                         borderSide: BorderSide(color: Colors.grey[300]!),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                         borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
  //                       ),
  //                       disabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                         borderSide: BorderSide(color: Colors.grey[200]!),
  //                       ),
  //                       contentPadding: AppSizes.paddingSymmetric(
  //                         horizontal: AppSizes.spaceSmall8,
  //                         vertical: AppSizes.spaceSmall8,
  //                       ),
  //                     ),
  //                     style: TextStyle(
  //                       fontSize: AppSizes.textMedium14,
  //                     ),
  //                     textCapitalization: TextCapitalization.characters,
  //                   ),
  //                 ),
  //                 SizedBox(width: AppSizes.spaceSmall8),
  //                 Obx(() {
  //                   if (_appliedReferralCode.value != null) {
  //                     return IconButton(
  //                       onPressed: _removeReferralCode,
  //                       icon: Icon(
  //                         Icons.close,
  //                         color: Colors.red,
  //                         size: AppSizes.icon(20),
  //                       ),
  //                     );
  //                   }
  //                   return ElevatedButton(
  //                     onPressed: _isApplyingReferral.value ? null : _applyReferralCode,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: AppColors.primaryGold,
  //                       foregroundColor: Colors.white,
  //                       padding: AppSizes.paddingSymmetric(
  //                         horizontal: AppSizes.spaceMedium16,
  //                         vertical: AppSizes.spaceMedium16,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                       ),
  //                     ),
  //                     child: _isApplyingReferral.value
  //                         ? SizedBox(
  //                       width: AppSizes.width(20),
  //                       height: AppSizes.height(20),
  //                       child: CircularProgressIndicator(
  //                         strokeWidth: 2,
  //                         color: Colors.white,
  //                       ),
  //                     )
  //                         : Text(
  //                       'Apply',
  //                       style: TextStyle(
  //                         fontSize: AppSizes.textMedium14,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   );
  //                 }),
  //               ],
  //             ),
  //             Obx(() {
  //               if (_referralMessage.value.isEmpty) return const SizedBox();
  //               return Container(
  //                 margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
  //                 padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
  //                 decoration: BoxDecoration(
  //                   color: _referralSuccess.value
  //                       ? AppColors.success.withOpacity(0.1)
  //                       : AppColors.error.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                   border: Border.all(
  //                     color: _referralSuccess.value ? AppColors.success : AppColors.error,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       _referralSuccess.value ? Icons.check_circle : Icons.error_outline,
  //                       size: AppSizes.icon(16),
  //                       color: _referralSuccess.value ? AppColors.success : AppColors.error,
  //                     ),
  //                     SizedBox(width: AppSizes.spaceSmall8),
  //                     Expanded(
  //                       child: Text(
  //                         _referralMessage.value,
  //                         style: TextStyle(
  //                           fontSize: AppSizes.textSmall12,
  //                           color: _referralSuccess.value ? AppColors.success : AppColors.error,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             }),
  //             Obx(() {
  //               if (_appliedReferralCode.value == null) return const SizedBox();
  //               return Container(
  //                 margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
  //                 padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primaryGold.withOpacity(0.05),
  //                   borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                   border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Icon(
  //                           Icons.card_giftcard,
  //                           size: AppSizes.icon(16),
  //                           color: AppColors.primaryGold,
  //                         ),
  //                         SizedBox(width: AppSizes.spaceSmall8),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 'Referral Code Applied: ${_appliedReferralCode.value}',
  //                                 style: TextStyle(
  //                                   fontSize: AppSizes.textSmall12,
  //                                   fontWeight: FontWeight.w600,
  //                                   color: AppColors.primaryGold,
  //                                 ),
  //                               ),
  //                               Text(
  //                                 'You saved ${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
  //                                 style: TextStyle(
  //                                   fontSize: AppSizes.textSmall12,
  //                                   color: Colors.grey[600],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     SizedBox(height: AppSizes.spaceSmall8),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           'Discount:',
  //                           style: TextStyle(
  //                             fontSize: AppSizes.textSmall12,
  //                             color: Colors.grey[600],
  //                           ),
  //                         ),
  //                         Text(
  //                           '-${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
  //                           style: TextStyle(
  //                             fontSize: AppSizes.textSmall12,
  //                             fontWeight: FontWeight.w600,
  //                             color: Colors.green,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             }),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildWalletBalance(bool isLandscape) {
    final monetaryValue = loyaltyController.monetaryValue;

    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(48),
            height: AppSizes.height(48),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius(24)),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: AppSizes.icon(24),
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(width: AppSizes.spaceMedium16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loyalty Wallet',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: AppSizes.height(4)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                size: AppSizes.icon(14),
                                color: AppColors.primaryGold,
                              ),
                              SizedBox(width: AppSizes.width(4)),
                              Text(
                                '$availablePoints Points',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.height(2)),
                          Text(
                            '≈ ${monetaryValue.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loyaltyController.canRedeem && _activeDiscountType.value != 'points')
                      Container(
                        padding: AppSizes.paddingSymmetric(
                          horizontal: AppSizes.spaceSmall8,
                          vertical: AppSizes.height(4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        ),
                        child: Text(
                          'Eligible to Redeem',
                          style: TextStyle(
                            fontSize: AppSizes.font(10),
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Column(
          children: [
            // ✅ Only show Stripe if finalPrice > 0
            if (finalPrice > 0)
              PaymentOptionCard(
                icon: Icons.credit_card,
                title: 'Pay with Card',
                subtitle: 'Visa, Mastercard, etc.',
                isSelected: _selectedPaymentMethod.value == 'card',
                onTap: () {
                  _selectedPaymentMethod.value = 'card';
                  _showPointsInput.value = false;
                  _onPointsChanged(0);
                  if (_activeDiscountType.value != 'none' && _activeDiscountType.value != 'points') {
                    _clearAllDiscounts();
                  }
                },
              ),

            if (finalPrice > 0) SizedBox(height: AppSizes.spaceSmall8),

            // Loyalty / points wallet payment removed — portal e-wallet is staff-managed.

            // Cash payment (always show)
            PaymentOptionCard(
              icon: Icons.money_outlined,
              title: 'Pay with Cash',
              subtitle: finalPrice > 0 ? 'Pay at the salon' : 'No payment needed',
              isSelected: _selectedPaymentMethod.value == 'cash',
              onTap: () {
                _selectedPaymentMethod.value = 'cash';
                _showPointsInput.value = false;
                _onPointsChanged(0);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsInputSection(bool isLandscape) {
    return Container(
      margin: AppSizes.paddingOnly(top: AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Use Loyalty Points',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Max: $maxPointsToUse points',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: pointsToUse.toDouble(),
                      min: 0,
                      max: maxPointsToUse.toDouble(),
                      divisions: maxPointsToUse > 0 ? maxPointsToUse : 1,
                      label: '$pointsToUse points',
                      onChanged: (value) => _onPointsChanged(value.toInt()),
                      activeColor: AppColors.primaryGold,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMedium16),
                  Container(
                    width: AppSizes.width(80),
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceSmall8,
                      vertical: AppSizes.height(6),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: TextEditingController(text: pointsToUse.toString()),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        final newValue = int.tryParse(value) ?? 0;
                        if (newValue <= maxPointsToUse && newValue >= 0) {
                          _onPointsChanged(newValue);
                        } else if (newValue > maxPointsToUse) {
                          _onPointsChanged(maxPointsToUse);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Container(
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Points to use:',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$pointsToUse points',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount value:',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${pointsDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining points:',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${availablePoints - pointsToUse} points',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(bool isLandscape) {
    final hasPromoDiscount = _promoDiscount > 0;
    final hasReferralDiscount = _referralDiscount > 0;
    final hasPointsDiscount = pointsDiscount > 0 && _selectedPaymentMethod.value == 'wallet' && _activeDiscountType.value != 'points';

    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${basePrice.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          // Promo Discount (if any)
          if (hasPromoDiscount) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.width(4)),
                    Text(
                      'Promo Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${_promoDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Referral Discount (if any)
          if (hasReferralDiscount) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.width(4)),
                    Text(
                      'Referral Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Price after discount (if any discount applied)
          if (hasPromoDiscount || hasReferralDiscount) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price after Discount',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '${priceAfterDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Points Discount (if any)
          if (hasPointsDiscount) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.width(4)),
                    Text(
                      'Loyalty Points Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${pointsDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: AppSizes.spaceSmall8),
          Divider(color: Colors.grey[300], height: 1),
          SizedBox(height: AppSizes.spaceSmall8),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '${finalPrice.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),

          // Payment note for card payment
          if (_selectedPaymentMethod.value == 'card')
            Padding(
              padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
              child: Text(
                'You will be redirected to secure payment page',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Payment notes for COD
          if (_selectedPaymentMethod.value == 'cod' && finalPrice > 0)
            Padding(
              padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
              child: Text(
                'Pay ${finalPrice.toStringAsFixed(2)} ${AppStrings.appCurreny} when you pick up your order',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_selectedPaymentMethod.value == 'wallet' && finalPrice == 0 && pointsToUse > 0)
            Padding(
              padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AppSizes.icon(14),
                    color: Colors.green,
                  ),
                  SizedBox(width: AppSizes.width(4)),
                  Text(
                    'Fully paid with loyalty points!',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Obx(() {
      final hasSufficientPoints = _selectedPaymentMethod.value != 'wallet' ||
          (pointsToUse > 0 && availablePoints >= pointsToUse);
      final hasPickupBranchSelected = _selectedBranch.value != null;

      return Container(
        padding: AppSizes.paddingSymmetric(
          horizontal: AppSizes.spaceMedium16,
          vertical: AppSizes.spaceMedium16,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPaymentMethod.value == 'wallet' && finalPrice > 0)
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                child: Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppSizes.icon(16),
                        color: Colors.orange[700],
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Expanded(
                        child: Text(
                          'Note: You need to pay ${finalPrice.toStringAsFixed(2)} ${AppStrings.appCurreny} when you pick up your order',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: AppSizes.height(52),
              child: ElevatedButton(
                onPressed: (!hasSufficientPoints || _isProcessing.value || !hasPickupBranchSelected)
                    ? null
                    : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isProcessing.value
                    ? SizedBox(
                  width: AppSizes.width(20),
                  height: AppSizes.height(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
                    : Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Missing Information',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
      return;
    }

    if (_selectedBranch.value == null) {
      Get.snackbar(
        'Missing Information',
        'Please select a pickup branch',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
      return;
    }

    // ✅ Prevent Stripe payment for zero amount
    if (_selectedPaymentMethod.value == 'card' && finalPrice <= 0) {
      Get.snackbar(
        'Invalid Payment Method',
        'Card payment requires amount > 0. Switching to Cash.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      _selectedPaymentMethod.value = 'cash';
      _isProcessing.value = false;
      return;
    }

    if (_selectedPaymentMethod.value == 'wallet' && pointsToUse > 0) {
      if (!isAuthenticated) {
        Get.snackbar('Error', 'Please login to use wallet');
        return;
      }
      if (availablePoints < pointsToUse) {
        Get.snackbar('Error', 'Insufficient points in your wallet');
        return;
      }
    }

    _isProcessing.value = true;

    try {
      final customerId = isAuthenticated
          ? (customerController.currentCustomer?.uid ?? '')
          : 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final customerName = _fullNameController.text.trim();
      final customerEmail = _emailController.text.trim();
      final customerPhone = _phoneController.text.trim();

      // Prepare order notes
      String orderNotes = '';
      if (_orderNotesController.text.isNotEmpty) orderNotes += _orderNotesController.text + '\n\n';
      orderNotes += 'CUSTOMER TYPE: ${isAuthenticated ? 'Registered' : 'Guest'}\n';
      if (_appliedPromo.value != null) {
        orderNotes += 'PROMO CODE: ${_appliedPromo.value!.code}\nPROMO DISCOUNT: ${_promoDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}\n';
      }
      if (_appliedReferralCode.value != null) {
        orderNotes += 'REFERRAL CODE: ${_appliedReferralCode.value}\nREFERRAL DISCOUNT: ${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}\n';
      }
      if (isAuthenticated && pointsToUse > 0 && _activeDiscountType.value != 'promo' && _activeDiscountType.value != 'referral') {
        orderNotes += 'LOYALTY POINTS USED: $pointsToUse points\nPOINTS DISCOUNT: ${pointsDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny}\n';
      }
      orderNotes += 'PAYMENT METHOD: ${_selectedPaymentMethod.value.toUpperCase()}';
      if (isAuthenticated && finalPrice == 0) orderNotes += ' (Fully Paid with Points)';
      else if (isAuthenticated && pointsToUse > 0) orderNotes += ' (Partial Points Payment)';
      orderNotes += '\nFINAL AMOUNT: ${finalPrice.toStringAsFixed(2)} ${AppStrings.appCurreny}';

      // Get cart items and prepare order products
      final cartItems = cartController.cartItems;
      if (cartItems.isEmpty) {
        Get.snackbar('Error', 'Cart is empty', backgroundColor: Colors.red, colorText: AppColors.white);
        return;
      }

      final orderProducts = <OrderProduct>[];
      final branchNames = <String>{};

      for (final cartItem in cartItems) {
        final product = await productController.getProductById(cartItem.productId);
        if (product == null) {
          Get.snackbar('Error', 'Product ${cartItem.productName} not found', backgroundColor: Colors.red, colorText: AppColors.white);
          return;
        }

        final orderProduct = OrderProduct(
          productId: product.id,
          productName: product.name,
          productImage: product.imageUrl,
          productCategory: product.category,
          productCategoryId: product.categoryId,
          price: product.price,
          productCost: product.cost,
          productSku: product.sku,
          quantity: cartItem.quantity,
          productBranches: product.branches,
          productBranchNames: product.branchNames,
        );

        orderProducts.add(orderProduct);
        branchNames.addAll(product.branchNames);
      }

      final totalAmount = orderProducts.fold(0.0, (sum, product) => sum + product.totalPrice);
      final orderDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final expectedDeliveryDate = _expectedPickupController.text.isNotEmpty
          ? _expectedPickupController.text
          : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 3)));

      // Determine payment status based on payment method
      String paymentStatus;
      if (_selectedPaymentMethod.value == 'card') {
        paymentStatus = 'pending'; // Will be updated after successful Stripe payment
      } else if (_selectedPaymentMethod.value == 'wallet' && pointsToUse > 0 && finalPrice == 0) {
        paymentStatus = 'paid';
      } else {
        paymentStatus = _selectedPaymentMethod.value == 'cod' ? 'pending' : 'paid';
      }

      // ✅ Use finalPrice for order total amount
      final orderTotal = finalPrice;

      // Create order
      final order = await orderController.createOrder(
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        products: orderProducts,
        branchNames: branchNames.toList(),
        totalAmount: orderTotal,
        status: 'upcoming',
        paymentMethod: _selectedPaymentMethod.value,
        paymentStatus: paymentStatus,
        orderDate: orderDate,
        expectedDeliveryDate: expectedDeliveryDate,
        pickupBranch: _selectedBranch.value!.name,
        pickupBranchAddress: _selectedBranch.value!.fullAddress,
        pickupBranchPhone: _selectedBranch.value!.phone,
        pickupBranchTiming: _selectedBranch.value!.businessHours,
        orderNotes: orderNotes,
        pointsAwarded: false,
      );

      if (order != null) {
        // Apply referral code if used
        // if (_appliedReferralCode.value != null && isAuthenticated) {
        //   await referralController.applyReferralCodeAtCheckout(customerId, _appliedReferralCode.value!);
        // }

        // Increment promo code usage count if promo was applied
        if (_appliedPromo.value != null) {
          await promoCodeController.incrementUsageCount(_appliedPromo.value!.id);
        }

        if (_selectedPaymentMethod.value == 'card') {
          final response = await _totalPayController.initiatePayment(
            orderId: order.transactionId,
            amount: finalPrice,
            currency: 'AED',
            customerName: customerName,
            customerEmail: customerEmail,
            referenceType: 'order',
            referenceId: order.id,
          );

          if (response != null && response.success && response.redirectUrl != null) {
            await Get.to(() => PaymentWebviewScreen(
              checkoutUrl: response.redirectUrl!,
              cookieHeader: response.cookies,
              onPaymentComplete: (success) async {
                if (success) {
                  await orderController.updatePaymentStatus(order.id, 'paid');
                  cartController.clearCart();
                  await _showConfirmationDialog(order);
                } else {
                  Get.snackbar(
                    'Payment Failed',
                    'Your payment could not be processed. Please try again.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
            ));
          } else {
            Get.snackbar('Payment Error', 'Failed to initialize payment. Please try again.');
          }
        }
        else if (_selectedPaymentMethod.value == 'wallet' && pointsToUse > 0 && _activeDiscountType.value != 'promo' && _activeDiscountType.value != 'referral') {
          // Redeem points for wallet payment
          await _redeemPointsForOrder(order.id);
          await _showConfirmationDialog(order);
        } else {
          // COD or fully paid with points
          await _showConfirmationDialog(order);
        }

        // Award purchase points (only for authenticated users with cash payment)
        if (isAuthenticated && _selectedPaymentMethod.value == 'cod' && finalPrice > 0) {
          await _awardPurchasePoints(order.id);
        }

        // Clear cart
        cartController.clearCart();
      } else {
        Get.snackbar('Order Failed', 'Failed to place order. Please try again.', backgroundColor: Colors.red, colorText: AppColors.white);
      }
    } catch (e) {
      Get.snackbar('Order Failed', 'Error placing order: ${e.toString()}', backgroundColor: Colors.red, colorText: AppColors.white);
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> _redeemPointsForOrder(String orderId) async {
    try {
      if (pointsToUse > 0) {
        final redemptionRate = loyaltyController.loyaltyConfig?.redemptionRate ?? 0.03;
        final pointsDiscountAmount = pointsToUse * redemptionRate;

        await loyaltyController.redeemPointsForOrder(
          customerId: customerController.currentCustomer!.uid,
          points: pointsToUse,
          orderAmount: priceAfterDiscount,
          orderId: orderId,
          itemCount: cartController.itemCount,
          pointsDiscount: pointsDiscountAmount,
          branchName: _selectedBranch.value?.name,
          metadata: {
            'appliedPromo': _appliedPromo.value?.code,
            'promoDiscount': _promoDiscount,
            'appliedReferral': _appliedReferralCode.value,
            'referralDiscount': _referralDiscount,
            'paymentMethod': _selectedPaymentMethod.value,
            'finalAmount': finalPrice,
            'pointsUsed': pointsToUse,
            'pointsValue': pointsDiscountAmount,
            'remainingBalance': finalPrice,
          },
        );

        await loyaltyController.refreshWalletAfterPayment(customerController.currentCustomer!.uid);
      }
    } catch (e) {
      print('Error redeeming points: $e');
      Get.snackbar(
        'Payment Note',
        'Order placed but points payment failed. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
      );
    }
  }

  Future<void> _awardPurchasePoints(String orderId) async {
    try {
      final cashPaid = finalPrice;
      if (cashPaid > 0) {
        await loyaltyController.awardProductPurchasePoints(
          customerId: customerController.currentCustomer!.uid,
          purchaseId: orderId,
          amount: cashPaid,
          productName: '${cartController.itemCount} products',
        );
      }
      await orderController.updateOrderPointsAwarded(orderId, true);
    } catch (e) {
      print('Error awarding purchase points: $e');
    }
  }

  Future<void> _showConfirmationDialog(Order order) async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        contentPadding: AppSizes.paddingAll(AppSizes.spaceLarge24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.width(80),
              height: AppSizes.height(80),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: AppSizes.icon(48),
                color: Colors.green,
              ),
            ),
            SizedBox(height: AppSizes.spaceLarge24),
            Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: AppSizes.textExtraLarge22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              _selectedPaymentMethod.value == 'card'
                  ? 'Your payment is being processed. You will receive a confirmation shortly.'
                  : 'Your order has been successfully placed. You will receive a confirmation email shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),

            if (!isAuthenticated)
              Container(
                margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppSizes.icon(16),
                      color: Colors.blue,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Text(
                        'Create an account to track your orders and earn loyalty points!',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_appliedPromo.value != null)
              Container(
                margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promo Code Applied',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: AppSizes.height(2)),
                          Text(
                            '${_appliedPromo.value!.code} (${_promoDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} off)',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_appliedReferralCode.value != null)
              Container(
                margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referral Code Applied',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: AppSizes.height(2)),
                          Text(
                            '${_appliedReferralCode.value} (${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} off)',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (isAuthenticated && pointsToUse > 0 && _activeDiscountType.value != 'promo' && _activeDiscountType.value != 'referral')
              Container(
                margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: AppSizes.icon(16),
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loyalty Points Used',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: AppSizes.height(2)),
                          Text(
                            '$pointsToUse points (${pointsDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} discount)',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: AppSizes.icon(16),
                    color: Colors.blue,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: AppSizes.height(2)),
                        Text(
                          order.transactionId,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Pickup at: ${_selectedBranch.value?.name}',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
            Text(
              'Order Total: ${order.totalAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.height(48),
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.off(() => ProfileScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                    ),
                    child: Text(
                      'View My Orders',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.height(48),
                  child: TextButton(
                    onPressed: () {
                      Get.back();
                      Get.offAll(() => const CustomerShell());
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}