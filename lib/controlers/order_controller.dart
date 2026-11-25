// controllers/order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/controlers/product_controller.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import 'cart_controller.dart';
import 'customer_controller.dart';
import 'loyalty_points_controller.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';

class OrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerController _customerController = Get.find<CustomerController>();
  final ProductController _productController = Get.find<ProductController>();
  final CartController _cartController = Get.find<CartController>();
  final LoyaltyController _loyaltyController = Get.find<LoyaltyController>();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final RxList<Order> _orders = <Order>[].obs;
  final RxList<Order> _customerOrders = <Order>[].obs;
  final RxList<Order> _userOrders = <Order>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _filterStatus = 'All'.obs;
  final RxString _filterPaymentStatus = 'All'.obs;

  // Current user info
  String? get _currentUserId => _authController.currentUser.value?.uid;
  bool get _isLoggedIn => _authController.isLoggedIn.value;

  // Getters
  List<Order> get allOrders => _orders;
  List<Order> get customerOrders => _customerOrders;
  List<Order> get userOrders => _userOrders;
  List<Order> get filteredOrders => _applyFilters(_orders);
  List<Order> get filteredCustomerOrders => _applyFilters(_customerOrders);
  List<Order> get filteredUserOrders => _applyFilters(_userOrders);
  bool get isLoading => _isLoading.value;
  String? get customerId => _customerController.currentCustomer?.uid;

  // Order statistics
  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((order) => order.isPending).length;
  int get completedOrders => _orders.where((order) => order.isCompleted).length;
  int get cancelledOrders => _orders.where((order) => order.isCancelled).length;
  double get totalRevenue => _orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  double get totalProfit => _orders.fold(0.0, (sum, order) => sum + order.totalProfit);

  @override
  void onInit() {
    super.onInit();

    if (customerId != null) {
      loadCustomerOrders();
    }

    ever(_authController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        loadUserOrders();
      } else {
        _userOrders.clear();
      }
    });

    if (_isLoggedIn) {
      loadUserOrders();
    }
  }

  // Load all orders (for admin)
  Future<void> loadAllOrders() async {
    try {
      _isLoading.value = true;
      update();

      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final loadedOrders = querySnapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();

      _orders.assignAll(loadedOrders);
      update();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load orders: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      update();
      print("Failed to load order: $e");
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  // Load orders for current customer
  Future<void> loadCustomerOrders() async {
    try {
      _isLoading.value = true;
      update();

      if (customerId == null) {
        _customerOrders.clear();
        update();
        return;
      }

      final querySnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final loadedOrders = querySnapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();

      _customerOrders.assignAll(loadedOrders);
      update();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load your orders: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      update();
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  // Load orders for current user
  Future<void> loadUserOrders() async {
    print("Current User: $_currentUserId");
    print("IsLoggedIn $_isLoggedIn");
    try {
      if (!_isLoggedIn || _currentUserId == null) {
        _userOrders.clear();
        return;
      }

      final querySnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final loadedOrders = querySnapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();

      _userOrders.assignAll(loadedOrders);
      update();

    } catch (e) {
      print('Error loading user orders: $e');
      if (e.toString().contains('The query requires an index')) {
        print('Firestore index required for user orders query');
      }
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Create new order from cart with pickup branch
  Future<Order?> createOrderFromCart({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String paymentMethod,
    required String pickupBranch,
    required String pickupBranchAddress,
    required String pickupBranchPhone,
    required String pickupBranchTiming,
    String? orderNotes,
    String? expectedDeliveryDate,
  }) async {
    try {
      _isLoading.value = true;

      // Get cart items
      final cartItems = _cartController.cartItems;
      if (cartItems.isEmpty) {
        Get.snackbar('Error', 'Cart is empty');
        return null;
      }

      // Get product details for each cart item
      final orderProducts = <OrderProduct>[];
      final branchNames = <String>{};

      for (final cartItem in cartItems) {
        final product = await _productController.getProductById(cartItem.productId);
        if (product == null) {
          Get.snackbar('Error', 'Product ${cartItem.productName} not found');
          return null;
        }

        // Check stock
        if (cartItem.quantity > product.totalStock) {
          Get.snackbar(
            'Out of Stock',
            'Not enough stock for ${product.name}. Available: ${product.totalStock}',
          );
          return null;
        }

        // Create order product
        final orderProduct = OrderProduct(
          productId: product.id,
          productName: product.name,
          productImage: product.imageUrl,
          productCategory: product.category,
          productCategoryId: product.categoryId,
          price: product.price,
          productCost: product.cost,
          productSku: product.sku,
          quantity: cartItem.quantity,
          productBranches: product.branches,
          productBranchNames: product.branchNames,
        );

        orderProducts.add(orderProduct);
        branchNames.addAll(product.branchNames);
      }

      // Calculate total amount
      final totalAmount = orderProducts.fold(0.0, (sum, product) => sum + product.totalPrice);

      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

      // Generate order date
      final orderDate = _formatDate(DateTime.now());
      final deliveryDate = expectedDeliveryDate ?? _formatDate(DateTime.now().add(Duration(days: 7)));

      // Determine payment status
      final paymentStatus = paymentMethod == 'cod' ? 'pending' : 'paid';

      // Create order with pickup branch fields
      final order = Order(
        id: '',
        transactionId: transactionId,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        products: orderProducts,
        branchNames: branchNames.toList(),
        totalAmount: totalAmount,
        status: 'upcoming',
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        orderDate: orderDate,
        expectedDeliveryDate: deliveryDate,
        orderNotes: orderNotes,
        pointsAwarded: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pickupBranch: pickupBranch,
        pickupBranchAddress: pickupBranchAddress,
        pickupBranchPhone: pickupBranchPhone,
        pickupBranchTiming: pickupBranchTiming,
      );

      // Save order to Firestore
      final orderRef = await _firestore
          .collection('orders')
          .add(order.toFirestore());

      // Get the created order with ID
      final createdOrderDoc = await orderRef.get();
      final createdOrder = Order.fromFirestore(createdOrderDoc);
      final orderId = orderRef.id;

      // Update product stock and sold counts
      await _updateProductStock(orderProducts);

      // Clear cart
      await _cartController.clearCart();

      // Refresh orders
      await loadCustomerOrders();
      if (_isLoggedIn) {
        await loadUserOrders();
      }

      _isLoading.value = false;

      Get.snackbar(
        'Order Placed Successfully! 🎉',
        'Your order #$transactionId has been placed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return createdOrder;

    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Order Failed',
        'Error creating order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Create order with pickup branch (for admin/guest)
  Future<Order?> createOrder({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required List<OrderProduct> products,
    required List<String> branchNames,
    required double totalAmount,
    required String status,
    required String paymentMethod,
    required String paymentStatus,
    required String orderDate,
    required String expectedDeliveryDate,
    required String pickupBranch,
    required String pickupBranchAddress,
    required String pickupBranchPhone,
    required String pickupBranchTiming,
    String? orderNotes,
    bool pointsAwarded = false,
  }) async {
    try {
      _isLoading.value = true;

      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

      // Create order
      final order = Order(
        id: '',
        transactionId: transactionId,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        products: products,
        branchNames: branchNames,
        totalAmount: totalAmount,
        status: status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        orderDate: orderDate,
        expectedDeliveryDate: expectedDeliveryDate,
        orderNotes: orderNotes,
        pointsAwarded: pointsAwarded,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pickupBranch: pickupBranch,
        pickupBranchAddress: pickupBranchAddress,
        pickupBranchPhone: pickupBranchPhone,
        pickupBranchTiming: pickupBranchTiming,
      );

      // Save order to Firestore
      final orderRef = await _firestore
          .collection('orders')
          .add(order.toFirestore());

      // Get the created order with ID
      final createdOrderDoc = await orderRef.get();
      final createdOrder = Order.fromFirestore(createdOrderDoc);
      final orderId = orderRef.id;

      // Update product stock and sold counts
      await _updateProductStock(products);

      // Clear cart
      await _cartController.clearCart();

      // Refresh orders
      if (customerId == this.customerId) {
        await loadCustomerOrders();
      }

      if (_isLoggedIn && customerId == _currentUserId) {
        await loadUserOrders();
      }
      if (order != null) {
        final notificationController = Get.find<NotificationController>();
        notificationController.showInAppNotification(
          title: 'Order Placed! 🛍️',
          message: 'Your order #${order.transactionId} has been placed successfully.',
          type: NotificationType.order,
          data: {
            'type': 'order',
            'orderId': order.id,
            'transactionId': order.transactionId,
          },
        );
      }

      _isLoading.value = false;
      Get.snackbar(
        'Order Placed Successfully! 🎉',
        'Your order #$transactionId has been placed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return createdOrder;

    } catch (e) {
      _isLoading.value = false;
      print('Error creating order: $e');
      Get.snackbar(
        'Order Failed',
        'Error creating order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Update order points awarded status
  Future<bool> updateOrderPointsAwarded(String orderId, bool pointsAwarded) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'pointsAwarded': pointsAwarded,
        'updatedAt': DateTime.now(),
      });

      // Refresh the order in the lists
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(pointsAwarded: pointsAwarded);
      }

      final customerIndex = _customerOrders.indexWhere((order) => order.id == orderId);
      if (customerIndex != -1) {
        _customerOrders[customerIndex] = _customerOrders[customerIndex].copyWith(pointsAwarded: pointsAwarded);
      }

      final userIndex = _userOrders.indexWhere((order) => order.id == orderId);
      if (userIndex != -1) {
        _userOrders[userIndex] = _userOrders[userIndex].copyWith(pointsAwarded: pointsAwarded);
      }

      update();
      return true;
    } catch (e) {
      print('Error updating order points awarded: $e');
      return false;
    }
  }

  // Award loyalty points for order
  Future<void> _awardOrderPoints({
    required String orderId,
    required String customerId,
    required String orderNumber,
    required double totalAmount,
    required List<String> branchNames,
    required List<OrderProduct> products,
  }) async {
    try {
      final points = await _calculateOrderPoints(totalAmount);

      if (points > 0) {
        final branchName = branchNames.isNotEmpty ? branchNames.first : 'Main Branch';
        final branchId = '';

        await _loyaltyController.awardProductPurchasePoints(
          customerId: customerId,
          purchaseId: orderId,
          amount: totalAmount,
          productName: _getProductNames(products),
          branchId: branchId,
          branchName: branchName,
        );

        await _firestore
            .collection('orders')
            .doc(orderId)
            .update({
          'pointsAwarded': true,
          'pointsAwardedAmount': points,
          'updatedAt': DateTime.now(),
        });

        Get.snackbar(
          'Loyalty Points Earned! 🎉',
          'You earned $points points for order #$orderNumber',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error awarding order points: $e');
      Get.snackbar(
        'Note',
        'Order placed successfully, but points awarding failed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  // Calculate points for order
  Future<int> _calculateOrderPoints(double totalAmount) async {
    try {
      if (_loyaltyController.loyaltyConfig == null) {
        await _loyaltyController.loadLoyaltyConfig();
      }

      final config = _loyaltyController.loyaltyConfig;
      if (config != null) {
        return config.calculatePoints(totalAmount);
      }
      return 0;
    } catch (e) {
      print('Error calculating order points: $e');
      return 0;
    }
  }

  // Get product names
  String _getProductNames(List<OrderProduct> products) {
    if (products.isEmpty) return 'Products';
    if (products.length == 1) return products.first.productName;
    return '${products.first.productName} and ${products.length - 1} more items';
  }

  // Update product stock
  Future<void> _updateProductStock(List<OrderProduct> orderProducts) async {
    final batch = _firestore.batch();

    for (final product in orderProducts) {
      final productRef = _firestore.collection('products').doc(product.productId);

      batch.update(productRef, {
        'totalStock': FieldValue.increment(-product.quantity),
        'totalSold': FieldValue.increment(product.quantity),
        'revenue': FieldValue.increment(product.totalPrice),
        'updatedAt': DateTime.now(),
      });
    }

    await batch.commit();
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading.value = true;

      final order = await getOrderById(orderId);
      if (order == null) {
        Get.snackbar('Error', 'Order not found');
        return false;
      }

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': DateTime.now(),
      });

      // Loyalty points awarding removed (portal e-wallet only).

      await loadAllOrders();
      if (customerId != null) {
        await loadCustomerOrders();
      }
      if (_isLoggedIn) {
        await loadUserOrders();
      }
      final notificationController = Get.find<NotificationController>();
      String title = '';
      String message = '';

      switch (newStatus) {
        case 'approved':
          title = 'Order Approved! ✅';
          message = 'Your order #${order.transactionId} has been approved.';
          break;
        case 'shipped':
          title = 'Order Shipped! 🚚';
          message = 'Your order #${order.transactionId} is on the way.';
          break;
        case 'completed':
          title = 'Order Ready for Pickup! 📬';
          message = 'Your order #${order.transactionId} is ready for pickup.';
          break;
        case 'cancelled':
          title = 'Order Cancelled ❌';
          message = 'Your order #${order.transactionId} has been cancelled.';
          break;
      }

      if (title.isNotEmpty) {
        notificationController.showInAppNotification(
          title: title,
          message: message,
          type: NotificationType.order,
          data: {
            'type': 'order',
            'orderId': orderId,
            'status': newStatus,
          },
        );
      }

      Get.snackbar(
        'Success',
        'Order status updated to $newStatus',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, String newPaymentStatus) async {
    try {
      _isLoading.value = true;

      final order = await getOrderById(orderId);
      if (order == null) {
        Get.snackbar('Error', 'Order not found');
        return false;
      }

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': newPaymentStatus,
        'updatedAt': DateTime.now(),
      });

      if (newPaymentStatus == 'paid' &&
          (order.status == 'completed' || order.status == 'approved') &&
          !order.pointsAwarded &&
          order.customerId.isNotEmpty) {

        await _awardOrderPoints(
          orderId: orderId,
          customerId: order.customerId,
          orderNumber: order.transactionId,
          totalAmount: order.totalAmount,
          branchNames: order.branchNames,
          products: order.products,
        );
      }

      await loadAllOrders();
      if (customerId != null) {
        await loadCustomerOrders();
      }
      if (_isLoggedIn) {
        await loadUserOrders();
      }

      Get.snackbar(
        'Success',
        'Payment status updated to $newPaymentStatus',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payment status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Apply filters
  List<Order> _applyFilters(List<Order> orders) {
    List<Order> filtered = List.from(orders);

    if (_filterStatus.value != 'All') {
      filtered = filtered.where((order) => order.status == _filterStatus.value).toList();
    }

    if (_filterPaymentStatus.value != 'All') {
      filtered = filtered.where((order) => order.paymentStatus == _filterPaymentStatus.value).toList();
    }

    return filtered;
  }

  // Set filters
  void setFilters({String? status, String? paymentStatus}) {
    if (status != null) _filterStatus.value = status;
    if (paymentStatus != null) _filterPaymentStatus.value = paymentStatus;
    update();
  }

  // Reset filters
  void resetFilters() {
    _filterStatus.value = 'All';
    _filterPaymentStatus.value = 'All';
    update();
  }

  // Get customer order stats
  Map<String, dynamic> getCustomerOrderStats() {
    final orders = customerOrders;

    return {
      'totalOrders': orders.length,
      'totalSpent': orders.fold(0.0, (sum, order) => sum + order.totalAmount),
      'pendingOrders': orders.where((order) => order.isPending).length,
      'completedOrders': orders.where((order) => order.isCompleted).length,
      'pointsEarned': orders.where((order) => order.pointsAwarded),
      'lastOrder': orders.isNotEmpty ? orders.first.createdAt : null,
      'averageOrderValue': orders.isNotEmpty ?
      orders.fold(0.0, (sum, order) => sum + order.totalAmount) / orders.length : 0,
    };
  }

  // Get user order stats
  Map<String, dynamic> getUserOrderStats() {
    final orders = userOrders;
    return {
      'totalOrders': orders.length,
      'totalSpent': orders.fold(0.0, (sum, order) => sum + order.totalAmount),
      'pendingOrders': orders.where((order) => order.isPending).length,
      'completedOrders': orders.where((order) => order.isCompleted).length,
      'cancelledOrders': orders.where((order) => order.isCancelled).length,
      'lastOrder': orders.isNotEmpty ? orders.first.createdAt : null,
      'averageOrderValue': orders.isNotEmpty ?
      orders.fold(0.0, (sum, order) => sum + order.totalAmount) / orders.length : 0,
    };
  }

  // Get admin order stats
  Map<String, dynamic> getAdminOrderStats() {
    return {
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'avgOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    };
  }

  // Get order loyalty summary
  Future<Map<String, dynamic>> getOrderLoyaltySummary(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        return {'error': 'Order not found'};
      }

      final points = await _calculateOrderPoints(order.totalAmount);
      final config = _loyaltyController.loyaltyConfig;

      return {
        'orderNumber': order.transactionId,
        'customerId': order.customerId,
        'customerName': order.customerName,
        'totalAmount': order.totalAmount,
        'eligibleForPoints': order.paymentStatus == 'paid' &&
            (order.status == 'completed' || order.status == 'approved'),
        'pointsEligible': points,
        'pointsAwarded': order.pointsAwarded,
        'redemptionRate': config?.redemptionRate ?? 0.03,
        'pointsValue': config != null ? config.calculateValue(points) : 0.0,
        'minimumPoints': config?.minimumPoints ?? 100,
      };
    } catch (e) {
      print('Error getting order loyalty summary: $e');
      return {'error': 'Failed to get loyalty summary'};
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final updateData = {
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
        if (reason != null && reason.isNotEmpty) 'notes': reason,
      };

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      await loadAllOrders();
      if (_isLoggedIn) {
        await loadUserOrders();
      }

      Get.snackbar(
        'Success',
        'Order cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel order: $e');
      return false;
    }
  }

  // Check and award points for completed orders
  Future<void> checkAndAwardPointsForCompletedOrders() async {
    try {
      final completedOrders = _orders
          .where((order) =>
      order.status == 'completed' &&
          order.paymentStatus == 'paid' &&
          !order.pointsAwarded &&
          order.customerId.isNotEmpty)
          .toList();

      for (final order in completedOrders) {
        await _awardOrderPoints(
          orderId: order.id,
          customerId: order.customerId,
          orderNumber: order.transactionId,
          totalAmount: order.totalAmount,
          branchNames: order.branchNames,
          products: order.products,
        );
      }

      if (completedOrders.isNotEmpty) {
        print('Awarded points for ${completedOrders.length} completed orders');
      }
    } catch (e) {
      print('Error checking and awarding points for completed orders: $e');
    }
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
        length,
            (_) => chars.codeUnitAt((chars.length * DateTime.now().microsecond) ~/ 1000000)
    ));
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadAllOrders();
    if (customerId != null) {
      await loadCustomerOrders();
    }
    if (_isLoggedIn) {
      await loadUserOrders();
    }
  }
}