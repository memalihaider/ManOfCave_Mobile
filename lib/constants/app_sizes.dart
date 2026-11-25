import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class AppSizes {
  static late double screenWidth;
  static late double screenHeight;
  static late double statusBarHeight;
  static late double bottomPadding;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    statusBarHeight = mediaQuery.padding.top;
    bottomPadding = mediaQuery.padding.bottom;
  }

  /// Widths based on screen size
  static double width(double inputWidth) => (screenWidth * inputWidth) / 390;

  /// Heights based on screen size
  static double height(double inputHeight) => (screenHeight * inputHeight) / 844;

  /// Radius and border rounding
  static double radius(double r) => r.r;

  /// Dynamic font size
  static double font(double size) => size.sp;

  /// Padding & Margin helpers
  static EdgeInsets paddingAll(double value) => EdgeInsets.all(value.w);
  static EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal.w, vertical: vertical.h);
  static EdgeInsets paddingOnly({double top = 0, double bottom = 0, double left=0, double right=0}) =>
      EdgeInsets.only(top: top.h, bottom: bottom.h, left: left.w, right: right.w);

  /// Button sizes
  static double buttonHeightSmall40 = 40.h;
  static double buttonHeightMedium50 = 50.h;
  static double buttonHeightLarge60 = 60.h;

  /// Icon sizes
  static double icon(double size) => size.sp;
  static double iconSmall14 = 14.sp;
  static double iconSmall18 = 18.sp;
  static double iconMedium24 = 24.sp;
  static double iconLarge32 = 32.sp;
  static double iconLarge60 = 60.sp;

  /// Text sizes
  static double textSmall12 = 12.sp;
  static double textMedium14 = 14.sp;
  static double textLarge18 = 18.sp;
  static double textExtraLarge22 = 22.sp;

  /// Border radius presets
  static double radiusSmall6 = 6.r;
  static double radiusMedium12 = 12.r;
  static double radiusLarge20 = 20.r;

  /// Spacing constants (use for SizedBox)
  static double spaceSmall8 = 8.h;
  static double spaceMedium16 = 16.h;
  static double spaceLarge24 = 24.h;
  static double spaceExtraLarge32 = 32.h;

  /// Example responsive box constraint
  static BoxConstraints maxWidthBox = BoxConstraints(maxWidth: 600.w);
}
