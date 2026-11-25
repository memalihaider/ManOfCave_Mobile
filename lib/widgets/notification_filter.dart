import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class NotificationFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const NotificationFilterChip({
    super.key,
    required this.label,
    this.count,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
        child: Container(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceMedium16,
            vertical: AppSizes.spaceSmall8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.grey[100],
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSizes.iconSmall18,
                color: isSelected ? AppColors.white : Colors.grey[600],
              ),
              SizedBox(width: AppSizes.spaceSmall8,),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : Colors.grey[600],
                ),
              ),
              if (count != null && count! > 0) ...[
                SizedBox(width: AppSizes.spaceSmall8,),
                Container(
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}