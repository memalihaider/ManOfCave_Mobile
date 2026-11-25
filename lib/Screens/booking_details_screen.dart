// screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/booking_controller.dart';
import '../controlers/feedback_controller.dart';
import '../models/booking_model.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingController _bookingController = Get.find<BookingController>();
  final FeedbackController _feedbackController = Get.find<FeedbackController>();
  final Rx<Booking?> _booking = Rx<Booking?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _hasGivenFeedback = false.obs;
  final RxBool _isSubmittingFeedback = false.obs;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      _isLoading.value = true;
      final booking = await _bookingController.getBookingById(widget.bookingId);
      _booking.value = booking;

      if (booking != null && booking.isCompleted) {
        await _checkFeedbackStatus();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load booking details',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
        borderRadius: AppSizes.radiusMedium12,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _checkFeedbackStatus() async {
    if (_booking.value == null) return;

    try {
      _hasGivenFeedback.value = await _feedbackController.hasGivenFeedback(
        _booking.value!.serviceId,
        'service',
        _booking.value!.customerId,
      );
    } catch (e) {
      // Silently fail
    }
  }

  void _showCancelDialog() {
    if (_booking.value == null) return;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        ),
        title: Text(
          'Cancel Booking',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel booking ${_booking.value!.bookingNumber}?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _bookingController.cancelBooking(widget.bookingId);
              await _loadBookingDetails();
              Get.snackbar(
                'Booking Cancelled',
                'Booking has been cancelled successfully',
                backgroundColor: AppColors.success,
                colorText: AppColors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
                borderRadius: AppSizes.radiusMedium12,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    if (_booking.value == null) return;

    final _rating = 5.obs;
    final _commentController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.width(40),
                height: AppSizes.height(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              Text(
                'How was your ${_booking.value!.serviceName} service?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),

              // Star Rating
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _rating.value = index + 1,
                    child: Padding(
                      padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8),
                      child: Icon(
                        index < _rating.value ? Icons.star : Icons.star_border,
                        size: AppSizes.iconLarge32,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  );
                }),
              )),
              SizedBox(height: AppSizes.spaceSmall8,),
              Obx(() => Text(
                '${_rating.value} ${_rating.value == 1 ? 'Star' : 'Stars'}',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGold,
                ),
              )),
              SizedBox(height: AppSizes.spaceSmall8,),

              // Comment Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Comments (Optional)',
                        hintText: 'Tell us about your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      ),
                      style: TextStyle(fontSize: AppSizes.textMedium14),
                    ),
                    SizedBox(height: AppSizes.spaceSmall8,),
                    // Submit Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightMedium50,
                      child: ElevatedButton(
                        onPressed: _isSubmittingFeedback.value ? null : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await _submitFeedback(
                              rating: _rating.value.toInt(),
                              comment: _commentController.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isSubmittingFeedback.value
                            ? SizedBox(
                          width: AppSizes.iconMedium24,
                          height: AppSizes.iconMedium24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                            : Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _submitFeedback({required int rating, required String comment}) async {
    if (_booking.value == null) return;

    _isSubmittingFeedback.value = true;

    try {
      final feedbackId = await _feedbackController.submitBookingFeedback(
        bookingId: widget.bookingId,
        serviceId: _booking.value!.serviceId,
        serviceName: _booking.value!.serviceName,
        rating: rating,
        comment: comment,
        serviceBranches: _booking.value!.branchNames,
        serviceBranchNames: _booking.value!.branchNames,
        serviceCategory: _booking.value!.serviceCategory,
        serviceCategoryId: _booking.value!.serviceCategoryId,
        servicePrice: _booking.value!.servicePrice,
        serviceDuration: _booking.value!.serviceDuration,
        serviceImageUrl: '',
        serviceDescription: '',
      );

      if (feedbackId != null) {
        Get.back();
        _hasGivenFeedback.value = true;

        Get.snackbar(
          'Feedback Submitted',
          'Thank you for your valuable feedback!',
          backgroundColor: AppColors.success,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
          borderRadius: AppSizes.radiusMedium12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit feedback',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
        borderRadius: AppSizes.radiusMedium12,
      );
    } finally {
      _isSubmittingFeedback.value = false;
    }
  }
  void _showReceipt() {
    if (_booking.value == null) return;

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.width(40),
                height: AppSizes.height(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              Text(
                'Booking Receipt',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              _buildReceiptContent(),
              SizedBox(height: AppSizes.spaceSmall8,),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final booking = _booking.value;
    if (booking == null) return const SizedBox();

    return Column(
      children: [
        Text(
          'BOOKING RECEIPT',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8,),
        Text(
          'Booking #${booking.bookingNumber}',
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8,),
        Text(
          'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt)}',
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8,),

        // Service Details
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              Row(
                children: [
                  Container(
                    width: AppSizes.width(50),
                    height: AppSizes.height(50),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Icon(
                      Icons.spa_outlined,
                      size: AppSizes.iconMedium24,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSmall8,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '${booking.durationFormatted} • ${booking.serviceCategory}',
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
            ],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8,),

        // Amount Summary
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Column(
            children: [
              if (booking.discountAmount > 0)
                _buildReceiptRow('Discount', '-${AppStrings.appCurreny}${booking.discountAmount.toStringAsFixed(2)}'),
              if (booking.productsTotal > 0)
                _buildReceiptRow('Products', '${AppStrings.appCurreny}${booking.productsTotal.toStringAsFixed(2)}'),
              SizedBox(height: AppSizes.spaceSmall8,),
              Divider(color: Colors.grey[300]),
              SizedBox(height: AppSizes.spaceSmall8,),
              _buildReceiptRow(
                'Total Amount',
                '${AppStrings.appCurreny}${booking.totalAmount.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? AppSizes.textMedium14 : AppSizes.textSmall12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? AppSizes.textMedium14 : AppSizes.textSmall12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppColors.primaryGold : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Obx(() => Text(
          _booking.value?.bookingNumber ?? 'Booking Details',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          iconSize: AppSizes.iconMedium24,
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return _buildLoadingScreen();
        }

        if (_booking.value == null) {
          return _buildNotFoundScreen();
        }

        final booking = _booking.value!;

        return SingleChildScrollView(
          padding: AppSizes.paddingOnly(bottom: AppSizes.buttonHeightLarge60 + AppSizes.spaceLarge24),
          child: Column(
            children: [
              // Booking Status Banner
              _buildBookingStatusBanner(booking),

              // Feedback Prompt for Completed Bookings
              if (booking.isCompleted && !_hasGivenFeedback.value)
                _buildFeedbackPrompt(),

              // Service Details
              _buildServiceDetails(booking),

              // Appointment Details
              _buildAppointmentDetails(booking),

              // Staff & Branch Details
              _buildStaffBranchDetails(booking),

              // Customer Information
              _buildCustomerInfo(booking),

              // Payment Information
              _buildPaymentInfo(booking),

              // Notes Section
              if (booking.notes.isNotEmpty) _buildNotesSection(booking),

              // Extra padding
              SizedBox(height: AppSizes.spaceSmall8,),
            ],
          ),
        );
      }),
      bottomSheet: Obx(() {
        if (_booking.value == null) return const SizedBox();

        final booking = _booking.value!;

        return Container(
          width: double.infinity,
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.spaceMedium16,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: AppSizes.radius(AppSizes.spaceMedium16),
                offset: Offset(0, -AppSizes.height(4)),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Feedback Button for Completed Bookings
                  if (booking.isCompleted && !_hasGivenFeedback.value)
                    _buildActionButton(
                      onPressed: _showFeedbackDialog,
                      icon: Icons.star_outline,
                      label: 'Give Feedback',
                      color: Colors.purple,
                    ),

                  // Cancel Button for Pending/Confirmed Bookings
                  if (booking.isPending || booking.isConfirmed)
                    _buildActionButton(
                      onPressed: _showCancelDialog,
                      icon: Icons.cancel_outlined,
                      label: 'Cancel Booking',
                      color: Colors.red,
                      isOutlined: true,
                    ),


                  // Receipt Button
                  _buildActionButton(
                    onPressed: _showReceipt,
                    icon: Icons.receipt_outlined,
                    label: 'Receipt',
                    color: Colors.blue,
                  ),
                ].map((button) => Padding(
                  padding: EdgeInsets.only(right: AppSizes.spaceSmall8),
                  child: button,
                )).toList(),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return SizedBox(
        height: AppSizes.buttonHeightMedium50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: AppSizes.iconSmall18),
          label: Text(
            label,
            style: TextStyle(fontSize: AppSizes.textSmall12),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: AppSizes.buttonHeightMedium50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSizes.iconSmall18),
        label: Text(
          label,
          style: TextStyle(fontSize: AppSizes.textSmall12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPrompt() {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars,
            size: AppSizes.iconMedium24,
            color: Colors.purple,
          ),
          SizedBox(width: AppSizes.spaceSmall8,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate Your Experience',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8,),
                Text(
                  'Help us improve by sharing your feedback and earn loyalty points!',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showFeedbackDialog,
            icon: Icon(
              Icons.arrow_forward,
              size: AppSizes.iconMedium24,
              color: Colors.purple,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: AppSizes.width(40),
              minHeight: AppSizes.height(40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatusBanner(Booking booking) {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      color: booking.statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(40),
            height: AppSizes.height(40),
            decoration: BoxDecoration(
              color: booking.statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              booking.statusIcon,
              size: AppSizes.iconMedium24,
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w700,
                    color: booking.statusColor,
                  ),
                ),
                Text(
                  _getBookingStatusMessage(booking.status),
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8,),
                LinearProgressIndicator(
                  value: _getBookingProgress(booking.status),
                  backgroundColor: Colors.grey[300],
                  color: booking.statusColor,
                  minHeight: AppSizes.height(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBookingStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your booking is pending confirmation';
      case 'confirmed':
        return 'Booking confirmed, see you soon!';
      case 'in-progress':
        return 'Your service is in progress';
      case 'completed':
        return 'Service completed successfully';
      case 'cancelled':
        return 'Booking has been cancelled';
      default:
        return 'Booking status unknown';
    }
  }

  double _getBookingProgress(String status) {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'confirmed':
        return 0.5;
      case 'in-progress':
        return 0.8;
      case 'completed':
        return 1.0;
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Widget _buildServiceDetails(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.width(60),
                height: AppSizes.height(60),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: AppSizes.iconMedium24,
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: TextStyle(
                        fontSize: AppSizes.font(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceSmall8,),
                    Row(
                      children: [
                        _buildDetailChip(
                          booking.durationFormatted,
                          Icons.access_time_outlined,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8,),
                        _buildDetailChip(
                          '${booking.servicePrice.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          Icons.attach_money_outlined,
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

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.width(4),
        vertical: AppSizes.height(4),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSizes.iconSmall14,
            color: Colors.grey[600],
          ),
          SizedBox(width: AppSizes.spaceSmall8,),
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

  Widget _buildAppointmentDetails(Booking booking) {
    return Container(
      margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: AppSizes.iconMedium24,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                'Appointment Details',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          _buildDetailRow('Booking Number', booking.bookingNumber),
          _buildDetailRow('Date', '${booking.formattedDate} (${booking.date})'),
          _buildDetailRow('Time', '${booking.formattedTime} (${booking.timeSlot})'),
          _buildDetailRow('Duration', booking.durationFormatted),
          _buildDetailRow('Created', DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt)),
        ],
      ),
    );
  }

  Widget _buildStaffBranchDetails(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: AppSizes.iconMedium24,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                'Location & Staff',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          _buildDetailRow('Branch', booking.branch),
          _buildDetailRow('Staff', booking.staffName),
          _buildDetailRow('Role', booking.staffRole),
          if (booking.teamMembers.isNotEmpty) ...[
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              'Team:',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            ...booking.teamMembers.map((member) => Padding(
              padding: EdgeInsets.only(left: AppSizes.spaceSmall8, top: AppSizes.spaceSmall8),
              child: Text(
                '• ${member['name']} (${member['role'] ?? ''})',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Booking booking) {
    return Container(
      margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: AppSizes.iconMedium24,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          _buildDetailRow('Name', booking.customerName),
          _buildDetailRow('Email', booking.customerEmail),
          _buildDetailRow('Phone', booking.customerPhone),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                size: AppSizes.iconMedium24,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          _buildDetailRow('Method', booking.paymentMethod),
          _buildDetailRow('Status', booking.paymentStatus),
          if (booking.trnNumber.isNotEmpty)
            _buildDetailRow('Transaction ID', booking.trnNumber),
          SizedBox(height: AppSizes.spaceSmall8,),

          // Amount Summary
          Container(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Column(
              children: [
                _buildAmountRow('Service Price', '${booking.servicePrice.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                if (booking.serviceCharges > 0)
                  _buildAmountRow('Service Charges', '${booking.serviceCharges.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                if (booking.taxAmount > 0)
                  _buildAmountRow('Tax (${booking.tax}%)', '${booking.taxAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                if (booking.discountAmount > 0)
                  _buildAmountRow('Discount', '-${booking.discountAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                if (booking.tip > 0)
                  _buildAmountRow('Tip', '${booking.tip.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                if (booking.productsTotal > 0)
                  _buildAmountRow('Products', '${booking.productsTotal.toStringAsFixed(2)} ${AppStrings.appCurreny}'),
                SizedBox(height: AppSizes.spaceSmall8,),
                Divider(color: Colors.grey[300]),
                SizedBox(height: AppSizes.spaceSmall8,),
                _buildAmountRow(
                  'Total',
                  '${booking.totalAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                  isTotal: true,
                ),
                SizedBox(height: AppSizes.spaceSmall8,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Points Awarded',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      booking.pointsAwarded ? 'Yes' : 'No',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: booking.pointsAwarded ? AppColors.success : Colors.orange,
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

  Widget _buildAmountRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? AppSizes.textMedium14 : AppSizes.textSmall12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? AppSizes.textMedium14 : AppSizes.textSmall12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppColors.primaryGold : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(Booking booking) {
    return Container(
      margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: AppSizes.iconMedium24,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          Container(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Text(
              booking.notes,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.width(120),
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: AppSizes.spaceSmall8,),
          Text(
            'Loading booking details...',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAll(AppSizes.spaceLarge24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSizes.iconLarge60,
              color: Colors.grey[400],
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              'Booking not found',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            SizedBox(
              height: AppSizes.buttonHeightMedium50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceLarge24,
                    vertical: AppSizes.spaceMedium16,
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}