// screens/staff_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/customer_controller.dart';
import '../controlers/staff_controller.dart';
import '../widgets/elevated_button.dart';
import '../widgets/staff_card.dart';
import 'booking_confirm_screen.dart';

class StaffSelectionScreen extends StatelessWidget {
  final StaffController staffController = Get.find<StaffController>();
  final CustomerController customerController = Get.find<CustomerController>();

  final String serviceId;
  final String serviceName;
  final int serviceDuration;
  final double servicePrice;
  final String branchName;
  final DateTime selectedDate;
  final String selectedTime;
  final String branchAddress;

  StaffSelectionScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.selectedDate,
    required this.selectedTime,
    required this.serviceDuration,
    required this.servicePrice,
    required this.branchName,
    required this.branchAddress,
  });

  @override
  Widget build(BuildContext context) {
    // Fire once when the booking flow opens this screen.
    staffController.ensureLoaded();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Select Staff',
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
      body: Obx(() {
        return Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: AppSizes.paddingOnly(bottom: AppSizes.spaceSmall8),
                child: Column(
                  children: [
                    // Service Summary
                    _buildServiceSummary(),

                    // Staff List
                    _buildStaffList(),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar (fixed at bottom)
            _buildActionBar(),
          ],
        );
      }),
    );
  }

  Widget _buildServiceSummary() {
    return Container(
      margin: AppSizes.paddingSymmetric(horizontal: 14,vertical: 8),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
        border: Border.all(color: AppColors.primaryGold),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
            offset: Offset(0, AppSizes.height(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8,),

          // Service Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Service Icon
              Container(
                width: AppSizes.width(50),
                height: AppSizes.height(50),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: AppSizes.iconSmall14,
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceMedium16,),
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSizes.height(4),),
                    Text(
                      '$serviceDuration min • ${servicePrice.toStringAsFixed(0)} ${AppStrings.appCurreny}',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSizes.spaceSmall8,),
          Divider(color: Colors.grey[200], height: AppSizes.height(1)),
          SizedBox(height: AppSizes.spaceSmall8,),

          // Branch Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: AppSizes.iconSmall18,
                color: Colors.grey[500],
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchName,
                      style: TextStyle(
                        fontSize: AppSizes.font(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceSmall8,),
                    Text(
                      branchAddress,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSizes.spaceSmall8,),
          Divider(color: Colors.grey[200], height: AppSizes.height(1)),
          SizedBox(height: AppSizes.spaceSmall8,),

          // Selected Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Date",
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Flexible(
                child: Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8,),
          // Selected Time Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Time",
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              Flexible(
                child: Text(
                  selectedTime,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    if (staffController.isLoading.value) {
      return Center(
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          child: CircularProgressIndicator(
            color: AppColors.primaryGold,
          ),
        ),
      );
    }

    if (staffController.activeStaff.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: AppSizes.iconSmall14,
                color: Colors.grey[400],
              ),
              SizedBox(height: AppSizes.spaceMedium16,),
              Text(
                'No staff available',
                style: TextStyle(
                  fontSize: AppSizes.textExtraLarge22,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16,),
              Text(
                'Please try another branch',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter staff for current branch and service type
    final filteredStaff = staffController.filterStaff(
      branch: branchName,
      isActive: true,
    );

    if (filteredStaff.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: AppSizes.iconMedium24,
                color: Colors.grey[400],
              ),
              SizedBox(height: AppSizes.spaceSmall8,),
              Text(
                'No staff available at $branchName',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.spaceMedium16,),
              Text(
                'Try selecting a different branch',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
      ),
      child: Column(
        children: [
          // "Any Available Staff" option
          _buildAnyStaffOption(),

          // Staff list
          ...filteredStaff.map((staff) {
            return StaffCard(
              staff: staff,
              isSelected: staffController.isStaffSelected(staff),
              onTap: () => staffController.selectStaff(staff),
            );
          }).toList(),

          SizedBox(height: AppSizes.spaceSmall8,),
        ],
      ),
    );
  }

  Widget _buildAnyStaffOption() {
    return GestureDetector(
      onTap: () => staffController.selectAnyStaff(),
      child: Container(
        margin: AppSizes.paddingOnly(bottom: 16),
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
              offset: Offset(0, AppSizes.height(2)),
            ),
          ],
          border: Border.all(
            color: staffController.isAnyStaffSelected
                ? AppColors.primaryGold
                : Colors.grey[200]!,
            width: staffController.isAnyStaffSelected ? AppSizes.width(2) : AppSizes.width(1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: AppSizes.width(60),
              height: AppSizes.height(60),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  width: AppSizes.width(1),
                ),
              ),
              child: Icon(
                Icons.group,
                size: AppSizes.iconLarge32,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(width: AppSizes.spaceSmall8,),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Any Available Staff',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSmall8,),
                  Text(
                    'We will assign the best available staff for your booking',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selected Indicator
            if (staffController.isAnyStaffSelected)
              Icon(
                Icons.check_circle,
                size: AppSizes.iconSmall18,
                color: AppColors.primaryGold,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Obx(() {

      return Container(
        padding: AppSizes.paddingSymmetric(horizontal: 14,vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: AppSizes.radius(AppSizes.spaceMedium16),
              offset: Offset(0, -AppSizes.height(4)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected Staff Info
            if (staffController.selectedStaff.value != null ||
                staffController.isAnyStaffSelected)
              Container(
                padding: AppSizes.paddingAll(8),
                margin: AppSizes.paddingOnly(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Row(
                  children: [
                    Icon(
                      staffController.isAnyStaffSelected
                          ? Icons.group
                          : Icons.person,
                      size: AppSizes.iconSmall18,
                      color: AppColors.primaryGold,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8,),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Staff',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: AppSizes.spaceSmall8,),
                          Text(
                            staffController.selectedStaffDisplayName,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


            CustomElevatedButton(onPressed: (){
              if (staffController.selectedStaff.value != null ||
                  staffController.isAnyStaffSelected) {


                // Format date to YYYY-MM-DD
                final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                // Extract time slot (remove AM/PM)
                final timeSlot = selectedTime.replaceAll(RegExp(r'\s*[AP]M$'), '').trim();

                // Navigate to BookingSummaryScreen
                Get.to(() => BookingSummaryScreen(
                  serviceId: serviceId,
                  serviceName: serviceName,
                  serviceDuration: serviceDuration,
                  servicePrice: servicePrice,
                  selectedDate: formattedDate,
                  selectedTime: selectedTime,
                  selectedTimeSlot: timeSlot,
                  branchName: branchName,
                  branchAddress: branchAddress,
                ));
              } else {
                Get.snackbar(
                  'Select Staff',
                  'Please select a staff member or choose "Any Available Staff"',
                  backgroundColor: AppColors.primaryGold,
                  colorText: AppColors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
                  borderRadius: AppSizes.radiusSmall6,
                );
              }
            }, text: "Proceed to Confirmation"),
          ],
        ),
      );
    });
  }
}