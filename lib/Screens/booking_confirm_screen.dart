// screens/booking_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/Screens/customer_shell.dart';
import 'package:man_of_cave/Screens/login_screen.dart';
import 'package:man_of_cave/Screens/my_booking_screen.dart';
import 'package:man_of_cave/Screens/payment_webView_screen.dart';
import 'package:man_of_cave/widgets/custom_textfield.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/booking_controller.dart';
import '../controlers/branches_controller.dart';
import '../controlers/category_controller.dart';
import '../controlers/customer_controller.dart';
import '../controlers/loyalty_points_controller.dart';
import '../controlers/promo_code_controller.dart';
import '../controlers/referral_controller.dart';
import '../controlers/payment_controller.dart';
import '../controlers/service_controller.dart';
import '../controlers/staff_controller.dart';
import '../controlers/totalpay_controller.dart';
import '../models/branch_model.dart';
import '../models/staff.dart';
import '../models/promo_code_model.dart';
import '../models/payment_model.dart';
import '../widgets/booking_summary.dart';
import '../widgets/payment_option.dart';
import '../widgets/stripe_payment_card.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final int serviceDuration;
  final double servicePrice;
  final String selectedDate;
  final String selectedTime;
  final String selectedTimeSlot;
  final String branchName;
  final String? branchAddress;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  const BookingSummaryScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDuration,
    required this.servicePrice,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedTimeSlot,
    required this.branchName,
    this.branchAddress,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final StaffController staffController = Get.find<StaffController>();
  final BookingController bookingController = Get.find<BookingController>();
  final ServiceController serviceController = Get.find<ServiceController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final LoyaltyController loyaltyController = Get.find<LoyaltyController>();
  final PromoCodeController promoCodeController = Get.find<PromoCodeController>();
  final TotalPayController _totalPayController = Get.find<TotalPayController>();
  // final ReferralController referralController = Get.find<ReferralController>();
  // final PaymentController paymentController = Get.find<PaymentController>();

  final RxString selectedPaymentMethod = 'cash'.obs;
  final RxBool isProcessing = false.obs;
  final RxBool showPointsInput = false.obs;

  // Promo code related state
  final TextEditingController _promoController = TextEditingController();
  final Rx<PromoCodeModel?> _appliedPromo = Rx<PromoCodeModel?>(null);
  final RxBool _isApplyingPromo = false.obs;
  final RxString _promoMessage = ''.obs;
  final RxBool _promoSuccess = false.obs;
  double _promoDiscount = 0.0;

  // Referral code related state
  final TextEditingController _referralController = TextEditingController();
  final Rx<String?> _appliedReferralCode = Rx<String?>(null);
  final RxBool _isApplyingReferral = false.obs;
  final RxString _referralMessage = ''.obs;
  final RxBool _referralSuccess = false.obs;
  double _referralDiscount = 0.0;
  String? _referredById;

  // Points related state
  int availablePoints = 0;
  int pointsToUse = 0;
  double pointsValue = 0.03;
  double pointsDiscount = 0.0;
  double remainingBalance = 0.0;
  int maxPointsToUse = 0;

  // Guest user info controllers
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();

  // Form key for guest validation
  final _guestFormKey = GlobalKey<FormState>();

  // Track which discount is applied (only one can be used at a time)
  final RxString _activeDiscountType = RxString('none');

  // Base price (without any discounts)
  double get basePrice => widget.servicePrice;

  // Price after active discount
  double get priceAfterDiscount {
    if (_activeDiscountType.value == 'promo') {
      return basePrice - _promoDiscount;
    } else if (_activeDiscountType.value == 'referral') {
      return basePrice - _referralDiscount;
    }
    return basePrice;
  }

  // Final price after all applicable discounts
  double get finalPrice {
    double price = priceAfterDiscount;
    if (selectedPaymentMethod.value == 'wallet' && _activeDiscountType.value != 'points') {
      price = priceAfterDiscount - pointsDiscount;
    }
    return price < 0 ? 0 : price;
  }

  // Check if user is authenticated
  bool get isAuthenticated => customerController.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _initializePoints();

    if (!isAuthenticated) {
      if (widget.customerName != null) {
        _guestNameController.text = widget.customerName!;
      }
      if (widget.customerEmail != null) {
        _guestEmailController.text = widget.customerEmail!;
      }
      if (widget.customerPhone != null) {
        _guestPhoneController.text = widget.customerPhone!;
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _referralController.dispose();
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  void _initializePoints() {
    if (isAuthenticated) {
      availablePoints = loyaltyController.availablePoints;
      pointsValue = loyaltyController.loyaltyConfig?.redemptionRate ?? 0.03;
    } else {
      availablePoints = 0;
      pointsValue = 0.03;
    }

    _updateMaxPoints();
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

    if (mounted) {
      setState(() {});
    }
  }

  void _onPointsChanged(int newPoints) {
    setState(() {
      pointsToUse = newPoints;
      _updatePointCalculations();
    });
  }

  int _calculateMaxPoints(int availablePoints, double price) {
    final redemptionRate = loyaltyController.loyaltyConfig?.redemptionRate ?? 0.03;
    final maxPointsByService = (price / redemptionRate).ceil();
    return availablePoints < maxPointsByService ? availablePoints : maxPointsByService;
  }

  String _formatDate(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return dateString;
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
      final branch = await _getBranchIdByName(widget.branchName);
      if (branch == null) {
        _promoMessage.value = 'Branch not found';
        _promoSuccess.value = false;
        _isApplyingPromo.value = false;
        return;
      }

      final result = await promoCodeController.validatePromoCode(
        code: _promoController.text.toUpperCase().trim(),
        branchId: branch.id,
        amount: basePrice,
      );

      if (result['valid']) {
        final promo = result['promo'] as PromoCodeModel;
        final discount = result['discount'] as double;

        setState(() {
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
      print('Promo error: $e');
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
  //   if (_referralController.text.isEmpty) {
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
  //       _referralController.text.trim().toUpperCase(),
  //       currentUserId,
  //     );
  //
  //     if (isValid) {
  //       final discount = referralController.getFriendDiscount(basePrice);
  //
  //       setState(() {
  //         _clearAllDiscounts();
  //         _appliedReferralCode.value = _referralController.text.trim().toUpperCase();
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
  //     print('Referral error: $e');
  //   } finally {
  //     _isApplyingReferral.value = false;
  //   }
  // }

  // void _removeReferralCode() {
  //   setState(() {
  //     _appliedReferralCode.value = null;
  //     _referralDiscount = 0.0;
  //     _referralController.clear();
  //     _referralMessage.value = '';
  //     _referralSuccess.value = false;
  //     _activeDiscountType.value = 'none';
  //   });
  //
  //   _updateMaxPoints();
  //   if (pointsToUse > maxPointsToUse) pointsToUse = maxPointsToUse;
  //   _updatePointCalculations();
  // }

  void _clearAllDiscounts() {
    _appliedPromo.value = null;
    _promoDiscount = 0.0;
    _promoController.clear();
    _promoMessage.value = '';
    _promoSuccess.value = false;

    _appliedReferralCode.value = null;
    _referralDiscount = 0.0;
    _referralController.clear();
    _referralMessage.value = '';
    _referralSuccess.value = false;

    if (_activeDiscountType.value == 'points') {
      pointsToUse = 0;
      pointsDiscount = 0.0;
      _updatePointCalculations();
    }

    _activeDiscountType.value = 'none';
  }

  Future<Branch?> _getBranchIdByName(String branchName) async {
    try {
      final branchController = Get.find<BranchController>();
      for (var branch in branchController.branches) {
        if (branch.name == branchName || branch.id == branchName) {
          return branch;
        }
      }
      return null;
    } catch (e) {
      print('Error finding branch: $e');
      return null;
    }
  }

  // ============================================================
  // 🔥 POINTS REDEMPTION METHOD
  // ============================================================

  Future<void> _redeemPointsForBooking(String bookingId) async {
    if (pointsToUse <= 0) return;

    try {
      print('🎯 Redeeming $pointsToUse points for booking $bookingId');
      print('   - Points value: $pointsValue');
      print('   - Points discount: $pointsDiscount');

      final success = await loyaltyController.redeemPointsForBookingPayment(
        customerId: customerController.currentCustomer?.uid ?? '',
        points: pointsToUse,
        bookingAmount: widget.servicePrice,
        bookingId: bookingId,
        bookingType: 'service',
        serviceName: widget.serviceName,
        pointsDiscount: pointsDiscount,
        branchName: widget.branchName,
        metadata: {
          'bookingDate': widget.selectedDate,
          'bookingTime': widget.selectedTime,
          'timeSlot': widget.selectedTimeSlot,
          'appliedPromo': _appliedPromo.value?.code,
          'promoDiscount': _promoDiscount,
          'appliedReferral': _appliedReferralCode.value,
          'referralDiscount': _referralDiscount,
          'redemptionRate': pointsValue,
          'pointsToUse': pointsToUse,
          'pointsValue': pointsDiscount,
        },
      );

      if (success) {
        print('✅ Successfully redeemed $pointsToUse points for booking $bookingId');
        await loyaltyController.refreshWalletAfterPayment(customerController.currentCustomer?.uid ?? '');
      } else {
        print('❌ Failed to redeem points for booking $bookingId');
        Get.snackbar(
          'Payment Note',
          'Booking created but points payment failed. Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error redeeming points for booking: $e');
    }
  }

  // ============================================================
  // 🔥 STRIPE PAYMENT METHOD
  // ============================================================

  // Future<void> _processStripePayment(String bookingId) async {
  //   if (finalPrice <= 0) {
  //     print('❌ Cannot process Stripe payment for amount 0');
  //     await _showConfirmationDialog();
  //     return;
  //   }
  //
  //   try {
  //     final success = await Get.to(() => StripePaymentWidget(
  //       amount: finalPrice,
  //       paymentType: PaymentType.booking,
  //       referenceId: bookingId,
  //       onPaymentComplete: (completed, paymentIntentId) async {
  //         if (completed) {
  //           await bookingController.updateBookingPayment(
  //             bookingId: bookingId,
  //             paymentMethod: 'card',
  //             paymentStatus: 'paid',
  //           );
  //           await _showConfirmationDialog();
  //         }
  //         return completed;
  //       },
  //     ));
  //
  //     if (success != true) {
  //       Get.snackbar(
  //         'Payment Failed',
  //         'Your payment was not completed. Please try again.',
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //     }
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
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Booking Summary',
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
          final selectedStaff = staffController.selectedStaff.value;
          final assignAnyStaff = staffController.assignAnyStaff.value;

          return Column(
            children: [
              _buildSummaryHeader(isLandscape),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                  child: Column(
                    children: [
                      _buildServiceDetails(),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildTimeLocation(isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildStaffSelection(selectedStaff, assignAnyStaff, isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildCustomerInfo(isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildPromoCodeSection(isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      // _buildReferralCodeSection(isLandscape),
                      // SizedBox(height: AppSizes.spaceSmall8),
                      _buildWalletBalance(isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildPaymentMethod(isLandscape),
                      if (showPointsInput.value && selectedPaymentMethod.value == 'wallet' && isAuthenticated && _activeDiscountType.value != 'points')
                        _buildPointsInputSection(isLandscape),
                      SizedBox(height: AppSizes.spaceSmall8),
                      _buildTotalAmount(isLandscape),
                      SizedBox(height: AppSizes.height(180)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: _buildConfirmButton(),
    );
  }

  // ============================================================
  // 🔥 ALL UI BUILD METHODS (KEEP EXACTLY AS ORIGINAL)
  // ============================================================

  Widget _buildSummaryHeader(bool isLandscape) {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.summarize_outlined,
            size: AppSizes.iconSmall18,
            color: AppColors.primaryGold,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Text(
              'Review your booking details before confirming',
              style: TextStyle(
                fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Details',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.width(40),
                height: AppSizes.height(40),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: AppSizes.icon(28),
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    Row(
                      children: [
                        _buildDetailChip(
                          '${widget.serviceDuration} min',
                          Icons.access_time_outlined,
                        ),
                        SizedBox(width: AppSizes.width(8)),
                        _buildDetailChip(
                          '${widget.servicePrice.toStringAsFixed(0)} ${AppStrings.appCurreny}',
                          Icons.attach_money_outlined,
                        ),
                      ],
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

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8, vertical: AppSizes.height(2)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.icon(14),
            color: Colors.grey[600],
          ),
          SizedBox(width: AppSizes.width(4)),
          Text(
            text,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLocation(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time & Location',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              BookingSummaryItem(
                icon: Icons.calendar_today_outlined,
                title: 'Date',
                value: _formatDate(widget.selectedDate),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              BookingSummaryItem(
                icon: Icons.schedule_outlined,
                title: 'Time',
                value: '${widget.selectedTime} (${widget.selectedTimeSlot})',
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              BookingSummaryItem(
                icon: Icons.location_on_outlined,
                title: 'Location',
                value: widget.branchName,
                isHighlighted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSelection(Staff? selectedStaff, bool assignAnyStaff, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned Staff',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Change',
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
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: AppColors.primaryGold, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.width(40),
                height: AppSizes.height(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radius(25)),
                  border: Border.all(color: AppColors.primaryGold, width: 2),
                  color: AppColors.primaryGold.withOpacity(0.1),
                ),
                child: selectedStaff?.avatar != null && selectedStaff!.avatar!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radius(25)),
                  child: Image.network(
                    selectedStaff.avatar!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Icon(
                  Icons.person,
                  size: AppSizes.icon(24),
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignAnyStaff
                          ? 'Any Available Staff'
                          : selectedStaff?.name ?? 'No Staff Selected',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: AppSizes.height(4)),
                    if (!assignAnyStaff && selectedStaff != null)
                      Text(
                        selectedStaff.role,
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
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(bool isLandscape) {
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
                onPressed: () {
                  Get.to(() => const LoginScreen());
                },
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
        Form(
          key: _guestFormKey,
          child: Container(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              border: Border.all(
                color: !isAuthenticated ? AppColors.primaryGold : Colors.grey[200]!,
              ),
            ),
            child: isAuthenticated
                ? _buildAuthenticatedCustomerInfo()
                : _buildGuestCustomerInfo(),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedCustomerInfo() {
    final currentCustomer = customerController.currentCustomer;
    final name = currentCustomer?.name ?? 'User';
    final email = currentCustomer?.email ?? '';
    final phone = currentCustomer?.phone ?? '';

    return Column(
      children: [
        BookingSummaryItem(
          icon: Icons.person_outline,
          title: 'Name',
          value: name,
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        BookingSummaryItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: email,
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        BookingSummaryItem(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: phone,
        ),
      ],
    );
  }

  Widget _buildGuestCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextfield(
          hintText: "Your Name",
          controller: _guestNameController,
          prefixIcon: const Icon(Icons.person),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        CustomTextfield(
          hintText: "Your Email",
          controller: _guestEmailController,
          prefixIcon: const Icon(Icons.email),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!GetUtils.isEmail(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        CustomTextfield(
          hintText: "Your Number",
          controller: _guestPhoneController,
          prefixIcon: const Icon(Icons.phone),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.trim().length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        SizedBox(height: AppSizes.spaceSmall8),
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
                  'You are booking as a guest. Your information will be used for this booking only.',
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
    );
  }

  Widget _buildPromoCodeSection(bool isLandscape) {
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
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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
                          size: AppSizes.iconSmall18,
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
                          color: AppColors.error,
                          size: AppSizes.iconSmall18,
                        ),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _isApplyingPromo.value ? null : _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.white,
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
                        size: AppSizes.icon(14),
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
                            size: AppSizes.icon(14),
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
                            '-${serviceController.formatPrice(_promoDiscount)}',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
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
  //   if (!isAuthenticated) {
  //     return const SizedBox();
  //   }
  //
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
  //         padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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
  //                     controller: _referralController,
  //                     enabled: _appliedReferralCode.value == null && _activeDiscountType.value == 'none',
  //                     decoration: InputDecoration(
  //                       hintText: 'Enter referral code',
  //                       prefixIcon: Icon(
  //                         Icons.card_giftcard_outlined,
  //                         color: AppColors.primaryGold,
  //                         size: AppSizes.iconSmall18,
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
  //                         color: AppColors.error,
  //                         size: AppSizes.iconSmall18,
  //                       ),
  //                     );
  //                   }
  //                   return ElevatedButton(
  //                     onPressed: _isApplyingReferral.value ? null : _applyReferralCode,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: AppColors.primaryGold,
  //                       foregroundColor: AppColors.white,
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
  //                       size: AppSizes.icon(14),
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
  //                           size: AppSizes.icon(14),
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
    if (!isAuthenticated) {
      return Container(
        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: AppSizes.icon(24),
              color: Colors.grey[500],
            ),
            SizedBox(width: AppSizes.spaceSmall8),
            Expanded(
              child: Text(
                'Login to use loyalty points',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const LoginScreen()),
              child: Text(
                'Login',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final monetaryValue = loyaltyController.monetaryValue;

    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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
          SizedBox(width: AppSizes.spaceSmall8),
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
                              SizedBox(width: AppSizes.height(4)),
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
                isSelected: selectedPaymentMethod.value == 'card',
                onTap: () {
                  selectedPaymentMethod.value = 'card';
                  showPointsInput.value = false;
                  _onPointsChanged(0);
                  if (_activeDiscountType.value != 'none' && _activeDiscountType.value != 'points') {
                    _clearAllDiscounts();
                  }
                },
              ),

            if (finalPrice > 0) SizedBox(height: AppSizes.spaceSmall8),

            // Loyalty / points wallet payment removed — portal e-wallet is staff-managed.

            PaymentOptionCard(
              icon: Icons.money_outlined,
              title: 'Pay with Cash',
              subtitle: 'Pay at the salon',
              isSelected: selectedPaymentMethod.value == 'cash',
              onTap: () {
                selectedPaymentMethod.value = 'cash';
                showPointsInput.value = false;
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
      margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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
                      onChanged: (value) {
                        _onPointsChanged(value.toInt());
                      },
                      activeColor: AppColors.primaryGold,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
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
                            color: AppColors.success,
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

  Widget _buildTotalAmount(bool isLandscape) {
    final servicePriceFormatted = serviceController.formatPrice(basePrice);
    final priceAfterDiscountFormatted = serviceController.formatPrice(priceAfterDiscount);
    final finalPriceFormatted = serviceController.formatPrice(finalPrice);

    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Price',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                servicePriceFormatted,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (_promoDiscount > 0) ...[
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
                    SizedBox(width: AppSizes.height(4)),
                    Text(
                      'Promo Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${serviceController.formatPrice(_promoDiscount)}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (_referralDiscount > 0) ...[
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
                    SizedBox(width: AppSizes.height(4)),
                    Text(
                      'Referral Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${serviceController.formatPrice(_referralDiscount)}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (_promoDiscount > 0 || _referralDiscount > 0) ...[
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
                  priceAfterDiscountFormatted,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (pointsDiscount > 0) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      'Loyalty Points Discount',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${serviceController.formatPrice(pointsDiscount)}',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: AppSizes.spaceSmall8),
          Divider(color: Colors.grey[300], height: 1),
          SizedBox(height: AppSizes.spaceSmall8),
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
                finalPriceFormatted,
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
          if (selectedPaymentMethod.value == 'card')
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
          if (selectedPaymentMethod.value == 'cash' && finalPrice > 0)
            Padding(
              padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
              child: Text(
                'Please pay at the salon when you arrive',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.success,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (selectedPaymentMethod.value == 'wallet' && finalPrice == 0)
            Padding(
              padding: AppSizes.paddingOnly(top: AppSizes.spaceSmall8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AppSizes.icon(14),
                    color: AppColors.success,
                  ),
                  SizedBox(width: AppSizes.width(4)),
                  Text(
                    'Fully paid with loyalty points!',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: AppColors.success,
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

  Widget _buildConfirmButton() {
    return Obx(() {
      final hasSufficientPoints = selectedPaymentMethod.value != 'wallet' ||
          (pointsToUse > 0 && availablePoints >= pointsToUse);

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
            if (selectedPaymentMethod.value == 'wallet' && finalPrice > 0)
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
                          'Note: You need to pay ${finalPrice.toStringAsFixed(2)} ${AppStrings.appCurreny} in cash at the salon',
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
                onPressed: (isProcessing.value || !hasSufficientPoints) ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: isProcessing.value
                    ? SizedBox(
                  width: AppSizes.width(20),
                  height: AppSizes.height(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
                    : Text(
                  'Confirm Booking',
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

  Future<void> _confirmBooking() async {
    if (!isAuthenticated && !_guestFormKey.currentState!.validate()) {
      Get.snackbar(
        'Missing Information',
        'Please fill in all customer information fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ✅ Prevent Stripe payment for zero amount
    if (selectedPaymentMethod.value == 'card' && finalPrice <= 0) {
      Get.snackbar(
        'Invalid Payment Method',
        'Card payment requires amount > 0. Switching to Cash.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      selectedPaymentMethod.value = 'cash';
      isProcessing.value = false;
      return;
    }

    isProcessing.value = true;

    try {
      final customerName = isAuthenticated
          ? (customerController.currentCustomer?.name ?? '')
          : _guestNameController.text.trim();
      final customerEmail = isAuthenticated
          ? (customerController.currentCustomer?.email ?? '')
          : _guestEmailController.text.trim();
      final customerPhone = isAuthenticated
          ? (customerController.currentCustomer?.phone ?? '')
          : _guestPhoneController.text.trim();
      final customerId = isAuthenticated
          ? (customerController.currentCustomer?.uid ?? '')
          : 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final service = await serviceController.getServiceById(widget.serviceId);
      if (service == null) {
        Get.snackbar('Error', 'Service not found');
        isProcessing.value = false;
        return;
      }

      String serviceCategory = service.category;
      String serviceCategoryId = service.categoryId;

      if (serviceCategoryId.isEmpty) {
        try {
          final category = await categoryController.getCategoryById(service.categoryId);
          if (category != null) {
            serviceCategory = category.name;
            serviceCategoryId = category.id;
          }
        } catch (e) {
          print('Error getting category: $e');
        }
      }

      final selectedStaff = staffController.selectedStaff.value;
      final assignAnyStaff = staffController.assignAnyStaff.value;
      final staffId = assignAnyStaff ? '' : selectedStaff?.id ?? '';
      final staffName = assignAnyStaff ? 'Any Available Staff' : selectedStaff?.name ?? '';
      final staffRole = assignAnyStaff ? '' : selectedStaff?.role ?? '';

      final List<Map<String, dynamic>> teamMembers = [];
      if (!assignAnyStaff && selectedStaff != null) {
        teamMembers.add({
          'name': selectedStaff.name,
          'role': selectedStaff.role,
          'staffId': selectedStaff.id,
        });
      }

      final double subtotal = basePrice;
      final double serviceCharges = 0;
      final double tax = 0;
      final double taxAmount = (subtotal + serviceCharges) * (tax / 100);
      final double totalDiscount = _promoDiscount + _referralDiscount + pointsDiscount;
      final double totalAmount = subtotal + serviceCharges + taxAmount - totalDiscount;

      String paymentStatus;
      if (selectedPaymentMethod.value == 'card') {
        paymentStatus = 'pending';
      } else if (selectedPaymentMethod.value == 'wallet' && pointsToUse > 0) {
        paymentStatus = totalAmount == 0 ? 'paid' : 'partial';
      } else {
        paymentStatus = selectedPaymentMethod.value == 'cash' ? 'pending' : 'paid';
      }

      String notes = 'Payment Method: ${selectedPaymentMethod.value}.';
      if (_appliedPromo.value != null) {
        notes += ' Promo code: ${_appliedPromo.value!.code} (${_promoDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} discount).';
      }
      if (_appliedReferralCode.value != null) {
        notes += ' Referral code: ${_appliedReferralCode.value} (${_referralDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} discount).';
      }
      if (pointsToUse > 0) {
        notes += ' Points used: $pointsToUse points (${pointsDiscount.toStringAsFixed(2)} ${AppStrings.appCurreny} discount).';
      }

      final userBranchId = widget.branchName;
      final userBranchName = widget.branchName;
      final String createdBy = 'customer_booking';

      final bookingId = await bookingController.createBooking(
        customerName: customerName,
        status: 'upcoming',
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
        servicePrice: widget.servicePrice,
        serviceDuration: widget.serviceDuration,
        serviceCategory: serviceCategory,
        serviceCategoryId: serviceCategoryId,
        date: widget.selectedDate,
        time: widget.selectedTime,
        timeSlot: widget.selectedTimeSlot,
        staffId: staffId,
        staffName: staffName,
        staffRole: staffRole,
        branch: widget.branchName,
        branchId: widget.branchName,
        userBranchId: userBranchId,
        userBranchName: userBranchName,
        customerId: customerId,
        source: 'customer_app',
        createdBy: createdBy,
        notes: notes,
        subtotal: subtotal,
        serviceCharges: serviceCharges,
        tax: tax,
        taxAmount: taxAmount,
        discount: totalDiscount > 0 ? (totalDiscount / widget.servicePrice * 100) : 0,
        discountAmount: totalDiscount,
        discountType: totalDiscount > 0 ? 'combined' : 'none',
        tip: 0,
        serviceTip: 0,
        paymentMethod: selectedPaymentMethod.value,
        paymentStatus: paymentStatus,
        teamMembers: teamMembers,
        bookingDate: widget.selectedDate,
        bookingTime: widget.selectedTime,
      );

      if (bookingId != null) {
        // if (_appliedReferralCode.value != null && isAuthenticated) {
        //   await referralController.applyReferralCodeAtCheckout(customerId, _appliedReferralCode.value!);
        // }

        if (_appliedPromo.value != null) {
          await promoCodeController.incrementUsageCount(_appliedPromo.value!.id);
        }

        if (selectedPaymentMethod.value == 'card') {
          isProcessing.value = true;

          final response = await _totalPayController.initiatePayment(
            orderId: bookingId,
            amount: finalPrice,
            currency: 'AED',
            customerName: customerName,
            customerEmail: customerEmail,
            referenceType: 'booking',
            referenceId: bookingId,
          );

          if (response != null && response.success && response.redirectUrl != null) {
            await Get.to(() => PaymentWebviewScreen(
              checkoutUrl: response.redirectUrl!,
              cookieHeader: response.cookies,
              onPaymentComplete: (success) async {
                if (success) {
                  await bookingController.updateBookingPayment(
                    bookingId: bookingId,
                    paymentMethod: 'card',
                    paymentStatus: 'paid',
                  );
                  staffController.clearSelection();
                  await _showConfirmationDialog();
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

          isProcessing.value = false;
        }
        else if (selectedPaymentMethod.value == 'wallet' && pointsToUse > 0) {
          await _redeemPointsForBooking(bookingId);
          await _showConfirmationDialog();
        } else {
          await _showConfirmationDialog();
        }

        staffController.clearSelection();
      } else {
        Get.snackbar('Error', 'Failed to create booking');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create booking: $e');
      print('Booking error: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _showConfirmationDialog() async {
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
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: AppSizes.textExtraLarge22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              selectedPaymentMethod.value == 'card'
                  ? 'Your payment is being processed. You will receive a confirmation shortly.'
                  : 'Your appointment has been successfully booked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
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
            if (pointsToUse > 0)
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
                color: AppColors.primaryGold.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: AppSizes.icon(16),
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Date',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: AppSizes.height(2)),
                        Text(
                          '${_formatDate(widget.selectedDate)} • ${widget.selectedTime}',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8),
            child: Column(
              children: [
                if (customerController.isAuthenticated)
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.height(48),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.offAll(
                              () => MyBookingsScreen(),
                          transition: Transition.circularReveal,
                          duration: const Duration(milliseconds: 1000),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                      ),
                      child: Text(
                        'View My Bookings',
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
                      Get.offAll(
                            () => const CustomerShell(),
                        transition: Transition.circularReveal,
                        duration: const Duration(milliseconds: 1000),
                      );
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                    ),
                    child: Text(
                      'Done',
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