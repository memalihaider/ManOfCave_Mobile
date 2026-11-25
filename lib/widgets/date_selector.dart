import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';



class DateSelectorCard extends StatelessWidget {
  final String selectedDate;
  final String selectedDay;
  final String selectedMonth;
  final VoidCallback onTap;
  final bool isLoading;

  const DateSelectorCard({
    super.key,
    required this.selectedDate,
    required this.selectedDay,
    required this.selectedMonth,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: AppSizes.paddingAll(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  if (isLoading)
                    SizedBox(
                      height: 24.h,
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      selectedDate.isNotEmpty
                          ? '$selectedDay, $selectedDate $selectedMonth'
                          : 'Tap to select date',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: selectedDate.isNotEmpty
                            ? AppColors.primaryDark
                            : Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 20.sp,
                color: AppColors.primaryGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}