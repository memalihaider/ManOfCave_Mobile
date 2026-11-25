// widgets/custom_outlined_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? borderColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? borderRadius;
  final double? borderWidth;
  final double? elevation;
  final EdgeInsets? padding;
  final Widget? icon;
  final MainAxisAlignment? iconAlignment;
  final bool fullWidth;
  final bool isLoading;

  const CustomOutlinedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.borderColor,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.borderWidth,
    this.elevation,
    this.padding,
    this.icon,
    this.iconAlignment,
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primaryGold,
        side: BorderSide(
          color: borderColor ?? AppColors.primaryGold,
          width: borderWidth ?? 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radius(8)),
        ),
        elevation: elevation ?? 0,
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
          fontSize: fontSize ?? AppSizes.font(16),
          fontWeight: fontWeight ?? FontWeight.w600,
          color: textColor ?? AppColors.primaryGold,
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
              fontSize: fontSize ?? AppSizes.font(16),
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
              fontSize: fontSize ?? AppSizes.font(16),
              fontWeight: fontWeight ?? FontWeight.w600,
              color: textColor ?? AppColors.primaryGold,
            ),
          ),
        ]
      ],
    );
  }
}