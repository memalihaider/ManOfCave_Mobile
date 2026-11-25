import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class TimeSlotCard extends StatelessWidget {
  final String time;
  final String availability;
  final Color availabilityColor;
  final bool isSelected;
  final bool isAvailable;
  final bool isPeakHour;
  final bool isWaitlist;
  final VoidCallback onTap;

  const TimeSlotCard({
    super.key,
    required this.time,
    required this.availability,
    required this.availabilityColor,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
    this.isPeakHour = false,
    this.isWaitlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        width: 80.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : isAvailable
                ? availabilityColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryGold
                    : isAvailable
                    ? AppColors.primaryDark
                    : Colors.grey[400],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              availability,
              style: TextStyle(
                fontSize: AppSizes.font(10),
                color: availabilityColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isPeakHour && isAvailable)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'Peak',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}