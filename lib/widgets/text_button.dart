// widgets/custom_text_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final bool hasUnderline;
  final Widget? icon;
  final MainAxisAlignment? iconAlignment;
  final bool fullWidth;
  final bool isLoading;
  final String? navigateTo; // Optional navigation route

  const CustomTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.width,
    this.height,
    this.padding,
    this.hasUnderline = false,
    this.icon,
    this.iconAlignment,
    this.fullWidth = false,
    this.isLoading = false,
    this.navigateTo,
  });

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: isLoading ? null : (onPressed ?? () => _handleNavigation()),
      style: TextButton.styleFrom(
        padding: padding ?? EdgeInsets.zero,
        minimumSize: Size(width ?? 0, height ?? 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: textColor ?? AppColors.primaryGold,
      ),
      child: isLoading
          ? SizedBox(
        width: 20.w,
        height: 20.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: textColor ?? AppColors.primaryGold,
        ),
      )
          : icon != null
          ? _buildIconContent()
          : Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? AppSizes.font(14),
          fontWeight: fontWeight ?? FontWeight.w600,
          color: textColor ?? AppColors.primaryGold,
          decoration: hasUnderline ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildIconContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: iconAlignment ?? MainAxisAlignment.center,
      children: [
        if (iconAlignment == MainAxisAlignment.end) ...[
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? AppSizes.font(14),
              fontWeight: fontWeight ?? FontWeight.w600,
              color: textColor ?? AppColors.primaryGold,
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          icon!,
        ] else ...[
          icon!,
          SizedBox(width: AppSizes.spaceSmall8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? AppSizes.font(14),
              fontWeight: fontWeight ?? FontWeight.w600,
              color: textColor ?? AppColors.primaryGold,
            ),
          ),
        ]
      ],
    );
  }

  void _handleNavigation() {
    if (navigateTo != null) {
      Get.toNamed(navigateTo!);
    }
  }
}