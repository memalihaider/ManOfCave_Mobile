// widgets/booking_summary_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class BookingSummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isHighlighted;

  const BookingSummaryItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryGold
              : Colors.grey[200]!,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.primaryGold.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSizes.radius(8)),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: isHighlighted ? AppColors.primaryGold : Colors.grey[600],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}