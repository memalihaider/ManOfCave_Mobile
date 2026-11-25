// controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class ThemeController extends GetxController {
  final isDarkMode = false.obs;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
    );

    // You can also update AppColors based on theme
    // This would require a theme-aware AppColors implementation
  }
}