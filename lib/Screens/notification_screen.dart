import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/notification_controller.dart';
import '../models/notification_model.dart';
import '../widgets/empty_card.dart';
import '../widgets/notification_filter.dart';
import '../widgets/notification_item_card.dart';
import '../widgets/shimmer_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _controller = Get.find<NotificationController>();
  final ScrollController _scrollController = ScrollController();

  final Map<String, IconData> _filterIcons = {
    'all': Icons.all_inbox,
    'unread': Icons.markunread,
    'booking': Icons.calendar_today,
    'payment': Icons.payment,
    'offer': Icons.local_offer,
    'order': Icons.shopping_bag,
    'loyalty': Icons.stars,
    'system': Icons.system_update,
  };

  RxString _selectedFilter = 'all'.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // Load more if pagination needed
    }
  }

  void _applyFilter(String filter) {
    _selectedFilter.value = filter;
  }

  List<NotificationItem> _getFilteredNotifications() {
    switch (_selectedFilter.value) {
      case 'unread':
        return _controller.notifications.where((n) => !n.isRead).toList();
      case 'booking':
        return _controller.notifications
            .where((n) => n.type == NotificationType.booking)
            .toList();
      case 'payment':
        return _controller.notifications
            .where((n) => n.type == NotificationType.payment)
            .toList();
      case 'offer':
        return _controller.notifications
            .where((n) => n.type == NotificationType.offer)
            .toList();
      case 'order':
        return _controller.notifications
            .where((n) => n.type == NotificationType.order)
            .toList();
      case 'loyalty':
        return _controller.notifications
            .where((n) => n.type == NotificationType.loyalty)
            .toList();
      case 'system':
        return _controller.notifications
            .where((n) => n.type == NotificationType.system)
            .toList();
      default:
        return _controller.notifications.toList();
    }
  }

  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        ),
        title: Text(
          'Clear All Notifications',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Clear All',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.notifications.isEmpty) {
          return _buildLoadingState();
        }

        final filteredNotifications = _getFilteredNotifications();

        return Column(
          children: [
            // Filter Chips
            _buildFilterSection(),

            // Notifications List
            Expanded(
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(filteredNotifications),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        return _controller.unreadCount.value > 0
            ? FloatingActionButton.extended(
          onPressed: _controller.markAllAsRead,
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.white,
          icon: Icon(
            Icons.mark_email_read,
            size: AppSizes.iconMedium24,
          ),
          label: Text(
            'Mark all read',
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
        )
            : const SizedBox.shrink();
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.white,
      elevation: 0,
      title: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            Text(
              '${_controller.unreadCount.value} unread • ${_controller.notifications.length} total',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
          ],
        );
      }),
      centerTitle: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          size: AppSizes.iconMedium24,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (_controller.notifications.isNotEmpty)
          IconButton(
            onPressed: _showClearAllDialog,
            icon: Icon(
              Icons.delete_outline,
              size: AppSizes.iconMedium24,
              color: AppColors.white,
            ),
          ),
        IconButton(
          onPressed: _controller.loadNotifications,
          icon: Icon(
            Icons.refresh,
            size: AppSizes.iconMedium24,
            color: AppColors.white,
          ),
        ),
        SizedBox(width: AppSizes.spaceSmall8,),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceSmall8,
        vertical: AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          return Row(
            children: [
              NotificationFilterChip(
                label: 'All',
                count: _controller.notifications.length,
                isSelected: _selectedFilter.value == 'all',
                icon: _filterIcons['all']!,
                onTap: () => _applyFilter('all'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Unread',
                count: _controller.unreadCount.value,
                isSelected: _selectedFilter.value == 'unread',
                icon: _filterIcons['unread']!,
                onTap: () => _applyFilter('unread'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Bookings',
                count: _controller.getCountByType(NotificationType.booking),
                isSelected: _selectedFilter.value == 'booking',
                icon: _filterIcons['booking']!,
                onTap: () => _applyFilter('booking'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Payments',
                count: _controller.getCountByType(NotificationType.payment),
                isSelected: _selectedFilter.value == 'payment',
                icon: _filterIcons['payment']!,
                onTap: () => _applyFilter('payment'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Offers',
                count: _controller.getCountByType(NotificationType.offer),
                isSelected: _selectedFilter.value == 'offer',
                icon: _filterIcons['offer']!,
                onTap: () => _applyFilter('offer'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Orders',
                count: _controller.getCountByType(NotificationType.order),
                isSelected: _selectedFilter.value == 'order',
                icon: _filterIcons['order']!,
                onTap: () => _applyFilter('order'),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              NotificationFilterChip(
                label: 'Loyalty',
                count: _controller.getCountByType(NotificationType.loyalty),
                isSelected: _selectedFilter.value == 'loyalty',
                icon: _filterIcons['loyalty']!,
                onTap: () => _applyFilter('loyalty'),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    return RefreshIndicator(
      backgroundColor: AppColors.white,
      color: AppColors.primaryGold,
      onRefresh: () async {
        _controller.loadNotifications();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
            child: NotificationItemCard(
              notification: notification,
              onTap: () {
                if (!notification.isRead) {
                  _controller.markAsRead(notification.id);
                }
                // Handle navigation based on notification data
                if (notification.actionUrl != null) {
                  Get.toNamed(notification.actionUrl!);
                } else if (notification.data != null) {
                  _controller.handleNotificationTap(notification.data!);
                }
              },
              onDismiss: () {
                _controller.deleteNotification(notification.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'You\'re all caught up!';
    String actionText = 'Refresh';

    if (_selectedFilter.value != 'all') {
      message = 'No ${_selectedFilter.value} notifications found';
    }

    return EmptyStateWidget(
      title: 'No Notifications',
      description: message,
      icon: Icons.notifications_none_outlined,
      buttonText: actionText,
      onButtonPressed: _controller.loadNotifications,
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}