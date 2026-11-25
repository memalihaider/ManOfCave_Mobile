import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/service_model.dart';
import '../controlers/service_controller.dart';
import '../controlers/auth_controller.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final bool showDeleteButton;

  ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.showDeleteButton = false,
  });

  // Get auth controller
  final AuthController _authController = Get.find<AuthController>();

  bool get isAdmin => _authController.isAdmin ||
      _authController.isSuperAdmin ||
      _authController.isBranchAdmin;

  @override
  Widget build(BuildContext context) {
    final serviceController = Get.find<ServiceController>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.width(156), // 40% of 390 = 156
        margin: EdgeInsets.only(right: AppSizes.width(7.8)), // 2% of 390 = 7.8
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with Status and Delete Button
            Stack(
              children: [
                Container(
                  height: AppSizes.height(97.5), // 25% of 390 height equivalent
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    image: service.imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(service.imageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: service.imageUrl.isEmpty
                      ? Center(
                    child: Icon(
                      Icons.spa_outlined,
                      size: AppSizes.icon(31.2), // 8% of 390
                      color: AppColors.primaryGold,
                    ),
                  )
                      : null,
                ),

                // Status badge — admin chrome only
                if (isAdmin)
                  Positioned(
                    top: AppSizes.height(3.9),
                    left: AppSizes.width(3.9),
                    child: Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.width(7.8),
                        vertical: AppSizes.height(1.95),
                      ),
                      decoration: BoxDecoration(
                        color: service.isActive
                            ? Colors.green.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                      ),
                      child: Text(
                        service.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: AppSizes.font(7.8),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Delete Button for Admins only (when showDeleteButton is true AND user is admin)
                if (showDeleteButton && isAdmin)
                  Positioned(
                    top: AppSizes.height(3.9),
                    right: AppSizes.width(3.9),
                    child: GestureDetector(
                      onTap: () => _showDeleteConfirmationDialog(context, serviceController),
                      child: Container(
                        padding: AppSizes.paddingAll(AppSizes.width(3.9)), // 1% of 390
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: AppSizes.icon(13.65), // 3.5% of 390
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: AppSizes.paddingAll(AppSizes.width(7.8)), // 2% of 390
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Service Name
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),

                  // Category
                  Text(
                    service.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Description
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),

                  // Duration and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            service.displayDuration,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${service.price.toStringAsFixed(0)} ${AppStrings.appCurreny}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmationDialog(BuildContext context, ServiceController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.width(15.6)), // 4% of 390
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: AppSizes.icon(23.4), // 6% of 390
                  ),
                  SizedBox(width: AppSizes.width(7.8)), // 2% of 390
                  Expanded(
                    child: Text(
                      'Delete Service',
                      style: TextStyle(
                        fontSize: AppSizes.font(17.55), // 4.5% of 390
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.height(11.7)), // 3% of 390 height equivalent
              Text(
                'Are you sure you want to delete this service?',
                style: TextStyle(
                  fontSize: AppSizes.font(13.65), // 3.5% of 390
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: AppSizes.height(11.7)),

              // Service Details Container
              Container(
                padding: AppSizes.paddingAll(AppSizes.width(11.7)), // 3% of 390
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Details:',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7), // 3% of 390
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: AppSizes.height(3.9)), // 1% of 390 height equivalent
                    Text(
                      '• ${service.name}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '• Category: ${service.category}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '• Duration: ${service.displayDuration}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '• Price: د.إ${service.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '• Total Bookings: ${service.totalBookings}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: service.totalBookings > 0 ? Colors.red : Colors.grey[600],
                        fontWeight: service.totalBookings > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (service.branchesCount > 0)
                      Text(
                        '• Available at: ${service.branchesCount} branch${service.branchesCount > 1 ? 'es' : ''}',
                        style: TextStyle(
                          fontSize: AppSizes.font(11.7),
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: AppSizes.height(11.7)),

              // Warning Text
              Text(
                service.totalBookings > 0
                    ? '⚠️ This service has ${service.totalBookings} booking${service.totalBookings > 1 ? 's' : ''}! Deleting may affect records.'
                    : '⚠️ This action cannot be undone!',
                style: TextStyle(
                  fontSize: AppSizes.font(9.75), // 2.5% of 390
                  color: service.totalBookings > 0 ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: AppSizes.height(15.6)), // 4% of 390 height equivalent

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: AppSizes.paddingSymmetric(
                          vertical: AppSizes.height(11.7), // 3% of 390 height equivalent
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppSizes.font(13.65), // 3.5% of 390
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.width(7.8)), // 2% of 390
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading) {
                        return Container(
                          padding: AppSizes.paddingSymmetric(
                            vertical: AppSizes.height(11.7),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: AppSizes.width(19.5), // 5% of 390
                              height: AppSizes.height(19.5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                      return ElevatedButton(
                        onPressed: () async {
                          Get.back(); // Close dialog
                          await _deleteService(controller);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: AppSizes.paddingSymmetric(
                            vertical: AppSizes.height(11.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: AppSizes.font(13.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delete Service Function
  Future<void> _deleteService(ServiceController controller) async {
    try {
      final success = await controller.deleteService(service.id);

      if (success) {
        Get.snackbar(
          'Success',
          'Service deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete service',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}