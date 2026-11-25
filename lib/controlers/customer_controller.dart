import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/CustomerModel.dart';
import '../models/customer_model.dart';
import 'auth_controller.dart';

class CustomerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final Rx<CustomerModel?> _currentCustomer = Rx<CustomerModel?>(null);
  final RxList<CustomerModel> _customers = <CustomerModel>[].obs;
  final RxList<CustomerModel> _activeCustomers = <CustomerModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  CustomerModel? get currentCustomer => _currentCustomer.value;
  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get activeCustomers => _activeCustomers;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String get errorMessage => _errorMessage.value;

  // Role-based getters
  bool get isAdmin => _currentCustomer.value?.role == 'admin' ||
      _currentCustomer.value?.role == 'super_admin';
  bool get isStaff => _currentCustomer.value?.role == 'staff';
  bool get isCustomer => _currentCustomer.value?.role == 'customer';

  // Branch info
  String? get branchId => _authController.getUserBranchId();
  String? get branchName => _authController.getUserBranchName();
  bool get isBranchAdmin => _authController.isBranchAdmin;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  // ============================================================
  // 🔥 AUTHENTICATION STATE
  // ============================================================

  void _checkAuthState() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _isAuthenticated.value = true;
        loadCurrentCustomer(user.uid);
      } else {
        _isAuthenticated.value = false;
        _currentCustomer.value = null;
        _customers.clear();
        _activeCustomers.clear();
      }
    });
  }

  // ============================================================
  // 🔥 CUSTOMER LOADING METHODS
  // ============================================================

  // Load current customer from Firestore
  Future<void> loadCurrentCustomer(String uid) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final doc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();

      if (doc.exists) {
        _currentCustomer.value = CustomerModel.fromFirestore(doc);
      } else {
        await _createCustomerFromAuth(uid);
      }
    } catch (e) {
      _errorMessage.value = 'Failed to load customer: $e';
      print('Error loading customer: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Create customer from auth data
  Future<void> _createCustomerFromAuth(String uid) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final customer = CustomerModel(
        uid: uid,
        name: user.displayName ?? 'Customer',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        role: 'customer',
        status: 'active',
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('customers')
          .doc(uid)
          .set(customer.toFirestore());

      _currentCustomer.value = customer;
      print('✅ Customer created: ${customer.name}');
    } catch (e) {
      print('Error creating customer: $e');
    }
  }

  Future<void> loadBranchCustomers() async {
    if (branchName == null || branchName!.isEmpty) {
      print('⚠️ No branch name found for branch admin');
      return;
    }

    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      print("🔍 Loading customers for branch: $branchName");

      // Fetch bookings and orders in parallel
      final results = await Future.wait([
        _firestore
            .collection('bookings')
            .where('branch', isEqualTo: branchName)
            .limit(500)
            .get(),
        _firestore
            .collection('orders')
            .where('pickupBranch', isEqualTo: branchName)
            .limit(500)
            .get(),
      ]);

      final bookingsSnapshot = results[0];
      final ordersSnapshot = results[1];

      print("📊 Found ${bookingsSnapshot.docs.length} bookings for branch: $branchName");
      print("📦 Found ${ordersSnapshot.docs.length} orders for branch: $branchName");

      // Collect unique customer identifiers
      final Set<String> customerIds = {};
      final Set<String> customerNamePhoneKeys = {};

      // Process bookings
      for (final booking in bookingsSnapshot.docs) {
        final data = booking.data();
        final customerId = data['customerId'] as String?;
        final customerName = data['customerName'] as String?;
        final customerPhone = data['customerPhone'] as String?;

        // Try to get by customerId first
        if (customerId != null && customerId.isNotEmpty &&
            customerId != 'guest' && !customerId.startsWith('guest_')) {
          customerIds.add(customerId);
          print("📝 Booking has customerId: $customerId");
        }
        // If no valid customerId, use name+phone combination
        else if (customerName != null && customerName.isNotEmpty &&
            customerPhone != null && customerPhone.isNotEmpty) {
          final key = '${customerName}_${customerPhone}';
          customerNamePhoneKeys.add(key);
          print("📝 Booking has customer: $customerName (Phone: $customerPhone)");
        }
        // If only name exists (no phone), use name only
        else if (customerName != null && customerName.isNotEmpty) {
          final key = 'name_${customerName}';
          customerNamePhoneKeys.add(key);
          print("📝 Booking has customer name only: $customerName");
        }
      }

      // Process orders
      for (final order in ordersSnapshot.docs) {
        final data = order.data();
        final customerId = data['customerId'] as String?;
        final customerName = data['customerName'] as String?;
        final customerPhone = data['customerPhone'] as String?;

        if (customerId != null && customerId.isNotEmpty &&
            customerId != 'guest' && !customerId.startsWith('guest_')) {
          customerIds.add(customerId);
          print("📝 Order has customerId: $customerId");
        }
        else if (customerName != null && customerName.isNotEmpty &&
            customerPhone != null && customerPhone.isNotEmpty) {
          final key = '${customerName}_${customerPhone}';
          customerNamePhoneKeys.add(key);
          print("📝 Order has customer: $customerName (Phone: $customerPhone)");
        }
        else if (customerName != null && customerName.isNotEmpty) {
          final key = 'name_${customerName}';
          customerNamePhoneKeys.add(key);
          print("📝 Order has customer name only: $customerName");
        }
      }

      print("Found ${customerIds.length} customers with IDs");
      print("Found ${customerNamePhoneKeys.length} customers with name/phone");

      final List<CustomerModel> branchCustomers = [];

      // Fetch customers by ID
      if (customerIds.isNotEmpty) {
        final List<Future<CustomerModel?>> futures = customerIds.map((customerId) async {
          return await _findCustomerById(customerId);
        }).toList();

        final resultsList = await Future.wait(futures);
        branchCustomers.addAll(resultsList.whereType<CustomerModel>());
      }

      // Fetch customers by name and phone
      if (customerNamePhoneKeys.isNotEmpty) {
        for (final key in customerNamePhoneKeys) {
          CustomerModel? customer;

          if (key.startsWith('name_')) {
            // Search by name only
            final name = key.substring(5);
            customer = await _findCustomerByName(name);
          } else {
            // Search by name and phone
            final parts = key.split('_');
            if (parts.length >= 2) {
              final name = parts[0];
              final phone = parts[1];
              customer = await _findCustomerByNameAndPhone(name, phone);
            }
          }

          if (customer != null) {
            branchCustomers.add(customer);
          } else {
            print("⚠️ Customer not found: $key");
          }
        }
      }

      // Remove duplicates (in case same customer appears in both methods)
      final uniqueCustomers = <String, CustomerModel>{};
      for (final customer in branchCustomers) {
        if (!uniqueCustomers.containsKey(customer.uid)) {
          uniqueCustomers[customer.uid] = customer;
        }
      }

      final List<CustomerModel> finalCustomers = uniqueCustomers.values.toList();

      // Sort by last login (most recent first)
      finalCustomers.sort((a, b) => b.lastLogin.compareTo(a.lastLogin));

      _customers.assignAll(finalCustomers);
      _activeCustomers.value = finalCustomers.where((c) => c.isActive).toList();
      update();

      print("✅ Loaded ${finalCustomers.length} branch customers");
      print("   - Active: ${_activeCustomers.length}");

    } catch (e) {
      _errorMessage.value = 'Failed to load branch customers: $e';
      print("❌ Error loading branch customers: $e");
      Get.snackbar(
        'Error',
        'Failed to load branch customers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

// Helper methods to find customers (NO TEMP CREATION)
  Future<CustomerModel?> _findCustomerById(String customerId) async {
    try {
      // Check customers collection
      final customerDoc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();

      if (customerDoc.exists) {
        print("✅ Found customer by ID in customers collection: $customerId");
        return CustomerModel.fromFirestore(customerDoc);
      }

      // Check users collection
      final userDoc = await _firestore
          .collection('users')
          .doc(customerId)
          .get();

      if (userDoc.exists) {
        print("✅ Found customer by ID in users collection: $customerId");
        return CustomerModel.fromUserFirestore(userDoc);
      }

      print("❌ No customer found with ID: $customerId");
      return null;
    } catch (e) {
      print('Error finding customer by ID: $e');
      return null;
    }
  }

  Future<CustomerModel?> _findCustomerByNameAndPhone(String name, String phone) async {
    try {
      // Search in customers collection by name and phone
      final customersQuery = await _firestore
          .collection('customers')
          .where('name', isEqualTo: name)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (customersQuery.docs.isNotEmpty) {
        print("✅ Found customer by name+phone in customers collection: $name ($phone)");
        return CustomerModel.fromFirestore(customersQuery.docs.first);
      }

      // Search in users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        print("✅ Found customer by name + phone in users collection: $name ($phone)");
        return CustomerModel.fromUserFirestore(usersQuery.docs.first);
      }

      print("❌ No customer found with name: $name and phone: $phone");
      return null;
    } catch (e) {
      print('Error finding customer by name and phone: $e');
      return null;
    }
  }

  Future<CustomerModel?> _findCustomerByName(String name) async {
    try {
      // Search in customers collection by name only
      final customersQuery = await _firestore
          .collection('customers')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (customersQuery.docs.isNotEmpty) {
        print("✅ Found customer by name in customers collection: $name");
        return CustomerModel.fromFirestore(customersQuery.docs.first);
      }

      // Search in users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        print("✅ Found customer by name in users collection: $name");
        return CustomerModel.fromUserFirestore(usersQuery.docs.first);
      }

      print("❌ No customer found with name: $name");
      return null;
    } catch (e) {
      print('Error finding customer by name: $e');
      return null;
    }
  }

  // Load all customers (for super admin)
  Future<void> loadAllCustomers() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final querySnapshot = await _firestore
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final loadedCustomers = querySnapshot.docs
          .map((doc) => CustomerModel.fromFirestore(doc))
          .toList();

      _customers.assignAll(loadedCustomers);
      _activeCustomers.value = loadedCustomers
          .where((customer) => customer.isActive)
          .toList();
      update();

      print("✅ Loaded ${loadedCustomers.length} total customers");
      print("   - Active: ${_activeCustomers.length}");

    } catch (e) {
      _errorMessage.value = 'Failed to load customers: $e';
      print("Failed to load customers: $e");
      Get.snackbar(
        'Error',
        'Failed to load customers',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomerById(String customerId) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();

      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // ============================================================
  // 🔥 CUSTOMER MANAGEMENT
  // ============================================================

  // Update customer profile
  Future<bool> updateCustomerProfile({
    String? name,
    String? phone,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final currentUser = _currentCustomer.value;
      if (currentUser == null) {
        _errorMessage.value = 'No user logged in';
        return false;
      }

      final updatedCustomer = currentUser.copyWith(
        name: name ?? currentUser.name,
        phone: phone ?? currentUser.phone,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('customers')
          .doc(currentUser.uid)
          .update(updatedCustomer.toFirestore());

      _currentCustomer.value = updatedCustomer;

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update profile: $e';
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update customer status
  Future<bool> updateCustomerStatus(String customerId, bool isActive) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _firestore
          .collection('customers')
          .doc(customerId)
          .update({
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': DateTime.now(),
      });

      // Refresh the list based on role
      if (isBranchAdmin) {
        await loadBranchCustomers();
      } else {
        await loadAllCustomers();
      }

      Get.snackbar(
        'Success',
        'Customer status updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update status: $e';
      Get.snackbar(
        'Error',
        'Failed to update customer status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 SEARCH & FILTER
  // ============================================================

  // Search customers
  List<CustomerModel> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    final searchQuery = query.toLowerCase();
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(searchQuery) ||
          customer.email.toLowerCase().contains(searchQuery) ||
          customer.phone.contains(searchQuery);
    }).toList();
  }

  // Get recent customers
  List<CustomerModel> getRecentCustomers({int limit = 10}) {
    return _customers
        .where((customer) => customer.isActive)
        .take(limit)
        .toList();
  }

  // Get customers by status
  List<CustomerModel> getCustomersByStatus(String status) {
    return _customers
        .where((customer) => customer.status == status)
        .toList();
  }

  // ============================================================
  // 🔥 LOYALTY POINTS
  // ============================================================

  // Update loyalty points
  Future<void> _updateLoyaltyPoints({
    required String customerId,
    required int points,
    required String type,
    required String description,
  }) async {
    try {
      final loyaltyRef = _firestore
          .collection('loyalty')
          .doc(customerId);

      final doc = await loyaltyRef.get();

      final currentBalance = doc.exists
          ? (doc.data()?['currentBalance'] as int? ?? 0)
          : 0;

      final totalEarned = doc.exists
          ? (doc.data()?['totalEarned'] as int? ?? 0)
          : 0;

      final totalRedeemed = doc.exists
          ? (doc.data()?['totalRedeemed'] as int? ?? 0)
          : 0;

      int newBalance = currentBalance;
      int newTotalEarned = totalEarned;
      int newTotalRedeemed = totalRedeemed;

      if (type == 'earned' || type == 'bonus') {
        newBalance += points;
        newTotalEarned += points;
      } else if (type == 'redeemed') {
        newBalance -= points;
        newTotalRedeemed += points;
      }

      await loyaltyRef.set({
        'currentBalance': newBalance,
        'totalEarned': newTotalEarned,
        'totalRedeemed': newTotalRedeemed,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Add transaction record
      await _firestore
          .collection('loyaltyTransactions')
          .doc(customerId)
          .collection('transactions')
          .add({
        'date': Timestamp.now(),
        'type': type,
        'description': description,
        'points': points,
        'balance': newBalance,
      });

      print('✅ Loyalty points updated: $type $points points for $customerId');

    } catch (e) {
      print('Error updating loyalty points: $e');
    }
  }

  // Get customer loyalty summary
  Future<LoyaltySummary> getLoyaltySummary(String customerId) async {
    try {
      final doc = await _firestore
          .collection('loyalty')
          .doc(customerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return LoyaltySummary(
          currentBalance: data['currentBalance'] ?? 0,
          earnedThisMonth: data['earnedThisMonth'] ?? 0,
          totalRedeemed: data['totalRedeemed'] ?? 0,
          totalEarned: data['totalEarned'] ?? 0,
        );
      }

      return LoyaltySummary(
        currentBalance: 0,
        earnedThisMonth: 0,
        totalRedeemed: 0,
        totalEarned: 0,
      );
    } catch (e) {
      print('Error getting loyalty summary: $e');
      return LoyaltySummary(
        currentBalance: 0,
        earnedThisMonth: 0,
        totalRedeemed: 0,
        totalEarned: 0,
      );
    }
  }

  // Redeem loyalty points
  Future<bool> redeemPoints({
    required int points,
    required String description,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final customer = _currentCustomer.value;
      if (customer == null) {
        _errorMessage.value = 'No user logged in';
        return false;
      }

      final loyaltySummary = await getLoyaltySummary(customer.uid);

      if (points > loyaltySummary.currentBalance) {
        _errorMessage.value = 'Insufficient points';
        Get.snackbar(
          'Error',
          'Insufficient points',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      await _updateLoyaltyPoints(
        customerId: customer.uid,
        points: points,
        type: 'redeemed',
        description: description,
      );

      Get.snackbar(
        'Success',
        'Points redeemed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to redeem points: $e';
      Get.snackbar(
        'Error',
        'Failed to redeem points',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 HELPER METHODS
  // ============================================================

  // Refresh customer data
  Future<void> refreshCustomerData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await loadCurrentCustomer(user.uid);
    }

    if (isBranchAdmin) {
      await loadBranchCustomers();
    } else {
      await loadAllCustomers();
    }
  }

  // Check if customer exists
  Future<bool> customerExists(String uid) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking customer existence: $e');
      return false;
    }
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final bookings = await _getCustomerBookings(customerId);
      final loyaltySummary = await getLoyaltySummary(customerId);

      final totalSpent = bookings.fold(0.0, (sum, booking) => sum + booking.amount);
      final totalBookings = bookings.length;
      final completedBookings = bookings.where((b) => b.status == 'completed').length;

      return {
        'totalSpent': totalSpent,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'loyaltyPoints': loyaltySummary.currentBalance,
        'averageSpending': totalBookings > 0 ? totalSpent / totalBookings : 0,
        'lastBooking': bookings.isNotEmpty ? bookings.first.date : null,
      };
    } catch (e) {
      print('Error getting customer stats: $e');
      return {
        'totalSpent': 0.0,
        'totalBookings': 0,
        'completedBookings': 0,
        'loyaltyPoints': 0,
        'averageSpending': 0.0,
        'lastBooking': null,
      };
    }
  }

  // Get customer bookings (private helper)
  Future<List<BookingHistory>> _getCustomerBookings(String customerId) async {
    try {
      final bookingsRef = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('date', descending: true)
          .get();

      return bookingsRef.docs
          .map((doc) {
        final data = doc.data();
        return BookingHistory(
          bookingId: doc.id,
          date: (data['date'] as Timestamp).toDate(),
          service: data['serviceName'] ?? '',
          staff: data['staffName'] ?? '',
          status: data['status'] ?? 'completed',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          pointsEarned: data['pointsEarned'] ?? 0,
        );
      })
          .toList();
    } catch (e) {
      print('Error getting bookings: $e');
      return [];
    }
  }

  // ============================================================
  // 🔥 CLEANUP
  // ============================================================

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentCustomer.value = null;
      _isAuthenticated.value = false;
      _customers.clear();
      _activeCustomers.clear();
      _errorMessage.value = '';

      Get.offAllNamed('/login');
    } catch (e) {
      _errorMessage.value = 'Failed to sign out: $e';
      Get.snackbar(
        'Error',
        'Failed to sign out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// ============================================================
// 🔥 MODEL CLASSES
// ============================================================

class BookingHistory {
  final String bookingId;
  final DateTime date;
  final String service;
  final String staff;
  final String status;
  final double amount;
  final int pointsEarned;

  BookingHistory({
    required this.bookingId,
    required this.date,
    required this.service,
    required this.staff,
    required this.status,
    required this.amount,
    required this.pointsEarned,
  });
}

class LoyaltySummary {
  final int currentBalance;
  final int earnedThisMonth;
  final int totalRedeemed;
  final int totalEarned;

  LoyaltySummary({
    required this.currentBalance,
    required this.earnedThisMonth,
    required this.totalRedeemed,
    required this.totalEarned,
  });
}