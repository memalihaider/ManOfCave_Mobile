import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/branches_controller.dart';
import '../models/branch_model.dart';
import '../widgets/shimmer_loading.dart';
import 'branch_detail_screen.dart';

class LocationsScreen extends StatelessWidget {
  final BranchController branchController = Get.find<BranchController>();

  LocationsScreen({super.key}) {
    if (branchController.branches.isEmpty && !branchController.isLoading.value) {
      branchController.loadBranches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Our Locations', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primaryGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (branchController.isLoading.value) {
          return ShimmerLoading(
            child: ListView.builder(
              padding: AppSizes.paddingAll(16),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          );
        }

        if (branchController.filteredBranches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No branches found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: AppSizes.paddingAll(16),
          itemCount: branchController.filteredBranches.length,
          itemBuilder: (context, index) {
            final branch = branchController.filteredBranches[index];
            return _buildBranchCard(branch);
          },
        );
      }),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    final bool isOpen = branch.isOpenNow();

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Branch Image Header
              Stack(
                children: [
                  Image.network(
                    branch.image ?? 'https://manofcave.ae/wp-content/uploads/2024/01/hero-bg.jpg',
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 180.h,
                      color: AppColors.primaryDark,
                      child: Icon(Icons.store, color: AppColors.primaryGold, size: 50.sp),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 16.h,
                    left: 16.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.success : AppColors.error,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            isOpen ? 'OPEN NOW' : 'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Branch Name and City
                  Positioned(
                    bottom: 16.h,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${branch.city}, ${branch.country}',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Branch Details
              Padding(
                padding: AppSizes.paddingAll(16),
                child: Column(
                  children: [
                    _buildDetailRow(null, branch.address),
                    SizedBox(height: 12.h),
                    _buildDetailRow(Icons.phone, branch.phone),
                    SizedBox(height: 12.h),
                    _buildDetailRow(Icons.access_time, branch.businessHours),
                  ],
                ),
              ),

              // 3. Action Buttons
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.to(() => BranchDetailScreen(branch: branch)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryGold),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: IconButton(
                        onPressed: () => _showWeeklySchedule(branch),
                        icon: Icon(Icons.calendar_month, color: AppColors.primaryGold, size: 20.sp),
                        tooltip: 'Weekly Schedule',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData? icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16.sp, color: AppColors.primaryGold),
          SizedBox(width: 12.w),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showWeeklySchedule(Branch branch) {
    final schedule = branch.weeklySchedule;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
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
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Weekly Hours - ${branch.name}',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Container(
              padding: AppSizes.paddingAll(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              child: Column(
                children: List.generate(days.length, (index) {
                  final day = days[index];
                  final dayKey = dayKeys[index];
                  final hours = schedule[dayKey] ?? 'Closed';
                  final isToday = DateTime.now().weekday - 1 == index;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index < days.length - 1 ? AppSizes.spaceSmall8 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: AppSizes.width(8),
                          height: AppSizes.height(8),
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primaryGold : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: AppSizes.width(8)),
                        SizedBox(
                          width: AppSizes.width(80),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              color: isToday ? AppColors.primaryDark : Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            hours,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              color: isToday ? AppColors.primaryGold : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                ),
                child: Text(
                  'Close',
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

  // void _showBranchDetails(Branch branch) {
  //   Get.defaultDialog(
  //     title: branch.name,
  //     content: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(
  //           'Address: ${branch.fullAddress}',
  //           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           'Phone: ${branch.phone}',
  //           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           'Email: ${branch.email}',
  //           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           'Status: ${branch.status}',
  //           style: TextStyle(
  //             fontSize: 14,
  //             color: branch.isActive ? Colors.green : Colors.red,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         if (branch.description != null && branch.description!.isNotEmpty)
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               SizedBox(height: 8),
  //               Text(
  //                 'Description:',
  //                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  //               ),
  //               Text(
  //                 branch.description!,
  //                 style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //               ),
  //             ],
  //           ),
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Get.back(),
  //         child: Text('Close'),
  //       ),
  //       TextButton(
  //         onPressed: () {
  //           Get.back();
  //           _selectBranch(branch);
  //         },
  //         child: Text(
  //           'Select',
  //           style: TextStyle(color: AppColors.primaryGold),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _selectBranch(Branch branch) {
    // Store selected branch in controller
    branchController.selectBranch(branch);

    // Navigate back with result
    Get.back(result: branch);

    // Show success message
    Get.snackbar(
      'Branch Selected',
      '${branch.name} has been selected',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: AppColors.white,
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      borderRadius: AppSizes.radiusMedium12,
    );
  }
}