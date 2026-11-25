import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/controlers/product_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/cart_model.dart';
import 'auth_controller.dart';
import 'order_controller.dart';

class CartController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  final ProductController _productController = Get.find<ProductController>();

  // Reactive state
  final RxList<CartItem> _cartItems = <CartItem>[].obs;
  final RxList<CartItem> _purchasedItems = <CartItem>[].obs;
  final RxDouble _subtotal = 0.0.obs;
  final RxDouble _taxRate = 0.05.obs;
  final RxString _selectedPaymentMethod = 'cod'.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isProcessing = false.obs;

  // Pickup branch fields
  final RxString _pickupBranch = ''.obs;
  final RxString _pickupBranchAddress = ''.obs;
  final RxString _pickupBranchPhone = ''.obs;
  final RxString _pickupBranchTiming = ''.obs;

  // Stream subscription for real-time updates
  StreamSubscription? _cartSubscription;

  // Getters
  List<CartItem> get cartItems => _cartItems.where((item) => item.isInCart).toList();
  List<CartItem> get purchasedItems => _purchasedItems.where((item) => item.isPurchased).toList();
  double get subtotal => _subtotal.value;
  double get taxAmount => _subtotal.value * _taxRate.value;
  double get total => _subtotal.value;
  String get selectedPaymentMethod => _selectedPaymentMethod.value;
  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;
  bool get isEmpty => cartItems.isEmpty;
  int get itemCount => cartItems.length;

  // Pickup branch getters
  String get pickupBranch => _pickupBranch.value;
  String get pickupBranchAddress => _pickupBranchAddress.value;
  String get pickupBranchPhone => _pickupBranchPhone.value;
  String get pickupBranchTiming => _pickupBranchTiming.value;
  bool get hasPickupInfo => _pickupBranch.value.isNotEmpty;

  // Get current user info
  String? get customerId => _authController.currentUser.value?.uid;
  String? get customerName => _authController.currentUser.value?.name;
  String? get customerEmail => _authController.currentUser.value?.email;
  String? get customerPhone => _authController.currentUser.value?.phone;

  @override
  void onInit() {
    super.onInit();

    // Listen to auth state changes
    ever(_authController.currentUser, (user) {
      if (user != null) {
        print('🛒 User logged in: ${user.uid} - Loading cart');
        _initializeCart();
        _setupRealTimeListener();
      } else {
        print('🛒 User logged out - Clearing cart');
        _clearCartData();
      }
    });

    // Initial load if user is already logged in
    if (customerId != null) {
      _initializeCart();
      _setupRealTimeListener();
    }
  }

  void _initializeCart() {
    if (customerId != null) {
      print('🛒 Initializing cart for user: $customerId');
      loadCartItems();
      loadPurchasedItems();
    } else {
      print('🛒 No user logged in - cart empty');
    }
  }

  void _setupRealTimeListener() {
    if (customerId == null) return;

    _cartSubscription?.cancel();

    _cartSubscription = _firestore
        .collection('cart')
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final updatedItems = snapshot.docs
          .map((doc) => CartItem.fromFirestore(doc))
          .toList();

      _cartItems.assignAll(updatedItems);
      _calculateSubtotal();

      print('🛒 Cart updated: ${_cartItems.length} items');
    }, onError: (error) {
      print('Error listening to cart: $error');
    });
  }

  void _clearCartData() {
    _cartItems.clear();
    _purchasedItems.clear();
    _subtotal.value = 0.0;
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  // Load cart items from Firestore
  Future<void> loadCartItems() async {
    try {
      _isLoading.value = true;

      if (customerId == null) {
        print('🛒 No user ID - cannot load cart');
        return;
      }

      print('🛒 Loading cart items for user: $customerId');

      final querySnapshot = await _firestore
          .collection('cart')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'active')
          .orderBy('addedAt', descending: true)
          .get();

      final loadedItems = querySnapshot.docs
          .map((doc) => CartItem.fromFirestore(doc))
          .toList();

      _cartItems.assignAll(loadedItems);
      _calculateSubtotal();

      print('🛒 Loaded ${_cartItems.length} cart items');

    } catch (e) {
      print('Error loading cart items: $e');
      Get.snackbar(
        'Error',
        'Failed to load cart items: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Load purchased items history
  Future<void> loadPurchasedItems() async {
    try {
      if (customerId == null) return;

      final querySnapshot = await _firestore
          .collection('cart')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'purchased')
          .orderBy('purchasedAt', descending: true)
          .limit(20)
          .get();

      final loadedItems = querySnapshot.docs
          .map((doc) => CartItem.fromFirestore(doc))
          .toList();

      _purchasedItems.assignAll(loadedItems);

      print('🛒 Loaded ${_purchasedItems.length} purchased items');

    } catch (e) {
      print('Error loading purchased items: $e');
    }
  }

  // Add product to cart
  Future<void> addToCart(String productId, int quantity) async {
    try {
      _isLoading.value = true;

      if (customerId == null || customerName == null || customerEmail == null) {
        Get.snackbar('Error', 'Please login to add items to cart');
        return;
      }

      final product = await _productController.getProductById(productId);
      if (product == null) {
        Get.snackbar('Error', 'Product not found');
        return;
      }

      if (!product.inStock) {
        Get.snackbar('Error', 'Product is out of stock');
        return;
      }

      final existingItem = _cartItems.firstWhereOrNull(
              (item) => item.productId == productId && item.isInCart
      );

      final orderId = _generateOrderId();
      final now = DateTime.now();

      if (existingItem != null) {
        final newQuantity = existingItem.quantity + quantity;
        await _firestore
            .collection('cart')
            .doc(existingItem.id)
            .update({
          'quantity': newQuantity,
          'updatedAt': now,
        });
        print('🛒 Updated existing cart item: $productId');
      } else {
        final cartItem = CartItem(
          id: '',
          orderId: orderId,
          productId: productId,
          productName: product.name,
          productImage: product.imageUrl,
          price: product.price,
          quantity: quantity,
          customerId: customerId!,
          customerName: customerName!,
          customerEmail: customerEmail!,
          status: 'active',
          addedAt: now,
          purchasedAt: now,
        );

        await _firestore
            .collection('cart')
            .add(cartItem.toFirestore());
        print('🛒 Added new cart item: $productId');
      }

      Get.snackbar(
        'Added to Cart',
        '${product.name} added to cart',
        backgroundColor: AppColors.primaryGold,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add to cart: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('cart')
          .doc(cartItemId)
          .delete();

      Get.snackbar(
        'Removed',
        'Item removed from cart',
        backgroundColor: AppColors.primaryGold,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove item: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity < 1) {
        await removeFromCart(cartItemId);
        return;
      }

      _isLoading.value = true;

      final cartItem = _cartItems.firstWhereOrNull((item) => item.id == cartItemId);
      if (cartItem != null) {
        final product = await _productController.getProductById(cartItem.productId);
        if (product != null && newQuantity > product.totalStock) {
          Get.snackbar('Error', 'Not enough stock available');
          return;
        }
      }

      await _firestore
          .collection('cart')
          .doc(cartItemId)
          .update({
        'quantity': newQuantity,
        'updatedAt': DateTime.now(),
      });

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update quantity: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Clear all items from cart
  Future<void> clearCart() async {
    try {
      _isLoading.value = true;

      final batch = _firestore.batch();

      for (final item in cartItems) {
        final docRef = _firestore.collection('cart').doc(item.id);
        batch.delete(docRef);
      }

      await batch.commit();

      Get.snackbar(
        'Cleared',
        'Cart cleared successfully',
        backgroundColor: AppColors.primaryGold,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear cart: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _calculateSubtotal() {
    _subtotal.value = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String _generateOrderId() {
    final now = DateTime.now();
    return 'ORD-${now.millisecondsSinceEpoch}-${_generateRandomString(6)}';
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        length,
            (_) => chars.codeUnitAt((chars.length * DateTime.now().microsecond) ~/ 1000000)
    ));
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod.value = method;
  }

  // Set pickup branch information
  void setPickupBranch({
    required String branch,
    required String address,
    required String phone,
    required String timing,
  }) {
    _pickupBranch.value = branch;
    _pickupBranchAddress.value = address;
    _pickupBranchPhone.value = phone;
    _pickupBranchTiming.value = timing;
  }

  void clearPickupBranch() {
    _pickupBranch.value = '';
    _pickupBranchAddress.value = '';
    _pickupBranchPhone.value = '';
    _pickupBranchTiming.value = '';
  }

  double getItemTotal(CartItem item) {
    return item.totalPrice;
  }

  // Checkout with pickup branch (no shipping)
  Future<void> checkout({
    required String paymentMethod,
    String? orderNotes,
    String? expectedDeliveryDate,
  }) async {
    try {
      if (isEmpty) {
        Get.snackbar(
          'Empty Cart',
          'Add items to cart before checkout',
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
        return;
      }

      if (!hasPickupInfo) {
        Get.snackbar(
          'Missing Information',
          'Please select a pickup branch before checkout',
          backgroundColor: Colors.orange,
          colorText: AppColors.white,
        );
        return;
      }

      if (customerId == null || customerName == null || customerEmail == null || customerPhone == null) {
        Get.snackbar(
          'Missing Information',
          'Please login or provide customer information',
          backgroundColor: Colors.orange,
          colorText: AppColors.white,
        );
        return;
      }

      _isProcessing.value = true;

      final orderController = Get.find<OrderController>();
      final order = await orderController.createOrderFromCart(
        customerId: customerId!,
        customerName: customerName!,
        customerEmail: customerEmail!,
        customerPhone: customerPhone!,
        paymentMethod: paymentMethod,
        pickupBranch: _pickupBranch.value,
        pickupBranchAddress: _pickupBranchAddress.value,
        pickupBranchPhone: _pickupBranchPhone.value,
        pickupBranchTiming: _pickupBranchTiming.value,
        orderNotes: orderNotes,
        expectedDeliveryDate: expectedDeliveryDate,
      );

      _isProcessing.value = false;

      if (order != null) {
        // Clear pickup branch after successful order
        clearPickupBranch();
        _showCheckoutSuccessDialog(order.id, order.transactionId);
      }

    } catch (e) {
      _isProcessing.value = false;
      Get.snackbar(
        'Checkout Failed',
        'Error during checkout: $e',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
    }
  }

  void _showCheckoutSuccessDialog(String orderId, String transactionId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius(16)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48.sp,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Your order has been placed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Order ID: ${orderId.substring(0, 8).toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Pickup at: ${_pickupBranch.value}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed('/orders');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
              ),
              child: Text(
                'View Orders',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed('/home');
              },
              child: Text(
                'Continue Shopping',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Refresh cart data
  Future<void> refreshCart() async {
    await loadCartItems();
    await loadPurchasedItems();
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'tax': taxAmount,
      'total': total,
      'paymentMethod': selectedPaymentMethod,
      'pickupBranch': _pickupBranch.value,
      'pickupBranchAddress': _pickupBranchAddress.value,
      'pickupBranchPhone': _pickupBranchPhone.value,
      'pickupBranchTiming': _pickupBranchTiming.value,
    };
  }

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }
}