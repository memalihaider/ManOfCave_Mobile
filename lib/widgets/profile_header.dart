// widgets/profile_header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String email;
  final String phoneNumber;
  final String? imageUrl;
  final VoidCallback onEditPressed;
  final VoidCallback onImageTap;

  const ProfileHeaderWidget({
    super.key,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.imageUrl,
    required this.onEditPressed,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGold,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusSmall6),
          bottomRight: Radius.circular(AppSizes.radiusSmall6),
        ),
      ),
      child: Column(
        children: [
          // User Name
          Text(
            name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8.h),

          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 14.sp,
                color: AppColors.white.withOpacity(0.8),
              ),
              SizedBox(width: 6.w),
              Text(
                email,
                maxLines: 2,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Phone Number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14.sp,
                color: AppColors.white.withOpacity(0.8),
              ),
              SizedBox(width: 6.w),
              Text(
                phoneNumber,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.white.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.person,
          size: 40.sp,
          color: AppColors.white,
        ),
      ),
    );
  }
}