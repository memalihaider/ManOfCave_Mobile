// widgets/custom_elevated_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsets? padding;
  final Widget? icon;
  final MainAxisAlignment? iconAlignment;
  final bool fullWidth;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.icon,
    this.iconAlignment,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primaryGold,
        foregroundColor: foregroundColor ?? AppColors.white,
        disabledBackgroundColor: Colors.grey[400],
        disabledForegroundColor: Colors.white,
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
          color: foregroundColor ?? AppColors.white,
        ),
      )
          : icon != null
          ? _buildIconContent()
          : Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? AppSizes.font(16),
          fontWeight: fontWeight ?? FontWeight.w600,
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
            ),
          ),
        ]
      ],
    );
  }
}