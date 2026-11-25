// controllers/admin_order_controller.dart - Updated with pickup branch
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/order_model.dart';

class AdminOrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive lists
  final RxList<Order> _orders = <Order>[].obs;

  // Filters
  final RxString _filterStatus = 'All'.obs;
  final RxString _filterPaymentStatus = 'All'.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Order> get allOrders => _orders;
  List<Order> get filteredOrders => _applyFilters();
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Statistics
  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((order) => order.isPending).length;
  int get completedOrders => _orders.where((order) => order.isCompleted).length;
  int get cancelledOrders => _orders.where((order) => order.isCancelled).length;
  double get totalRevenue => _orders.fold(0.0, (sum, order) => sum + order.totalAmount);

  @override
  void onInit() {
    super.onInit();
    loadAllOrders();
  }

  // Load all orders with error handling
  Future<void> loadAllOrders() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      print('Loading orders from Firestore...');

      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} orders');

      final loadedOrders = <Order>[];

      for (final doc in querySnapshot.docs) {
        try {
          final order = Order.fromFirestore(doc);
          loadedOrders.add(order);
        } catch (e) {
          print('Error parsing order ${doc.id}: $e');
          print('Document data: ${doc.data()}');

          // Try to load with default values using the new model
          final order = _createOrderFromMap(doc.id, doc.data() ?? {});
          loadedOrders.add(order);
        }
      }

      _orders.assignAll(loadedOrders);
      print('Successfully loaded ${_orders.length} orders');

    } catch (e) {
      _errorMessage.value = 'Failed to load orders: $e';
      Get.snackbar(
        'Error',
        'Failed to load orders',
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Error loading orders: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  // Fallback method to create order from raw map data (updated with pickup branch)
  Order _createOrderFromMap(String docId, Map<String, dynamic> data) {
    final now = DateTime.now();

    // Parse products safely
    final productsData = data['products'] as List<dynamic>? ?? [];
    final products = productsData
        .whereType<Map<String, dynamic>>()
        .map((productData) {
      return OrderProduct(
        productId: productData['productId']?.toString() ?? '',
        productName: productData['productName']?.toString() ?? '',
        productImage: productData['productImage']?.toString() ?? '',
        productCategory: productData['productCategory']?.toString() ?? '',
        productCategoryId: productData['productCategoryId']?.toString() ?? '',
        price: (productData['price'] as num?)?.toDouble() ?? 0.0,
        productCost: (productData['productCost'] as num?)?.toDouble() ?? 0.0,
        productSku: productData['productSku']?.toString() ?? '',
        quantity: (productData['quantity'] as num?)?.toInt() ?? 1,
        productBranches: List<String>.from(productData['productBranches'] ?? []),
        productBranchNames: List<String>.from(productData['productBranchNames'] ?? []),
      );
    })
        .toList();

    return Order(
      id: docId,
      transactionId: data['transactionId']?.toString() ?? 'TXN-${now.millisecondsSinceEpoch}',
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? 'Unknown Customer',
      customerEmail: data['customerEmail']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      products: products,
      branchNames: List<String>.from(data['branchNames'] ?? []),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString() ?? 'cash',
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      orderDate: data['orderDate']?.toString() ?? _formatDate(now),
      expectedDeliveryDate: data['expectedDeliveryDate']?.toString() ?? _formatDate(now.add(Duration(days: 7))),
      orderNotes: data['orderNotes']?.toString(),
      pointsAwarded: data['pointsAwarded'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']) ?? now,
      updatedAt: _parseTimestamp(data['updatedAt']) ?? now,
      // Pickup branch fields
      pickupBranch: data['pickupBranch']?.toString() ?? '',
      pickupBranchAddress: data['pickupBranchAddress']?.toString() ?? '',
      pickupBranchPhone: data['pickupBranchPhone']?.toString() ?? '',
      pickupBranchTiming: data['pickupBranchTiming']?.toString() ?? '',
    );
  }

  // Helper method to parse timestamp safely
  DateTime? _parseTimestamp(dynamic timestampData) {
    try {
      if (timestampData == null) return null;

      if (timestampData is Timestamp) {
        return timestampData.toDate();
      }

      if (timestampData is DateTime) {
        return timestampData;
      }

      return null;
    } catch (e) {
      print('Error parsing timestamp: $e');
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Apply filters
  List<Order> _applyFilters() {
    List<Order> filtered = List.from(_orders);

    if (_filterStatus.value != 'All') {
      filtered = filtered.where((order) => order.status.toLowerCase() == _filterStatus.value.toLowerCase()).toList();
    }

    if (_filterPaymentStatus.value != 'All') {
      filtered = filtered.where((order) => order.paymentStatus.toLowerCase() == _filterPaymentStatus.value.toLowerCase()).toList();
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

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadAllOrders();

      Get.snackbar(
        'Success',
        'Order status updated to $newStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': newPaymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadAllOrders();

      Get.snackbar(
        'Success',
        'Payment status updated to $newPaymentStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payment status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
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

  // Get orders by customer ID
  List<Order> getOrdersByCustomer(String customerId) {
    return _orders.where((order) => order.customerId == customerId).toList();
  }

  // Get today's orders
  List<Order> getTodaysOrders() {
    final today = DateTime.now().toLocal().toString().split(' ')[0];
    return _orders.where((order) => order.orderDate == today).toList();
  }

  // Get this month's orders
  List<Order> getThisMonthOrders() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    return _orders.where((order) {
      return order.orderDate.startsWith('$year-$month');
    }).toList();
  }

  // Get orders by date range
  List<Order> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders.where((order) {
      try {
        final orderDate = DateTime.parse(order.orderDate);
        return orderDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get orders by pickup branch
  List<Order> getOrdersByPickupBranch(String branchName) {
    return _orders.where((order) => order.pickupBranch == branchName).toList();
  }

  // Get pickup branch statistics
  Map<String, int> getPickupBranchStatistics() {
    final branchStats = <String, int>{};

    for (final order in _orders) {
      if (order.pickupBranch.isNotEmpty) {
        branchStats[order.pickupBranch] = (branchStats[order.pickupBranch] ?? 0) + 1;
      }
    }

    return branchStats;
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadAllOrders();
  }

  // Export orders data (updated with pickup branch)
  List<Map<String, dynamic>> exportOrders() {
    return _orders.map((order) {
      return {
        'Order ID': order.transactionId,
        'Customer': order.customerName,
        'Email': order.customerEmail,
        'Phone': order.customerPhone,
        'Date': order.orderDate,
        'Status': order.status,
        'Payment Status': order.paymentStatus,
        'Payment Method': order.paymentMethod,
        'Total Amount': order.totalAmount,
        'Items': order.totalItems,
        'Pickup Branch': order.pickupBranch,
        'Pickup Address': order.pickupBranchAddress,
        'Pickup Hours': order.pickupBranchTiming,
        'Products': order.products.map((p) => '${p.productName} x${p.quantity}').join(', '),
      };
    }).toList();
  }

  // Get order statistics by date
  Map<String, double> getRevenueByDate() {
    final revenueMap = <String, double>{};

    for (final order in _orders) {
      if (order.isCompleted && order.isPaid) {
        final dateKey = order.orderDate;
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0) + order.totalAmount;
      }
    }

    return revenueMap;
  }

  // Get top products
  Map<String, int> getTopProducts({int limit = 10}) {
    final productCount = <String, int>{};

    for (final order in _orders) {
      for (final product in order.products) {
        final productName = product.productName;
        productCount[productName] = (productCount[productName] ?? 0) + product.quantity;
      }
    }

    // Sort by quantity descending
    final sortedEntries = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(limit));
  }

  // Get branch revenue statistics
  Map<String, double> getBranchRevenue() {
    final branchRevenue = <String, double>{};

    for (final order in _orders) {
      if (order.pickupBranch.isNotEmpty && (order.isCompleted || order.isPaid)) {
        branchRevenue[order.pickupBranch] = (branchRevenue[order.pickupBranch] ?? 0) + order.totalAmount;
      }
    }

    return branchRevenue;
  }
}