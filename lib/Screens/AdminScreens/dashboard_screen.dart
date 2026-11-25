import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/Screens/AdminScreens/profile_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/admin_booking_controller.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/branches_controller.dart';
import '../../controlers/chat_controller.dart';
import '../../controlers/dashboard_controller.dart';
import '../../controlers/product_controller.dart';
import '../../controlers/service_controller.dart';
import '../../controlers/staff_controller.dart';
import '../../models/booking_model.dart';
import '../../models/staff.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/drawer.dart';
import '../all_category_screen.dart';
import '../all_product_screen.dart';
import '../all_services_screen.dart';
import '../chats/chat_list_screen.dart';
import '../chats/new_chat_screens.dart';
import '../notification_screen.dart';
import 'admin_booking_details_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_branches_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_staff_card.dart';
import 'admin_staff_screen.dart';
import 'customer_loayalty_screen.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final AdminBookingController bookingsController = Get.put(AdminBookingController());
  final StaffController staffController = Get.find<StaffController>();
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();
  final ProductController productController = Get.find<ProductController>();
  final ServiceController serviceController = Get.find<ServiceController>();

  String get userRole => authController.currentUser.value?.role ?? 'customer';
  String? get userBranchId => authController.currentUser.value?.branchId;
  String? get userBranchName => authController.currentUser.value?.branchName;
  bool get isBranchAdmin => userRole == 'admin' || userRole == 'branch_admin';
  bool get isSuperAdmin => userRole == 'super_admin';

  T? firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final element in list) {
      if (test(element)) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Admin catalog loads on dashboard open, not at app cold start.
    staffController.ensureLoaded();
    chatController.ensureListening();
    if (productController.products.isEmpty && !productController.isLoading) {
      productController.loadProducts();
    }
    if (serviceController.services.isEmpty && !serviceController.isLoading) {
      serviceController.loadServices();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isSuperAdmin ? "Super Admin Dashboard"
                  : isBranchAdmin ? "Branch Admin Dashboard"
                  : "Dashboard",
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppSizes.textExtraLarge22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isBranchAdmin && userBranchName != null)
              Text(
                userBranchName!,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: AppSizes.textSmall12,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: AppSizes.iconMedium24),
            onPressed: () {
              Get.to(() => NotificationsScreen());
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.person, size: AppSizes.iconMedium24),
            onPressed: () {
              Get.to(() => ProfileScreenAdmin());
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                isSuperAdmin ? "Welcome Back, Super Admin!"
                    : isBranchAdmin ? "Welcome, Branch Manager!"
                    : "Welcome Back!",
                style: TextStyle(
                  fontSize: AppSizes.textExtraLarge22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                isSuperAdmin ? "Here's what's happening across all branches"
                    : isBranchAdmin ? "Managing branch: ${userBranchName ?? 'Your Branch'}"
                    : "Your dashboard overview",
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),

              // Stats Cards - Top Row
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.width(2),
                mainAxisSpacing: AppSizes.height(2),
                childAspectRatio: 1.2,
                children: [
                  Obx(() => DashboardCard(
                    title: "Total Bookings",
                    value: _getTotalBookingsCount(),
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  )),
                  Obx(() => DashboardCard(
                    title: "Pending Bookings",
                    value: _getPendingBookingsCount(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    onTap: () {
                      Get.to(() => AdminBookingsScreen());
                      bookingsController.changeFilter('pending');
                    },
                  )),
                  Obx(() => DashboardCard(
                    title: "Today's Bookings",
                    value: bookingsController.getTodaysBookings().length.toString(),
                    icon: Icons.today,
                    color: Colors.green,
                  )),
                  Obx(() => DashboardCard(
                    title: "Today's Revenue",
                    value: _getTodayRevenue(),
                    icon: Icons.attach_money,
                    color: Colors.purple,
                  )),
                ],
              ),

              SizedBox(height: AppSizes.spaceMedium16),

              // Quick Actions
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8),

              Wrap(
                spacing: AppSizes.spaceLarge24,
                runSpacing: AppSizes.spaceMedium16,
                children: [
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.shopping_bag,
                      label: "Products",
                      color: Colors.blueAccent,
                      onTap: ()=> _navigateToProducts()
                    ),
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.medical_services,
                      label: "Services",
                      color: Colors.teal,
                      onTap: () => _navigateToServices(),
                    ),
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.group,
                      label: "Customers",
                      color: Colors.indigo,
                      onTap: () => Get.to(() => AdminCustomersScreen()),
                    ),
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.people,
                      label: "Staff",
                      color: Colors.green,
                      onTap: () => Get.to(() => AdminStaffScreen()),
                    ),
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.calendar_today,
                      label: "Bookings",
                      color: Colors.blue,
                      onTap: () => Get.to(() => AdminBookingsScreen()),
                    ),
                  // In your quick action widget
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.calendar_today,
                      label: "Categories",
                      color: Colors.blue,
                      onTap: () {
                        if (isBranchAdmin) {
                          // For branch admin - pass their branch
                          final branchController = Get.find<BranchController>();
                          final branch = firstWhereOrNull(
                              branchController.branches,
                                  (b) => b.name == userBranchName
                          );


                          if (branch != null) {
                            Get.to(() => AllCategoriesScreen(selectedBranch: branch));
                          } else {
                            Get.snackbar(
                              'Error',
                              'Branch not found',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        } else {
                          // For super admin - go to all categories (no filter)
                          Get.to(() => AllCategoriesScreen());
                        }
                      },
                    ),
                  if (isSuperAdmin || isBranchAdmin)
                    _buildQuickAction(
                      icon: Icons.pending_actions,
                      label: "Pending",
                      color: Colors.orange,
                      onTap: () {
                        Get.to(() => AdminBookingsScreen());
                        bookingsController.changeFilter('pending');
                      },
                    ),
                  // if (isSuperAdmin)
                  //   _buildQuickAction(
                  //     icon: Icons.assessment,
                  //     label: "Reports",
                  //     color: Colors.purple,
                  //     onTap: () => Get.to(() => CustomerLoyaltyScreen()),
                  //   ),
                  if (isSuperAdmin)
                    _buildQuickAction(
                      icon: Icons.store,
                      label: "Branches",
                      color: Colors.indigo,
                      onTap: () => Get.to(() => AdminBranchesScreen()),
                    ),
                ],
              ),

              SizedBox(height: AppSizes.spaceMedium16),

              // Today's Bookings Section
              _buildTodaysBookings(),

              SizedBox(height: AppSizes.spaceMedium16),

              // Active Staff Section
              _buildActiveStaff(),

              SizedBox(height: AppSizes.spaceLarge24),
            ],
          ),
        ),
      ),
      floatingActionButton: GetBuilder<ChatController>(
        builder: (chatController) {
          return FloatingActionButton(
            backgroundColor: AppColors.primaryGold,
            onPressed: () {
              if (!chatController.isAuthenticated) {
                Get.snackbar(
                  'Authentication Required',
                  'Please login to access chat',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              if (chatController.isCustomer) {
                Get.to(() => const NewChatScreen());
              } else {
                Get.to(() => const ChatListScreen());
              }
            },
            tooltip: chatController.isAuthenticated ? 'Chat Support' : 'Login Required',
            child: Stack(
              children: [
                const Icon(Icons.chat, color: Colors.white),
                if (chatController.totalUnreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: AppSizes.width(16),
                        minHeight: AppSizes.height(16),
                      ),
                      child: Center(
                        child: Text(
                          chatController.totalUnreadCount > 99 ? '99+' : '${chatController.totalUnreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTotalBookingsCount() {
    if (isSuperAdmin) {
      return bookingsController.allBookings.length.toString();
    } else if (isBranchAdmin && userBranchId != null) {
      return bookingsController.branchBookings.length.toString();
    }
    return "0";
  }

  String _getPendingBookingsCount() {
    if (isSuperAdmin) {
      return bookingsController.pendingCount.toString();
    } else if (isBranchAdmin && userBranchId != null) {
      final branchPendingBookings = bookingsController.allBookings
          .where((booking) => booking.isPending &&
          (booking.branch == userBranchName))
          .length;
      return branchPendingBookings.toString();
    }
    return "0";
  }

  String _getTodayRevenue() {
    double calculateRevenue(List<Booking> bookings) {
      return bookings.fold(0.0, (sum, b) => sum + b.totalAmount);
    }

    final todayBookings = bookingsController.getTodaysBookings()
        .where((booking) => booking.isCompleted || booking.isConfirmed);
    final revenue = calculateRevenue(todayBookings.toList());
    return "${revenue.toStringAsFixed(0)} ${AppStrings.appCurreny}";
  }

  List<Booking> _getFilteredTodayBookings() {
    if (isSuperAdmin) {
      return bookingsController.getTodaysBookings();
    } else if (isBranchAdmin && userBranchId != null) {
      return bookingsController.allBookings
          .where((booking) => booking.isToday &&
          (booking.branchId == userBranchId ||
              booking.userBranchId == userBranchId))
          .toList();
    }
    return [];
  }

  List<Staff> _getFilteredStaff() {
    if (isSuperAdmin) {
      return staffController.activeStaff;
    } else if (isBranchAdmin && userBranchName != null) {
      return staffController.activeStaff
          .where((staff) => staff.branch.toLowerCase() == userBranchName!.toLowerCase())
          .toList();
    }
    return [];
  }

  Widget _buildTodaysBookings() {
    return Obx(() {
      final filteredBookings = _getFilteredTodayBookings();
      final todaysBookings = filteredBookings.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Bookings",
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              if (filteredBookings.isNotEmpty)
                TextButton(
                  onPressed: () => Get.to(() => AdminBookingsScreen()),
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.textSmall12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          if (todaysBookings.isEmpty)
            _buildEmptyState(
              icon: Icons.calendar_today,
              title: "No bookings today",
              message: isBranchAdmin
                  ? "No bookings scheduled for your branch today"
                  : "All bookings are completed for today",
            )
          else
            Column(
              children: todaysBookings.map((booking) => _buildBookingCard(booking)).toList(),
            ),
        ],
      );
    });
  }

  Widget _buildActiveStaff() {
    return Obx(() {
      final filteredStaff = _getFilteredStaff();
      final activeStaff = filteredStaff.take(3).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Staff",
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              if (filteredStaff.isNotEmpty)
                TextButton(
                  onPressed: () => Get.to(() => AdminStaffScreen()),
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.textSmall12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          if (activeStaff.isEmpty)
            _buildEmptyState(
              icon: Icons.people,
              title: "No active staff",
              message: isBranchAdmin
                  ? "No staff assigned to your branch"
                  : "Add staff members to get started",
            )
          else
            Column(
              children: StaffCard.createStaffCards(
                staffList: activeStaff,
                onTap: () => Get.to(() => AdminStaffScreen()),
                showStatus: true,
                showBranch: true,
                compact: true,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.width(100),
        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSizes.iconMedium24),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProducts() {
    final user = authController.currentUser.value;
    if (user != null) {
      productController.setUserRole(
        user.role,
        branchId: user.branchId,
        branchName: user.branchName,
      );
    }
    Get.to(() => AllProductsScreen());
  }
  
  void _navigateToServices() {
    final user = authController.currentUser.value;
    if (user != null) {
      serviceController.setUserRole(
        user.role,
        branchId: user.branchId,
        branchName: user.branchName,
      );
    }
    Get.to(() => AllServicesScreen());
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: AppSizes.paddingOnly(bottom: AppSizes.spaceSmall8),
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
      child: ListTile(
        contentPadding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        leading: Container(
          width: AppSizes.width(48),
          height: AppSizes.height(48),
          decoration: BoxDecoration(
            color: booking.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Icon(
            booking.statusIcon,
            size: AppSizes.iconMedium24,
            color: booking.statusColor,
          ),
        ),
        title: Text(
          booking.customerName,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.serviceName,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              '${booking.formattedTime} • ${booking.staffName}',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: AppSizes.paddingAll(2),
              decoration: BoxDecoration(
                color: booking.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
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
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              booking.formatCurrency(booking.totalAmount),
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
          ],
        ),
        onTap: () {
          Get.to(()=>AdminBookingDetailScreen(bookingId: booking.id));
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppSizes.iconLarge60,
            color: Colors.grey[300],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            message,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}