// controllers/admin_booking_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:man_of_cave/controlers/auth_controller.dart';
import '../models/booking_model.dart';

class AdminBookingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive lists
  final RxList<Booking> _allBookings = <Booking>[].obs;
  final RxList<Booking> _filteredBookings = <Booking>[].obs;
  final RxList<Booking> _branchBookings=<Booking>[].obs;

  // Filters
  final RxString _selectedFilter = 'all'.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isLoading = false.obs;

  // Statistics
  final RxInt _pendingCount = 0.obs;
  final RxInt _confirmedCount = 0.obs;
  final RxInt _inProgressCount = 0.obs;
  final RxInt _completedCount = 0.obs;
  final RxInt _cancelledCount = 0.obs;

  // Getters
  List<Booking> get allBookings => _allBookings;
  List<Booking> get filteredBookings => _filteredBookings;
  List<Booking> get branchBookings =>_branchBookings;

  String get selectedFilter => _selectedFilter.value;
  bool get isLoading => _isLoading.value;

  int get pendingCount => _pendingCount.value;
  int get confirmedCount => _confirmedCount.value;
  int get inProgressCount => _inProgressCount.value;
  int get completedCount => _completedCount.value;
  int get cancelledCount => _cancelledCount.value;
  int get totalCount => authController.isBranchAdmin ? _branchBookings.length : _allBookings.length;

  final AuthController authController=Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    
    // Only proceed if user is an admin
    if (authController.isAdmin) {
      authController.isBranchAdmin ? loadBranchBookings() : loadBookings();
      // Setup real-time listener
      _setupRealTimeListener();
    }
  }

  Future<void> loadBranchBookings() async{
    try{
      _isLoading.value=true;
      final querySnapshot= await _firestore
      .collection('bookings')
      .where('branch',isEqualTo: authController.getUserBranchName())
      .orderBy('createdAt',descending: true)
      .get();

      final loadedBranchBookings=querySnapshot.docs
      .map((doc) =>Booking.fromFirestore(doc)).toList();

      _branchBookings.assignAll(loadedBranchBookings);
      _calculateStatistics();
      _applyFilters();
      update();
    }catch(e){
      Get.snackbar(
        'Error',
        'Failed to load branch bookings: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    finally {
      _isLoading.value = false;
    }
  }
  // Load all bookings
  Future<void> loadBookings() async {
    try {
      _isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      final loadedBookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _allBookings.assignAll(loadedBookings);
      _calculateStatistics();
      _applyFilters();

      update();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load bookings: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Setup real-time listener
  void _setupRealTimeListener() {
    _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final updatedBookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _allBookings.assignAll(updatedBookings);
      _calculateStatistics();
      _applyFilters();
      update();
    });
  }

  // Calculate statistics
  void _calculateStatistics() {
    _pendingCount.value = authController.isBranchAdmin ?
    _branchBookings.where((b) => b.isPending).length
        : _allBookings.where((b) => b.isPending).length;

    _confirmedCount.value = authController.isBranchAdmin
        ? _branchBookings.where((b) => b.isConfirmed).length
        : _allBookings.where((b) => b.isConfirmed).length;

    _inProgressCount.value = authController.isBranchAdmin
        ? _branchBookings.where((b) => b.isInProgress).length
        : _allBookings.where((b) => b.isInProgress).length;

    _completedCount.value = authController.isBranchAdmin
        ? _branchBookings.where((b) => b.isCompleted).length
        : _allBookings.where((b) => b.isCompleted).length;

    _cancelledCount.value =  authController.isBranchAdmin
        ? _branchBookings.where((b) => b.isCancelled).length
        : _allBookings.where((b) => b.isCancelled).length;
  }
  // Apply filters
  void _applyFilters() {
    List<Booking> filtered = authController.isBranchAdmin ? _branchBookings : _allBookings;

    // Filter by status
    if (_selectedFilter.value != 'all') {
      filtered = filtered.where((booking) => booking.status == _selectedFilter.value).toList();
    }

    // Filter by search query
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((booking) =>
      booking.customerName.toLowerCase().contains(query) ||
          booking.bookingNumber.toLowerCase().contains(query) ||
          booking.serviceName.toLowerCase().contains(query) ||
          booking.staffName.toLowerCase().contains(query)
      ).toList();
    }

    _filteredBookings.assignAll(filtered);
  }

  // Change filter
  void changeFilter(String filter) {
    _selectedFilter.value = filter.toLowerCase();
    _applyFilters();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  // Update booking status
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      Get.snackbar(
        'Success',
        'Booking status updated to ${status.replaceAll('-', ' ')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update booking status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Keep as upcoming (portal has no separate "approved" status)
  Future<bool> approveBooking(String bookingId) async {
    return await updateBookingStatus(
      bookingId: bookingId,
      status: 'upcoming',
      notes: 'Booking confirmed by admin',
    );
  }

  // Start booking (in-progress / check-in)
  Future<bool> startBooking(String bookingId) async {
    return await updateBookingStatus(
      bookingId: bookingId,
      status: 'in-progress',
      notes: 'Service started',
    );
  }

  // Close booking (portal canonical: closed)
  Future<bool> completeBooking(String bookingId) async {
    return await updateBookingStatus(
      bookingId: bookingId,
      status: 'closed',
      notes: 'Service completed',
    );
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    return await updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
      notes: reason ?? 'Booking cancelled by admin',
    );
  }

  // Assign staff to booking
  Future<bool> assignStaff({
    required String bookingId,
    required String staffId,
    required String staffName,
    required String staffRole,
  }) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'staffId': staffId,
        'staffName': staffName,
        'staffRole': staffRole,
        'status': 'upcoming',
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Staff assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign staff: $e');
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    String? paymentMethod,
    String? trnNumber,
  }) async {
    try {
      final updateData = {
        'paymentStatus': paymentStatus,
        'updatedAt': Timestamp.now(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (trnNumber != null) 'trnNumber': trnNumber,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      Get.snackbar(
        'Success',
        'Payment status updated to $paymentStatus',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update payment status: $e');
      return false;
    }
  }

  // Get available branches for filtering
  List<String> getAvailableBranches() {
    final branches = <String>{'all'};

    for (final booking in _allBookings) {
      if (booking.branch.isNotEmpty) {
        branches.add(booking.branch);
      }
    }

    return branches.toList()..sort();
  }

  String getRevenueBasedOnRole(){
    return
      authController.isBranchAdmin ?
      branchBookings.where((b) => b.isCompleted).fold(0.0, (sum, b) => sum + b.totalAmount).toStringAsFixed(0)
          : allBookings.where((b) => b.isCompleted).fold(0.0, (sum, b) => sum + b.totalAmount).toStringAsFixed(0);
  }
  // Get today's bookings
  List<Booking> getTodaysBookings() {
    return authController.isBranchAdmin ? _branchBookings.where((booking) => booking.isToday).toList() : _allBookings.where((booking) => booking.isToday).toList();
  }

  // Get upcoming bookings
  List<Booking> getUpcomingBookings() {
    return authController.isBranchAdmin ? _branchBookings.where((booking) => booking.isUpcoming).toList() : _allBookings.where((booking) => booking.isUpcoming).toList();
  }

  // Refresh bookings
  Future<void> refreshBookings() async {
    authController.isBranchAdmin ? loadBranchBookings() : loadBookings();
  }

  // Export bookings data
  List<Map<String, dynamic>> exportBookings() {
    return _allBookings.map((booking) {
      return {
        'Booking Number': booking.bookingNumber,
        'Customer': booking.customerName,
        'Phone': booking.customerPhone,
        'Email': booking.customerEmail,
        'Service': booking.serviceName,
        'Date': booking.formattedDate,
        'Time': booking.formattedTime,
        'Staff': booking.staffName,
        'Branch': booking.branch,
        'Status': booking.status,
        'Payment Status': booking.paymentStatus,
        'Amount': booking.totalAmount,
      };
    }).toList();
  }
}