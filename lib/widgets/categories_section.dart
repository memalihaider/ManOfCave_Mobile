// widgets/categories_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../Screens/all_product_screen.dart';
import '../Screens/all_services_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/category_controller.dart';
import '../models/category_model.dart';
import 'category_card.dart';

class CategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final VoidCallback onViewAll;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.spaceSmall8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: AppColors.primaryGold,
                    size: AppSizes.iconMedium24,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: AppSizes.textLarge18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: AppSizes.iconSmall14,
                      color: AppColors.primaryGold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceSmall8),
          child: Row(
            children: categories.map((category) {
              return Padding(
                padding: EdgeInsets.only(right: AppSizes.spaceSmall8),
                child: CategoryCard(
                  category: category,
                  onTap: () {
                    // Navigate to category products/services screen
                    if (category.isServiceCategory) {
                      Get.to(()=>AllServicesScreen(
                        categoryId: category.id,
                        categoryName: category.name,
                      ));
                    } else {
                      Get.to(()=>AllProductsScreen(
                        categoryName: category.name,
                        categoryId: category.id,
                      ));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}