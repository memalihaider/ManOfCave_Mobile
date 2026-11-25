// screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/booking_controller.dart';
import '../controlers/order_controller.dart';
import '../models/booking_model.dart';
import '../models/order_model.dart';
import '../widgets/shimmer_loading.dart';
import 'all_product_screen.dart';
import 'all_services_screen.dart';
import 'booking_details_screen.dart';
import 'order_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingController _bookingController = Get.find<BookingController>();
  final OrderController _orderController = Get.find<OrderController>();

  final RxString _selectedTab = 'services'.obs;
  final RxString _selectedStatus = 'all'.obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _bookingController.loadUserBookings();
    await _orderController.loadUserOrders();
  }

  // Filter service bookings
  List<Booking> getFilteredServiceBookings() {
    List<Booking> bookings = _bookingController.userBookings;

    // Filter by status
    if (_selectedStatus.value != 'all') {
      bookings = bookings.where((booking) => booking.status == _selectedStatus.value).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      bookings = bookings.where((booking) =>
      booking.bookingNumber.toLowerCase().contains(query) ||
          booking.serviceName.toLowerCase().contains(query) ||
          booking.staffName.toLowerCase().contains(query)
      ).toList();
    }

    return bookings;
  }

  // Filter product orders
  List<Order> getFilteredProductOrders() {
    List<Order> orders = _orderController.userOrders;

    // Filter by status
    if (_selectedStatus.value != 'all') {
      orders = orders.where((order) => order.status == _selectedStatus.value).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      orders = orders.where((order) =>
      order.transactionId.toLowerCase().contains(query) ||
          order.products.any((product) =>
              product.productName.toLowerCase().contains(query)
          )
      ).toList();
    }

    return orders;
  }

  void _showCancelDialog(Booking booking) {
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
          'Are you sure you want to cancel booking ${booking.bookingNumber}?',
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
              await _bookingController.cancelBooking(booking.id);
              Get.back();
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

  void _showCancelOrderDialog(Order order) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        ),
        title: Text(
          'Cancel Order',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel order ${order.transactionId}?',
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
              await _orderController.cancelOrder(order.id);
              Get.back();
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

  Widget _buildServiceBookingCard(Booking booking) {
    return Container(
      margin: AppSizes.paddingAll(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
            offset: Offset(0, AppSizes.height(2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          onTap: () {
            Get.to(() => BookingDetailScreen(bookingId: booking.id));
          },
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.spaceSmall8,
                      ),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        border: Border.all(color: booking.statusColor),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          fontWeight: FontWeight.w600,
                          color: booking.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8,),
                // Booking details - Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Text(
                      booking.formattedDate,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Icon(
                      Icons.access_time_outlined,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Text(
                      booking.formattedTime,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppSizes.spaceSmall8,),

                // Staff name
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Expanded(
                      child: Text(
                        'Staff: ${booking.staffName}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8,),

                // Branch
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Expanded(
                      child: Text(
                        'Branch: ${booking.branch}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8,),

                Divider(color: Colors.grey[200], height: AppSizes.height(1)),

                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #${booking.bookingNumber}',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '${booking.totalAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),

                    // Actions
                    if (booking.isPending || booking.isConfirmed)
                      IconButton(
                        onPressed: () => _showCancelDialog(booking),
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: AppSizes.iconMedium24,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: AppSizes.width(40),
                          minHeight: AppSizes.height(40),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductOrderCard(Order order) {
    return Container(
      margin: AppSizes.paddingOnly(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
            offset: Offset(0, AppSizes.height(2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          onTap: () {
            Get.to(() => OrderDetailScreen(orderId: order.id));
          },
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.transactionId}',
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.spaceSmall8,
                      ),
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        border: Border.all(color: _getOrderStatusColor(order.status)),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          fontWeight: FontWeight.w600,
                          color: _getOrderStatusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8,),

                // Order details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Text(
                      '${order.orderDate}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Icon(
                      Icons.local_shipping_outlined,
                      size: AppSizes.iconSmall18,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Expanded(
                      child: Text(
                        'Delivery: ${order.expectedDeliveryDate}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppSizes.spaceSmall8,),

                // Products summary
                Text(
                  'Items: ${order.totalItems} products',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8,),

                Text(
                  order.products.take(2).map((p) => p.productName).join(', '),
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (order.products.length > 2)
                  Text(
                    '+ ${order.products.length - 2} more',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[500],
                    ),
                  ),
                SizedBox(height: AppSizes.spaceSmall8,),

                Divider(color: Colors.grey[200], height: AppSizes.height(1)),

                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment: ${order.paymentMethod} (${order.paymentStatus})',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '${order.totalAmount.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),

                    // Actions
                    if (order.isPending)
                      IconButton(
                        onPressed: () => _showCancelOrderDialog(order),
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: AppSizes.iconMedium24,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: AppSizes.width(40),
                          minHeight: AppSizes.height(40),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'approved':
      case 'confirmed':
      case 'pending':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'closed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldSoft,
        foregroundColor: AppColors.textInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: canPop,
        title: Text(
          'Bookings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textInk,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              if (_selectedTab.value == 'services') {
                _bookingController.refreshBookings();
              } else {
                _orderController.refreshOrders();
              }
            },
            icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
        
            // Main Tabs
            _buildMainTabs(),
        
            // Status Filter
            Obx(() => _buildStatusFilter()),
        
            // Content
            Obx(() {
              if (_selectedTab.value == 'services') {
                return _buildServiceBookingsList();
              } else {
                return _buildProductOrdersList();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      color: AppColors.scaffoldSoft,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8E4DE)),
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            Icon(
              Icons.search_rounded,
              size: 22.sp,
              color: AppColors.textMuted,
            ),
            SizedBox(width: AppSizes.spaceSmall8,),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by booking/order number...',
                  hintStyle: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.clear,
                  size: AppSizes.iconMedium24,
                  color: Colors.grey[500],
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: AppSizes.width(40),
                  minHeight: AppSizes.height(40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: AppSizes.height(1)),
        ),
      ),
      child: Obx(() {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _selectedTab.value = 'services';
                  _selectedStatus.value = 'all';
                },
                child: Container(
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab.value == 'services'
                            ? AppColors.primaryGold
                            : Colors.transparent,
                        width: AppSizes.height(3),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconMedium24,
                        color: _selectedTab.value == 'services'
                            ? AppColors.primaryGold
                            : Colors.grey[400],
                      ),
                      SizedBox(height: AppSizes.spaceSmall8,),
                      Text(
                        'Service Bookings',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab.value == 'services'
                              ? AppColors.primaryDark
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _selectedTab.value = 'products';
                  _selectedStatus.value = 'all';
                },
                child: Container(
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab.value == 'products'
                            ? AppColors.primaryGold
                            : Colors.transparent,
                        width: AppSizes.height(3),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: AppSizes.iconMedium24,
                        color: _selectedTab.value == 'products'
                            ? AppColors.primaryGold
                            : Colors.grey[400],
                      ),
                      SizedBox(height: AppSizes.spaceSmall8,),
                      Text(
                        'Product Orders',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab.value == 'products'
                              ? AppColors.primaryDark
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusFilter() {
    final statusOptions = [
      'all',
      'upcoming',
      'in-progress',
      'closed',
      'cancelled',
    ];

    final statusLabels = {
      'all': 'All',
      'upcoming': 'Upcoming',
      'in-progress': 'Check-in',
      'closed': 'Closed',
      'cancelled': 'Cancelled',
    };

    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceSmall8,
        vertical: AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusOptions.map((status) {
            return Padding(
              padding: EdgeInsets.only(right: AppSizes.spaceSmall8),
              child: ChoiceChip(
                label: Text(
                  statusLabels[status]!,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: _selectedStatus.value == status
                        ? AppColors.white
                        : Colors.grey[600],
                  ),
                ),
                selected: _selectedStatus.value == status,
                selectedColor: AppColors.primaryGold,
                backgroundColor: Colors.grey[100],
                onSelected: (selected) {
                  _selectedStatus.value = selected ? status : 'all';
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                  side: BorderSide(
                    color: _selectedStatus.value == status
                        ? AppColors.primaryGold
                        : Colors.grey[300]!,
                  ),
                ),
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceBookingsList() {
    final bookings = getFilteredServiceBookings();

    if (_bookingController.isLoading) {
      return ShimmerLoading(
        child: Column(
          children: List.generate(3, (index) => Padding(
            padding: AppSizes.paddingAll(12),
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          )),
        ),
      );
    }

    if (bookings.isEmpty) {
      if (_bookingController.userBookings.isNotEmpty &&
          (_selectedStatus.value != 'all' || _searchController.text.isNotEmpty)) {
        return _buildFilteredEmptyState(
          icon: Icons.filter_alt_outlined,
          title: 'No matching bookings',
          message: 'Try changing your filters or search',
          buttonText: 'Clear Filters',
          onPressed: () {
            _selectedStatus.value = 'all';
            _searchController.clear();
            setState(() {});
          },
        );
      } else {
        return _buildEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'No Service Bookings',
          message: 'You haven\'t booked any services yet',
          buttonText: 'Book a Service',
          onPressed: () => Get.offAll(
              ()=>AllServicesScreen(),
            transition: Transition.rightToLeft,
            duration: Duration(milliseconds: 1000)
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _bookingController.loadUserBookings();
      },
      color: AppColors.primaryGold,
      child:  Column(
        children: [
          ...bookings.map((booking) => _buildServiceBookingCard(booking)).toList(),
          SizedBox(height: AppSizes.spaceMedium16),
        ],
      ),
    );
  }

  Widget _buildProductOrdersList() {
    final orders = getFilteredProductOrders();

    if (_orderController.isLoading && orders.isEmpty) {
      return ShimmerLoading(
        child: Column(
          children: List.generate(3, (index) => Padding(
            padding: AppSizes.paddingAll(12),
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          )),
        ),
      );
    }

    if (orders.isEmpty) {
      // Check if there are orders but filtered out
      if (_orderController.userOrders.isNotEmpty &&
          (_selectedStatus.value != 'all' || _searchController.text.isNotEmpty)) {
        return _buildFilteredEmptyState(
          icon: Icons.filter_alt_outlined,
          title: 'No matching orders',
          message: 'Try changing your filters or search',
          buttonText: 'Clear Filters',
          onPressed: () {
            _selectedStatus.value = 'all';
            _searchController.clear();
            setState(() {});
          },
        );
      } else {
        return _buildEmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'No Product Orders',
          message: 'You haven\'t ordered any products yet',
          buttonText: 'Browse Products',
          onPressed: () => Get.offAll(
                  ()=>AllProductsScreen(),
              transition: Transition.rightToLeft,
              duration: Duration(milliseconds: 1000)
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _orderController.loadUserOrders();
      },
      color: AppColors.primaryGold,
      child:  Column(
        children: [
          ...orders.map((order) => _buildProductOrderCard(order)).toList(),
          SizedBox(height: AppSizes.spaceMedium16),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAll(AppSizes.spaceLarge24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSizes.width(100),
              height: AppSizes.height(100),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconLarge32,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceLarge24,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAll(AppSizes.spaceLarge24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSizes.width(120),
              height: AppSizes.height(120),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconLarge60,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8,),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceLarge24,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}