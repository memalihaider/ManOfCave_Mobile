// screens/admin_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/admin_booking_controller.dart';
import '../../models/booking_model.dart';
import '../../widgets/shimmer_loading.dart';
import 'admin_booking_details_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final AdminBookingController _controller = Get.find<AdminBookingController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _selectedDateFilter = 'all'.obs;
  final RxString _selectedBranchFilter = 'all'.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.setSearchQuery(_searchController.text);
  }


  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.textSmall12,
          color: selected ? AppColors.white : Colors.grey[600],
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryGold,
      backgroundColor: Colors.grey[100],
      checkmarkColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
      ),
    );
  }

  void _showStatusUpdateDialog(Booking booking) {
    Get.defaultDialog(
      title: 'Update Booking Status',
      titleStyle: TextStyle(
        fontSize: AppSizes.textLarge18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusOption(
            '📅 Upcoming',
            'upcoming',
            booking,
            Colors.green,
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          _buildStatusOption(
            '⏳ Check-in',
            'in-progress',
            booking,
            Colors.orange,
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          _buildStatusOption(
            '✓ Closed',
            'closed',
            booking,
            Colors.blue,
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          _buildStatusOption(
            '❌ Cancel',
            'cancelled',
            booking,
            Colors.red,
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          if (booking.isPending)
            Text(
              'Note: Confirming will notify the customer',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String status, Booking booking, Color color) {
    return ListTile(
      leading: Container(
        width: AppSizes.width(40),
        height: AppSizes.height(40),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        ),
        child: Center(
          child: Text(
            label.substring(0, 1),
            style: TextStyle(
              fontSize: AppSizes.iconSmall18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        label.substring(2),
        style: TextStyle(
          fontSize: AppSizes.textMedium14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      trailing: booking.status == status
          ? Icon(Icons.check_circle, color: Colors.green, size: AppSizes.iconSmall18)
          : null,
      onTap: () async {
        Get.back();
        final result = await _controller.updateBookingStatus(
          bookingId: booking.id,
          status: status,
          notes: 'Status updated to $status by admin',
        );
        if (result) {
          Get.snackbar(
            'Success',
            'Booking status updated',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      },
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
          'Bookings (${_controller.filteredBookings.length})',
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
            onPressed: _controller.refreshBookings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading && _controller.filteredBookings.isEmpty) {
          return _buildLoadingState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.refreshBookings();
          },
          color: AppColors.primaryGold,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),

              // Statistics Cards
              SliverToBoxAdapter(
                child: _buildStatisticsCards(),
              ),

              // Status Filter Chips
              SliverToBoxAdapter(
                child: _buildStatusFilter(),
              ),

              // Bookings List or Empty State
              if (_controller.filteredBookings.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final booking = _controller.filteredBookings[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < _controller.filteredBookings.length - 1
                              ? AppSizes.spaceSmall8
                              : 0),
                          child: _buildBookingCard(booking),
                        );
                      },
                      childCount: _controller.filteredBookings.length,
                    ),
                  ),
                ),

              // Bottom Spacing
              SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.spaceMedium16),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(width: AppSizes.width(16)),
            Icon(
              Icons.search,
              size: AppSizes.icon(20),
              color: Colors.grey[500],
            ),
            SizedBox(width: AppSizes.width(12)),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, booking #, service...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[500],
                  ),
                ),
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: Icon(
                  Icons.clear,
                  size: AppSizes.icon(20),
                  color: Colors.grey[500],
                ),
              ),
            SizedBox(width: AppSizes.width(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
              'Total',
              _controller.totalCount.toString()
          ),
          _buildStatCard(
              'Today',
              _controller.getTodaysBookings().length.toString()
          ),
          _buildStatCard(
              'Revenue',
              '${_controller.getRevenueBasedOnRole()} ${AppStrings.appCurreny}'
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSizes.width(4)),
        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.textLarge18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statusFilters = [
      {'value': 'all', 'label': 'All', 'color': Colors.grey},
      {'value': 'upcoming', 'label': 'Upcoming', 'color': Colors.orange},
      {'value': 'in-progress', 'label': 'Check-in', 'color': Colors.blue},
      {'value': 'closed', 'label': 'Closed', 'color': Colors.green},
      {'value': 'cancelled', 'label': 'Cancelled', 'color': Colors.red},
      {'value': 'cancelled', 'label': 'Cancelled', 'color': Colors.red},
    ];

    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: statusFilters.map((filter) {
            final isSelected = _controller.selectedFilter == filter['value'];
            return Padding(
              padding: EdgeInsets.only(right: AppSizes.width(8)),
              child: ChoiceChip(
                label: Text(
                  filter['label']!.toString(),
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: filter['color'] as Color,
                backgroundColor: Colors.grey[100],
                onSelected: (_) {
                  _controller.changeFilter(filter['value']!.toString());
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                  side: BorderSide(
                    color: isSelected ? filter['color'] as Color : Colors.grey[300]!,
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          onTap: () {
            Get.to(
                  () => AdminBookingDetailScreen(
                bookingId: booking.id,
                isAdmin: true,
              ),
            );
          },
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.customerName,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.height(4),
                      ),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        border: Border.all(color: booking.statusColor),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: AppSizes.font(10),
                          fontWeight: FontWeight.w600,
                          color: booking.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                // Service Details
                Row(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: AppSizes.icon(16),
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.width(6)),
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.height(4)),

                // Time and Staff
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: AppSizes.icon(16),
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.width(6)),
                    Text(
                      '${booking.formattedTime} • ${booking.durationFormatted}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: AppSizes.width(16)),
                    Icon(
                      Icons.person_outline,
                      size: AppSizes.icon(16),
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.width(6)),
                    Text(
                      booking.staffName,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.height(4)),

                // Date and Branch
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: AppSizes.icon(16),
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: AppSizes.width(6)),
                        Text(
                          booking.formattedDate,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: AppSizes.width(16)),
                   Row(
                     children: [
                       Icon(
                         Icons.location_on_outlined,
                         size: AppSizes.icon(16),
                         color: Colors.grey[500],
                       ),
                       SizedBox(width: AppSizes.width(6)),
                       Text(
                         booking.branch,
                         style: TextStyle(
                           fontSize: AppSizes.textSmall12,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                   )
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                Divider(color: Colors.grey[200]),

                // Footer with actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.bookingNumber,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          booking.formatCurrency(booking.totalAmount),
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),

                    // Quick Actions
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: AppSizes.icon(20),
                        color: Colors.grey[600],
                      ),
                      itemBuilder: (context) => [
                        if (booking.isPending)
                          PopupMenuItem(
                            value: 'confirm',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: AppSizes.iconSmall18),
                                SizedBox(width: AppSizes.width(8)),
                                Text('Confirm'),
                              ],
                            ),
                          ),
                        if (booking.isConfirmed)
                          PopupMenuItem(
                            value: 'start',
                            child: Row(
                              children: [
                                Icon(Icons.play_arrow_outlined, color: Colors.orange, size: AppSizes.iconSmall18),
                                SizedBox(width: AppSizes.width(8)),
                                Text('Start Service'),
                              ],
                            ),
                          ),
                        if (booking.isInProgress)
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue, size: AppSizes.iconSmall18),
                                SizedBox(width: AppSizes.width(8)),
                                Text('Mark Complete'),
                              ],
                            ),
                          ),
                        if (!booking.isCancelled && !booking.isCompleted)
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red, size: AppSizes.iconSmall18),
                                SizedBox(width: AppSizes.width(8)),
                                Text('Cancel'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: AppSizes.iconSmall18),
                              SizedBox(width: AppSizes.width(8)),
                              Text('View Details'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'confirm':
                            await _controller.approveBooking(booking.id);
                            break;
                          case 'start':
                            await _controller.startBooking(booking.id);
                            break;
                          case 'complete':
                            await _controller.completeBooking(booking.id);
                            break;
                          case 'cancel':
                            await _controller.cancelBooking(booking.id);
                            break;
                          case 'details':
                            Get.to(
                                  () => AdminBookingDetailScreen(
                                bookingId: booking.id,
                                isAdmin: true,
                              ),
                            );
                            break;
                        }
                      },
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

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
          child: Container(
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppSizes.width(120),
            height: AppSizes.height(120),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: AppSizes.icon(48),
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: AppSizes.spaceLarge24),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            'Try changing your filters',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: AppSizes.spaceLarge24),
          ElevatedButton(
            onPressed: () {
              _controller.changeFilter('all');
              _searchController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceExtraLarge32,
                vertical: AppSizes.spaceSmall8,
              ),
            ),
            child: Text(
              'Clear Filters',
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