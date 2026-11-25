// widgets/cart_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/cart_model.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback? onRemove;
  final Function(int)? onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.cartItem,
    this.onRemove,
    this.onQuantityChanged,
  });

  double get price => cartItem.price;
  int get quantity => cartItem.quantity;
  double get itemTotal => cartItem.totalPrice;
  String get cartItemId => cartItem.id;
  String get productId => cartItem.productId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSizes.paddingOnly(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: AppSizes.paddingAll(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: AppSizes.width(80),
                  height: AppSizes.height(80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                    color: AppColors.primaryGold.withOpacity(0.1),
                  ),
                  child: cartItem.productImage.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                    child: Image.network(
                      cartItem.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingIndicator();
                      },
                    ),
                  )
                      : _buildPlaceholderIcon(),
                ),
                SizedBox(width: AppSizes.width(10)),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.productName,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: AppSizes.spaceMedium16),

                      // Price and Quantity
                      Row(
                        children: [
                          Text(
                            '${price.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          SizedBox(width: AppSizes.width(8)),
                          Text(
                            '× $quantity',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.width(8)),

                      // Customer Info (if admin view)
                      if (cartItem.customerName.isNotEmpty && cartItem.isPurchased)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer: ${cartItem.customerName}',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: AppSizes.width(2)),
                            Text(
                              cartItem.customerEmail,
                              style: TextStyle(
                                fontSize: AppSizes.font(10),
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                      // Added Date (for purchased items)
                      if (cartItem.isPurchased)
                        Padding(
                          padding: AppSizes.paddingOnly(top:4),
                          child: Text(
                            'Purchased: ${_formatDate(cartItem.purchasedAt)}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Remove Button (only for cart items, not purchased)
                if (!cartItem.isPurchased && onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.close,
                      size: AppSizes.iconSmall18,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),

          // Quantity Controls (only for cart items)
          if (!cartItem.isPurchased && onQuantityChanged != null)
            Container(
              padding: AppSizes.paddingSymmetric(horizontal: 14,vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusMedium12),
                  bottomRight: Radius.circular(AppSizes.radiusMedium12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radius(8)),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => onQuantityChanged?.call(quantity - 1)
                              : null,
                          icon: Icon(
                            Icons.remove,
                            size: AppSizes.icon(16),
                            color: quantity > 1
                                ? AppColors.primaryDark
                                : Colors.grey[300],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                        ),
                        SizedBox(
                          width: AppSizes.width(20),
                          child: Text(
                            quantity.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onQuantityChanged?.call(quantity + 1),
                          icon: Icon(
                            Icons.add,
                            size: AppSizes.icon(16),
                            color: AppColors.primaryDark,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item Total
                  Text(
                    '${itemTotal.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ),

          // Purchased Summary (for purchased items)
          if (cartItem.isPurchased)
            Container(
              padding: AppSizes.paddingSymmetric(horizontal: 14,vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusMedium12),
                  bottomRight: Radius.circular(AppSizes.radiusMedium12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:AppSizes.width(8),
                      vertical: AppSizes.height(4),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: AppSizes.icon(12),
                          color: AppColors.white,
                        ),
                        SizedBox(width: AppSizes.width(4)),
                        Text(
                          'PURCHASED',
                          style: TextStyle(
                            fontSize: AppSizes.font(10),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${itemTotal.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: AppSizes.font(10),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 32.sp,
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primaryGold,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}