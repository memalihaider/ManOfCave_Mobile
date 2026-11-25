// screens/admin_order_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/order_model.dart';
import '../../widgets/payment_update_dialogue.dart';
import '../../widgets/status_update_dialogue.dart';
import 'admin_order_controller.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isAdmin;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
    this.isAdmin = true,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final AdminOrderController _controller = Get.find<AdminOrderController>();
  final Rx<Order?> _order = Rx<Order?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isProcessing = false.obs;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      _isLoading.value = true;
      final order = await _getOrderById(widget.orderId);
      _order.value = order;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load order details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Order?> _getOrderById(String id) async {
    // Try to find in controller first
    for (final order in _controller.allOrders) {
      if (order.id == id) return order;
    }

    // If not found, fetch from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .get();

      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching order: $e');
    }
    return null;
  }

  void _showStatusUpdateDialog() {
    if (_order.value == null) return;

    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        booking: null,
        order: _order.value,
        onStatusUpdate: (status, notes) async {
          final result = await _controller.updateOrderStatus(
            widget.orderId,
            status,
          );
          if (result) {
            await _loadOrderDetails();
            Get.snackbar(
              'Success',
              'Order status updated to $status',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
        },
      ),
    );
  }

  void _showPaymentUpdateDialog() {
    if (_order.value == null) return;

    showDialog(
      context: context,
      builder: (context) => PaymentUpdateDialog(
        booking: null,
        order: _order.value,
        onPaymentUpdate: (paymentStatus, paymentMethod, trnNumber) async {
          final result = await _controller.updatePaymentStatus(
            widget.orderId,
            paymentStatus,
          );
          if (result) {
            await _loadOrderDetails();
            Get.snackbar(
              'Success',
              'Payment status updated to $paymentStatus',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
        },
      ),
    );
  }

  void _markAsShipped() async {
    if (_order.value == null) return;

    _isProcessing.value = true;
    try {
      final result = await _controller.updateOrderStatus(widget.orderId, 'shipped');
      if (result) {
        await _loadOrderDetails();
        Get.snackbar(
          'Order Shipped',
          'Order marked as shipped',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } finally {
      _isProcessing.value = false;
    }
  }

  void _markAsDelivered() async {
    if (_order.value == null) return;

    _isProcessing.value = true;
    try {
      final result = await _controller.updateOrderStatus(widget.orderId, 'delivered');
      if (result) {
        await _loadOrderDetails();
        Get.snackbar(
          'Order Delivered',
          'Order marked as delivered',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } finally {
      _isProcessing.value = false;
    }
  }

  void _sendPickupNotification() {
    if (_order.value == null) return;

    Get.snackbar(
      'Notification Sent',
      'Pickup notification sent to ${_order.value!.customerEmail}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _viewCustomerProfile() {
    if (_order.value == null) return;

    Get.toNamed('/admin/customer/${_order.value!.customerId}');
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
          _order.value?.transactionId ?? 'Order Details',
          style: TextStyle(
            fontSize: 18.sp,
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
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return _buildLoadingState();
        }

        if (_order.value == null) {
          return _buildNotFoundState();
        }

        final order = _order.value!;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Status Banner with Actions
              _buildStatusBanner(order),

              // Quick Action Buttons (Admin Only)
              if (widget.isAdmin) _buildActionButtons(order),

              // Order Summary
              _buildOrderSummary(order),

              // Customer Information
              _buildCustomerInfo(order),

              // Pickup Information (replaced Shipping Information)
              _buildPickupInfo(order),

              // Products List
              _buildProductsList(order),

              // Payment Information
              _buildPaymentInfo(order),

              // Notes Section
              if (order.orderNotes != null && order.orderNotes!.isNotEmpty)
                _buildNotesSection(order),

              // Timeline/History
              _buildTimeline(order),

              SizedBox(height: 100.h),
            ],
          ),
        );
      }),
      bottomSheet: widget.isAdmin ? _buildAdminBottomSheet() : null,
    );
  }

  Widget _buildStatusBanner(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Container(
      padding: EdgeInsets.all(16.w),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 30.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.textLarge18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getStatusDescription(order),
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: _getProgressValue(order.status),
                  backgroundColor: Colors.grey[300],
                  color: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(Order order) {
    switch (order.status) {
      case 'pending':
        return 'Order received, awaiting processing';
      case 'confirmed':
        return 'Order confirmed, preparing for pickup';
      case 'processing':
        return 'Order is being processed';
      case 'shipped':
        return 'Order ready for pickup';
      case 'delivered':
        return 'Order picked up successfully';
      case 'completed':
        return 'Order completed successfully';
      case 'cancelled':
        return 'Order cancelled';
      default:
        return 'Status unknown';
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.1;
      case 'confirmed':
        return 0.3;
      case 'processing':
        return 0.5;
      case 'shipped':
        return 0.8;
      case 'delivered':
      case 'completed':
        return 1.0;
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Widget _buildActionButtons(Order order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            Icons.edit,
            'Update Status',
            _showStatusUpdateDialog,
            Colors.blue,
          ),
          _buildActionButton(
            Icons.payment,
            'Payment',
            _showPaymentUpdateDialog,
            Colors.green,
          ),
          _buildActionButton(
            Icons.store,
            'Pickup',
            _sendPickupNotification,
            Colors.orange,
          ),
          _buildActionButton(
            Icons.email,
            'Notify',
            _sendPickupNotification,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(
      children: [
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 20.sp, color: color),
          ),
        ),
        SizedBox(height: 4.h),
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

  Widget _buildOrderSummary(Order order) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Order ID', order.transactionId),
          _buildDetailRow('Order Date', order.orderDate),
          _buildDetailRow('Expected Pickup', order.expectedDeliveryDate),
          _buildDetailRow('Total Items', '${order.totalItems} items'),
          _buildDetailRow('Total Products', '${order.products.length} products'),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Row(
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
                  'د.إ${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
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
                size: 20.sp,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 8.w),
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
          SizedBox(height: 12.h),
          _buildDetailRow('Name', order.customerName),
          _buildDetailRow('Email', order.customerEmail),
          _buildDetailRow('Phone', order.customerPhone),
          _buildDetailRow('Customer ID', order.customerId),
          if (widget.isAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _viewCustomerProfile,
                icon: Icon(Icons.person_search, size: 16.sp),
                label: Text('View Customer Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: BorderSide(color: AppColors.primaryGold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ NEW: Pickup Information Section (replaced Shipping Information)
  Widget _buildPickupInfo(Order order) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
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
                Icons.store_outlined,
                size: 20.sp,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 8.w),
              Text(
                'Pickup Information',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Pickup Branch', order.pickupBranch),
          _buildDetailRow('Address', order.pickupBranchAddress),
          _buildDetailRow('Phone', order.pickupBranchPhone),
          _buildDetailRow('Pickup Hours', order.pickupBranchTiming),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.blue,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Please collect your order from the selected branch during pickup hours',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(Order order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
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
                Icons.shopping_bag_outlined,
                size: 20.sp,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 8.w),
              Text(
                'Order Items (${order.totalItems})',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...order.products.map((product) => _buildProductItem(product)).toList(),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 8.h),
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
                'د.إ${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderProduct product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: product.productImage.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                product.productImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
              ),
            )
                : _buildProductPlaceholder(),
          ),
          SizedBox(width: 12.w),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  product.productCategory,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'Qty: ${product.quantity}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Price: د.إ${product.price.toStringAsFixed(2)}',
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

          // Total Price
          Text(
            'د.إ${product.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 24.sp,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildPaymentInfo(Order order) {
    final paymentStatusColor = _getPaymentStatusColor(order.paymentStatus);

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 20.sp,
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: 8.w),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: paymentStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: paymentStatusColor),
                ),
                child: Text(
                  order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: paymentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Payment Method', order.paymentMethod.toUpperCase()),
          _buildDetailRow('Amount', 'د.إ${order.totalAmount.toStringAsFixed(2)}'),
          SizedBox(height: 8.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit Margin',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'د.إ${order.totalProfit.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: order.totalProfit > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(Order order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
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
                size: 20.sp,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 8.w),
              Text(
                'Order Notes',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Text(
              order.orderNotes!,
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

  Widget _buildTimeline(Order order) {
    final timelineItems = [
      {
        'title': 'Order Created',
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
        'icon': Icons.event_note,
        'color': Colors.blue,
      },
      if (order.updatedAt != order.createdAt)
        {
          'title': 'Last Updated',
          'time': DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt),
          'icon': Icons.update,
          'color': Colors.orange,
        },
    ];

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ...timelineItems.map((item) => _buildTimelineItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'],
              size: 18.sp,
              color: item['color'],
            ),
          ),
          SizedBox(width: 12.w),
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
      final order = _order.value;
      if (order == null) return const SizedBox();

      return Container(
        padding: EdgeInsets.all(16.w),
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
            if (order.isPending)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showStatusUpdateDialog,
                  icon: Icon(Icons.check_circle_outline, size: 20.sp),
                  label: Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (order.isPending || order.isCompleted) SizedBox(width: 12.w),
            if (order.isPending || order.isCompleted)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markAsShipped,
                  icon: Icon(Icons.local_shipping, size: 20.sp),
                  label: Text('Ready for Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (order.status == 'shipped') SizedBox(width: 12.w),
            if (order.status == 'shipped')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markAsDelivered,
                  icon: Icon(Icons.done_all, size: 20.sp),
                  label: Text('Mark as Picked Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (!order.isCancelled && !order.isCompleted) SizedBox(width: 12.w),
            if (!order.isCancelled && !order.isCompleted)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showStatusUpdateDialog,
                  icon: Icon(Icons.cancel_outlined, size: 20.sp),
                  label: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
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
          SizedBox(height: 16.h),
          Text(
            'Loading order details...',
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
          Icon(Icons.error_outline, size: 60.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'The order you are looking for does not exist',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // Helper methods for order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.blueAccent;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.rotate_right;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}