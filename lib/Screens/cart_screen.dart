// screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/cart_controller.dart';
import '../controlers/loyalty_points_controller.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/shimmer_loading.dart';
import '../screens/checkout_screen.dart';
import 'all_product_screen.dart';
import 'customer_shell.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Controllers
  final CartController cartController = Get.find<CartController>();
  final LoyaltyController loyaltyController = Get.find<LoyaltyController>();

  // Loyalty Points State
  int availablePoints = 0;
  double pointsValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize loyalty points
    _initializePoints();
  }

  void _initializePoints() {
    // Get loyalty data
    availablePoints = loyaltyController.availablePoints;
    pointsValue = loyaltyController.loyaltyConfig?.redemptionRate ?? 0.03;
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius(16)),
        ),
        title: Text(
          'Clear Cart',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              cartController.clearCart();
              Get.back();
              Get.snackbar(
                'Cart Cleared',
                'All items removed from cart',
                backgroundColor: AppColors.primaryGold,
                colorText: AppColors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            fontSize: AppSizes.font(18),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (cartController.cartItems.isNotEmpty) {
              return IconButton(
                onPressed: _showClearCartDialog,
                icon: const Icon(Icons.delete_outline),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            if (cartController.isEmpty)
              Expanded(
                child: _buildEmptyCart(),
              )
            else
              Expanded(
                child: _buildCartContent(),
              ),

            // Bottom Summary
            if (!cartController.isEmpty)
              _buildBottomSummary(),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add some amazing products to your cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.offAll(
                        () => const CustomerShell(),
                    transition: Transition.cupertino,
                    duration: const Duration(milliseconds: 1000)
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart Items Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.white,
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${cartController.itemCount} Items in Cart',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.offAll(
                          () => AllProductsScreen(),
                      transition: Transition.fade,
                      duration: const Duration(milliseconds: 1000)
                  );
                },
                child: Text(
                  'Add More',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cart Items List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: () async {
              await cartController.refreshCart();
            },
            child: Obx(() {
              if (cartController.isLoading) {
                return ShimmerLoading(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Container(
                        height: 100.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...cartController.cartItems.map((cartItem) {
                    return CartItemCard(
                      cartItem: cartItem,
                      onRemove: () {
                        cartController.removeFromCart(cartItem.id);
                      },
                      onQuantityChanged: (newQuantity) {
                        cartController.updateQuantity(cartItem.id, newQuantity);
                      },
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price Summary
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items (${cartController.itemCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${cartController.subtotal.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '${cartController.total.toStringAsFixed(2)} ${AppStrings.appCurreny}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (cartController.isEmpty) return;
                    Get.to(() => CheckoutScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}