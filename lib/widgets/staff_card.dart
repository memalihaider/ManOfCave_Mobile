import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/staff.dart';

class StaffCard extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final VoidCallback onTap;

  const StaffCard({
    super.key,
    required this.staff,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: AppSizes.paddingOnly(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: AppSizes.paddingAll(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Staff Image or Icon
              _buildStaffImage(),
              SizedBox(width: AppSizes.spaceSmall8),

              // Staff Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            staff.name,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Container(
                          padding: AppSizes.paddingSymmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: AppSizes.iconSmall14,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                staff.formattedRating,
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.height(2)),

                    // Role and Branch
                    Text(
                      '${staff.role} • ${staff.branch}',
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

              // Selection Indicator
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    Icons.check_circle,
                    size: 20.sp,
                    color: AppColors.primaryGold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffImage() {
    // Staff Profile Image
    return Container(
      width: 60.w,
      height: 60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        child: staff.avatar != null && staff.avatar!.isNotEmpty
            ? Image.network(
          staff.avatar!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGold,
              ),
            );
          },
        )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: AppColors.primaryGold.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 28.sp,
        color: AppColors.primaryGold,
      ),
    );
  }
}