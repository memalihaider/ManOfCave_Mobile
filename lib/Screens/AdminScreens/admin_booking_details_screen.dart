// screens/admin_booking_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/admin_booking_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/payment_update_dialogue.dart';
import '../../widgets/status_update_dialogue.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final bool isAdmin;

  const AdminBookingDetailScreen({
    super.key,
    required this.bookingId,
    this.isAdmin = true,
  });

  @override
  State<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  final AdminBookingController _controller = Get.find<AdminBookingController>();
  final Rx<Booking?> _booking = Rx<Booking?>(null);
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      _isLoading.value = true;
      final booking = await _getBookingById(widget.bookingId);
      _booking.value = booking;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load booking details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Booking?> _getBookingById(String id) async {
    final booking = _controller.allBookings.firstWhereOrNull((b) => b.id == id);
    if (booking != null) return booking;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .get();

      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching booking: $e');
    }
    return null;
  }

  void _showStatusUpdateDialog() {
    if (_booking.value == null) return;

    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        booking: _booking.value!,
        onStatusUpdate: (status, notes) async {
          final result = await _controller.updateBookingStatus(
            bookingId: widget.bookingId,
            status: status,
            notes: notes,
          );
          if (result) {
            await _loadBookingDetails();
          }
        },
      ),
    );
  }

  // void _showPaymentUpdateDialog() {
  //   if (_booking.value == null) return;
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => PaymentUpdateDialog(
  //       booking: _booking.value!,
  //       onPaymentUpdate: (paymentStatus, paymentMethod, trnNumber) async {
  //         final result = await _controller.updatePaymentStatus(
  //           bookingId: widget.bookingId,
  //           paymentStatus: paymentStatus,
  //           paymentMethod: paymentMethod,
  //           trnNumber: trnNumber,
  //         );
  //         if (result) {
  //           await _loadBookingDetails();
  //         }
  //       },
  //     ),
  //   );
  // }

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
        ),
        actions: [
          IconButton(
            onPressed: _loadBookingDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return _buildLoadingState();
        }

        if (_booking.value == null) {
          return _buildNotFoundState();
        }

        final booking = _booking.value!;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Status Banner
            SliverToBoxAdapter(
              child: _buildStatusBanner(booking),
            ),

            // // Quick Action Buttons (Admin Only)
            // if (widget.isAdmin)
            //   SliverToBoxAdapter(
            //     child: _buildActionButtons(booking),
            //   ),

            // Service Details
            SliverToBoxAdapter(
              child: _buildServiceDetails(booking),
            ),

            // Appointment Details
            SliverToBoxAdapter(
              child: _buildAppointmentDetails(booking),
            ),

            // Customer Information
            SliverToBoxAdapter(
              child: _buildCustomerInfo(booking),
            ),

            // Staff & Branch Details
            SliverToBoxAdapter(
              child: _buildStaffBranchDetails(booking),
            ),

            // Payment Information
            SliverToBoxAdapter(
              child: _buildPaymentInfo(booking),
            ),

            // Notes Section
            if (booking.notes.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildNotesSection(booking),
              ),

            // Timeline/History
            SliverToBoxAdapter(
              child: _buildTimeline(booking),
            ),

            // Bottom Spacing
            SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.height(50)),
            ),
          ],
        );
      }),
      bottomSheet: widget.isAdmin ? _buildAdminBottomSheet() : null,
    );
  }

  Widget _buildStatusBanner(Booking booking) {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      color: booking.statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: booking.statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              booking.statusIcon,
              size: AppSizes.icon(30),
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppSizes.spaceMedium16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: booking.statusColor,
                  ),
                ),
                SizedBox(height: AppSizes.height(4)),
                Text(
                  _getStatusDescription(booking),
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                LinearProgressIndicator(
                  value: _getProgressValue(booking.status),
                  backgroundColor: Colors.grey[300],
                  color: booking.statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(Booking booking) {
    switch (booking.status) {
      case 'pending':
        return 'Awaiting confirmation';
      case 'approved':
        return 'Approved, waiting for service';
      case 'in-progress':
        return 'Service in progress';
      case 'completed':
        return 'Service completed successfully';
      case 'cancelled':
        return 'Booking cancelled';
      default:
        return 'Status unknown';
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'approved':
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

  // Widget _buildActionButtons(Booking booking) {
  //   return Container(
  //     padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
  //     color: AppColors.white,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildActionButton(
  //           Icons.edit,
  //           'Update Status',
  //           _showStatusUpdateDialog,
  //           Colors.blue,
  //         ),
  //         // _buildActionButton(
  //         //   Icons.payment,
  //         //   'Payment',
  //         //   _showPaymentUpdateDialog,
  //         //   Colors.green,
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(
      children: [
        Container(
          width: AppSizes.width(48),
          height: AppSizes.height(48),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: AppSizes.icon(20), color: color),
          ),
        ),
        SizedBox(height: AppSizes.height(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetails(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
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
                  size: AppSizes.icon(28),
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceMedium16),
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
                    SizedBox(height: AppSizes.height(4)),
                    Row(
                      children: [
                        _buildDetailChip(
                          booking.durationFormatted,
                          Icons.access_time_outlined,
                        ),
                        SizedBox(width: AppSizes.width(8)),
                        _buildDetailChip(
                          booking.formatCurrency(booking.servicePrice),
                          Icons.attach_money_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          _buildDetailRow('Category', booking.serviceCategory),
          _buildDetailRow('Service ID', booking.serviceId),
          if (booking.services.isNotEmpty)
            _buildDetailRow('Additional Services', booking.formattedServices),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceSmall8,
        vertical: AppSizes.height(4),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.icon(12), color: Colors.grey[600]),
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

  Widget _buildAppointmentDetails(Booking booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.width(16)),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          _buildDetailRow('Booking Number', booking.bookingNumber),
          _buildDetailRow('Date', '${booking.formattedDate} (${booking.date})'),
          _buildDetailRow('Time', '${booking.formattedTime} (${booking.timeSlot})'),
          _buildDetailRow('Duration', booking.durationFormatted),
          _buildDetailRow('Created At', DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt)),
          _buildDetailRow('Updated At', DateFormat('dd MMM yyyy, hh:mm a').format(booking.updatedAt)),
          _buildDetailRow('Source', booking.source),
          _buildDetailRow('Booked By', booking.createdBy),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
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
                size: AppSizes.icon(20),
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
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
          SizedBox(height: AppSizes.spaceSmall8),
          _buildDetailRow('Name', booking.customerName),
          _buildDetailRow('Email', booking.customerEmail),
          _buildDetailRow('Phone', booking.customerPhone),
          _buildDetailRow('Customer ID', booking.customerId),
        ],
      ),
    );
  }

  Widget _buildStaffBranchDetails(Booking booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.width(16)),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff & Location',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          // Branch Info
          Padding(
            padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: AppSizes.icon(20), color: Colors.grey[600]),
                SizedBox(width: AppSizes.width(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Branch',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        booking.branch,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Staff Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline, size: AppSizes.icon(20), color: Colors.grey[600]),
              SizedBox(width: AppSizes.width(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Staff',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      booking.staffName.isNotEmpty ? booking.staffName : 'Not assigned',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: booking.staffName.isNotEmpty ? AppColors.primaryDark : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Team Members
          if (booking.teamMembers.isNotEmpty) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              'Team Members:',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            ...booking.teamMembers.map((member) {
              return Padding(
                padding: EdgeInsets.only(left: AppSizes.width(8), top: AppSizes.height(4)),
                child: Text(
                  '• ${member['name']} (${member['role'] ?? 'Staff'})',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
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
                size: AppSizes.icon(20),
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.height(4),
                ),
                decoration: BoxDecoration(
                  color: booking.paymentStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: booking.paymentStatusColor),
                ),
                child: Text(
                  booking.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.font(10),
                    fontWeight: FontWeight.w600,
                    color: booking.paymentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          _buildDetailRow('Payment Method', booking.paymentMethod),
          if (booking.trnNumber.isNotEmpty)
            _buildDetailRow('Transaction ID', booking.trnNumber),
          if (booking.cardLast4Digits.isNotEmpty)
            _buildDetailRow('Card', '**** **** **** ${booking.cardLast4Digits}'),

          SizedBox(height: AppSizes.spaceMedium16),

          // Amount Breakdown
          Container(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Column(
              children: [
                _buildAmountRow('Service Price', booking.servicePrice),
                if (booking.serviceCharges > 0)
                  _buildAmountRow('Service Charges', booking.serviceCharges),
                if (booking.taxAmount > 0)
                  _buildAmountRow('Tax (${booking.tax}%)', booking.taxAmount),
                if (booking.discountAmount > 0)
                  _buildAmountRow('Discount', -booking.discountAmount, isNegative: true),
                if (booking.tip > 0)
                  _buildAmountRow('Tip', booking.tip),
                if (booking.productsTotal > 0)
                  _buildAmountRow('Products', booking.productsTotal),
                SizedBox(height: AppSizes.spaceSmall8),
                Divider(color: Colors.grey[300]),
                SizedBox(height: AppSizes.spaceSmall8),
                _buildAmountRow(
                  'Total Amount',
                  booking.totalAmount,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.height(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${amount.abs().toStringAsFixed(2)} ${AppStrings.appCurreny}',
            style: TextStyle(
              fontSize: isTotal ? AppSizes.textMedium14 : AppSizes.textSmall12,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppColors.primaryGold : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(Booking booking) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.width(16)),
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
                size: AppSizes.icon(20),
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
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
          SizedBox(height: AppSizes.spaceSmall8),
          Container(
            padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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

  Widget _buildTimeline(Booking booking) {
    final timelineItems = [
      {
        'title': 'Booking Created',
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt),
        'icon': Icons.event_note,
        'color': Colors.blue,
      },
      if (booking.updatedAt != booking.createdAt)
        {
          'title': 'Last Updated',
          'time': DateFormat('dd MMM yyyy, hh:mm a').format(booking.updatedAt),
          'icon': Icons.update,
          'color': Colors.orange,
        },
    ];

    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          ...timelineItems.map((item) => _buildTimelineItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.height(8)),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(36),
            height: AppSizes.height(36),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'],
              size: AppSizes.icon(18),
              color: item['color'],
            ),
          ),
          SizedBox(width: AppSizes.width(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  item['time'],
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
    );
  }

  Widget _buildAdminBottomSheet() {
    return Obx(() {
      final booking = _booking.value;
      if (booking == null) return const SizedBox();

      return Container(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (booking.isPending)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showStatusUpdateDialog,
                  icon: Icon(Icons.check_circle_outline, size: AppSizes.icon(20)),
                  label: Text('Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                  ),
                ),
              ),
            if (booking.isPending) SizedBox(width: AppSizes.width(12)),
            if (booking.isConfirmed)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _controller.startBooking(booking.id),
                  icon: Icon(Icons.play_arrow_outlined, size: AppSizes.icon(20)),
                  label: Text('Start Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                  ),
                ),
              ),
            if (booking.isInProgress) SizedBox(width: AppSizes.width(12)),
            if (booking.isInProgress)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _controller.completeBooking(booking.id),
                  icon: Icon(Icons.check_circle, size: AppSizes.icon(20)),
                  label: Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                  ),
                ),
              ),
            if (!booking.isCancelled && !booking.isCompleted) SizedBox(width: AppSizes.width(12)),
            if (!booking.isCancelled && !booking.isCompleted)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _controller.cancelBooking(booking.id),
                  icon: Icon(Icons.cancel_outlined, size: AppSizes.icon(20)),
                  label: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.width(100),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: AppSizes.spaceMedium16),
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

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconLarge60,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'Booking not found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceMedium16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
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
        ],
      ),
    );
  }
}