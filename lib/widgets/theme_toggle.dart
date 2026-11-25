// widgets/theme_toggle_switch.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class ThemeToggleSwitch extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeToggleSwitch({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryDark.withOpacity(0.1)
                  : AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              size: 24.sp,
              color: isDarkMode ? AppColors.primaryDark : AppColors.primaryGold,
            ),
          ),
          SizedBox(width: 16.w),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Theme',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: isDarkMode,
            onChanged: onChanged,
            activeColor: AppColors.primaryGold,
            activeTrackColor: AppColors.primaryGold.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}