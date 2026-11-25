import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/product_model.dart';
import '../controlers/product_controller.dart';
import '../controlers/auth_controller.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showDeleteButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final productController = Get.find<ProductController>();

    final isAdmin = authController.isAdmin ||
        authController.isSuperAdmin ||
        authController.isBranchAdmin;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.width(156), // 40% of 390 = 156
        margin: EdgeInsets.only(right: AppSizes.width(7.8)), // 2% of 390
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image with Stock Status and Delete Button
            Stack(
              children: [
                Container(
                  height: AppSizes.height(97.5), // 25% of 390 height equivalent
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                  ),
                  child: _buildProductImage(),
                ),

                // Stock Status Badge
                Positioned(
                  top: AppSizes.height(3.9), // 1% of 390 height equivalent
                  left: AppSizes.width(3.9), // 1% of 390
                  child: Container(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.width(5.85), // 1.5% of 390
                      vertical: AppSizes.height(1.95), // 0.5% of 390 height equivalent
                    ),
                    decoration: BoxDecoration(
                      color: _getStockStatusColor(product),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Text(
                      product.stockStatus,
                      style: TextStyle(
                        fontSize: AppSizes.font(7.8), // 2% of 390
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Delete Button for Admins
                if (showDeleteButton && isAdmin)
                  Positioned(
                    top: AppSizes.height(3.9),
                    right: AppSizes.width(3.9),
                    child: GestureDetector(
                      onTap: () => _showDeleteConfirmationDialog(context, productController),
                      child: Container(
                        padding: AppSizes.paddingAll(AppSizes.width(3.9)),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: AppSizes.icon(13.65), // 3.5% of 390
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                // Profit Margin Indicator
                if (!showDeleteButton || !isAdmin)
                  Positioned(
                    top: AppSizes.height(3.9),
                    right: AppSizes.width(3.9),
                    child: Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.width(5.85),
                        vertical: AppSizes.height(1.95),
                      ),
                      decoration: BoxDecoration(
                        color: product.profitMargin > 50 ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                      ),
                      child: Text(
                        '${product.profitMargin.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: AppSizes.font(7.8),
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: AppSizes.paddingAll(AppSizes.width(7.8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),

                  // Category
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Description
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8.h),

                  // Price, Stock, and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} ${AppStrings.appCurreny}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            product.rating.toString(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    // Check if image URL is valid (not empty and not a placeholder)
    final hasValidImage = product.imageUrl.isNotEmpty &&
        !product.imageUrl.contains('via.placeholder.com') &&
        !product.imageUrl.contains('placeholder') &&
        !product.imageUrl.contains('example.com');

    if (hasValidImage) {
      return Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image for ${product.name}: $error');
          return _buildImagePlaceholder();
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
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: AppSizes.icon(31.2), // 8% of 390
        color: AppColors.primaryGold,
      ),
    );
  }

  Color _getStockStatusColor(Product product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmationDialog(BuildContext context, ProductController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.width(15.6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: AppSizes.icon(23.4),
                  ),
                  SizedBox(width: AppSizes.width(7.8)),
                  Expanded(
                    child: Text(
                      'Delete Product',
                      style: TextStyle(
                        fontSize: AppSizes.font(17.55),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.height(11.7)),
              Text(
                'Are you sure you want to delete this product?',
                style: TextStyle(
                  fontSize: AppSizes.font(13.65),
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: AppSizes.height(11.7)),

              // Product Details Container
              Container(
                padding: AppSizes.paddingAll(AppSizes.width(11.7)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details:',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: AppSizes.height(3.9)),
                    Text(
                      '• ${product.name}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '• SKU: ${product.sku}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '• Category: ${product.category}',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '• Stock: ${product.totalStock} units',
                      style: TextStyle(
                        fontSize: AppSizes.font(11.7),
                        color: product.totalStock > 0 ? Colors.red : Colors.grey[600],
                        fontWeight: product.totalStock > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSizes.height(11.7)),

              // Warning Text
              Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(
                  fontSize: AppSizes.font(9.75),
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: AppSizes.height(15.6)),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: AppSizes.paddingSymmetric(
                          vertical: AppSizes.height(11.7),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppSizes.font(13.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.width(7.8)),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading) {
                        return Container(
                          padding: AppSizes.paddingSymmetric(
                            vertical: AppSizes.height(11.7),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: AppSizes.width(19.5),
                              height: AppSizes.height(19.5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                      return ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await _deleteProduct(controller);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: AppSizes.paddingSymmetric(
                            vertical: AppSizes.height(11.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: AppSizes.font(13.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delete Product Function
  Future<void> _deleteProduct(ProductController controller) async {
    try {
      final success = await controller.deleteProduct(product.id);

      if (success) {
        Get.snackbar(
          'Success',
          'Product deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete product',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}