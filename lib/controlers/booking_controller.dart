import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../utils/safe_firestore.dart';
import 'loyalty_points_controller.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';

class BookingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoyaltyController _loyaltyController = Get.find<LoyaltyController>();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final RxList<Booking> _allBookings = <Booking>[].obs;
  final RxList<Booking> _userBookings = <Booking>[].obs;
  final RxList<Booking> _filteredBookings = <Booking>[].obs;
  final RxString _selectedFilter = 'all'.obs;
  final RxString _selectedDate = 'all'.obs;
  final RxString _selectedBranch = 'all'.obs;
  final RxString _selectedStatus = 'all'.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Statistics
  final RxMap<String, int> _bookingStats = <String, int>{}.obs;
  final RxMap<String, double> _revenueStats = <String, double>{}.obs;

  // Current user info
  String? get _currentUserId => _authController.currentUser.value?.uid;
  bool get _isLoggedIn => _authController.isLoggedIn.value;

  // Getters
  List<Booking> get allBookings => _allBookings;
  List<Booking> get userBookings => _userBookings;
  List<Booking> get filteredBookings => _filteredBookings;
  String get selectedFilter => _selectedFilter.value;
  String get selectedDate => _selectedDate.value;
  String get selectedBranch => _selectedBranch.value;
  String get selectedStatus => _selectedStatus.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Map<String, int> get bookingStats => _bookingStats;
  Map<String, double> get revenueStats => _revenueStats;

  @override
  void onInit() {
    super.onInit();

    // Load bookings only after login — never at cold start for guests.
    ever(_authController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        loadUserBookings();
        if (_authController.isAdmin) {
          loadBookings();
        }
      } else {
        _userBookings.clear();
        _allBookings.clear();
      }
    });
  }

  // Load all bookings from Firestore (for admin)
  Future<void> loadBookings() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final querySnapshot = await SafeFirestore.getQuery(
        _firestore
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .limit(80),
      );

      final loadedBookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _allBookings.assignAll(loadedBookings);
      _calculateStatistics();
      _applyFilters();

      update();
    } catch (e) {
      _errorMessage.value = 'Failed to load bookings: $e';
      print('❌ loadBookings: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // ========== NEW FUNCTION: Load bookings for a specific date ==========
  /// Load bookings for a specific date using the bookingDate field
  /// This is used in Time Selection Screen to check available slots
  Future<List<Booking>> loadBookingsForDate({
    required DateTime date,
    String? branchName,
  }) async {
    try {
      _isLoading.value = true;

      // Format date to match Firestore bookingDate field format (YYYY-MM-DD)
      final formattedDate = _formatDateForQuery(date);

      // Build query
      Query query = _firestore
          .collection('bookings')
          .where('bookingDate', isEqualTo: formattedDate)
          .where('status', whereIn: ['upcoming', 'approved', 'confirmed', 'pending', 'in-progress']); // Active (+ legacy)

      // If branch name is provided, filter by branch
      if (branchName != null && branchName.isNotEmpty) {
        query = query.where('branch', isEqualTo: branchName);
      }

      final querySnapshot = await query.get();

      final bookingsForDate = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      print('📅 Found ${bookingsForDate.length} bookings for date: $formattedDate');

      return bookingsForDate;
    } catch (e) {
      print('❌ Error loading bookings for date: $e');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  // Helper method to format date for Firestore query
  String _formatDateForQuery(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Load current user's bookings from Firestore
  Future<void> loadUserBookings() async {
    try {
      if (!_isLoggedIn || _currentUserId == null) {
        _userBookings.clear();
        return;
      }

      final querySnapshot = await SafeFirestore.getQuery(
        _firestore
            .collection('bookings')
            .where('customerId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(50),
      );

      final loadedBookings = querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      _userBookings.assignAll(loadedBookings);
      update();
    } catch (e) {
      print('Error loading user bookings: $e');
      if (e.toString().contains('The query requires an index')) {
        print('Firestore index required for user bookings query');
      }
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Get booking by booking number
  Future<Booking?> getBookingByNumber(String bookingNumber) async {
    try {
      final query = await _firestore
          .collection('bookings')
          .where('bookingNumber', isEqualTo: bookingNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Booking.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting booking by number: $e');
      return null;
    }
  }

  // Create a new booking with loyalty points
  Future<String?> createBooking({
    required String customerName,
    required String customerEmail,
    required String status,
    required String customerPhone,
    required String serviceId,
    required String serviceName,
    required double servicePrice,
    required int serviceDuration,
    required String serviceCategory,
    required String serviceCategoryId,
    required String date,
    required String time,
    required String timeSlot,
    required String staffId,
    required String staffName,
    required String staffRole,
    required String branch,
    required String branchId,
    required String userBranchId,
    required String userBranchName,
    String customerId = '',
    String source = 'admin_panel',
    String createdBy = '',
    String notes = '',
    String bookingDate = '',
    String bookingTime = '',
    String bookingNumber = '',
    double subtotal = 0,
    double serviceCharges = 0,
    double tax = 0,
    double taxAmount = 0,
    double discount = 0,
    double discountAmount = 0,
    String discountType = 'fixed',
    double tip = 0,
    double serviceTip = 0,
    String paymentMethod = 'cash',
    String paymentStatus = 'pending',
    List<dynamic> products = const [],
    double productsTotal = 0,
    List<Map<String, dynamic>> teamMembers = const [],
  }) async {
    try {
      _isLoading.value = true;

      // Generate a unique booking ID
      final bookingId = _firestore.collection('bookings').doc().id;

      // Generate booking number if not provided
      final bookingNum = bookingNumber.isNotEmpty
          ? bookingNumber
          : 'BOOK-${DateTime.now().millisecondsSinceEpoch}';

      // Use provided bookingDate/time or current date/time
      final bookDate = bookingDate.isNotEmpty ? bookingDate : date;
      final bookTime = bookingTime.isNotEmpty ? bookingTime : time;

      // Calculate total amount
      final totalAmount = servicePrice + serviceCharges + taxAmount - discountAmount + tip;

      // Use current user ID if customerId is empty
      final finalCustomerId = customerId.isNotEmpty ? customerId : (_currentUserId ?? '');

      // Create booking data
      final bookingData = {
        'id': bookingId,
        'bookingNumber': bookingNum,
        'bookingDate': bookDate,
        'bookingTime': bookTime,

        // Customer details
        'customerId': finalCustomerId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,

        // Booking details
        'date': date,
        'time': time,
        'timeSlot': timeSlot,
        'totalAmount': totalAmount,
        'status': 'upcoming', // Initial status
        'notes': notes,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'pointsAwarded': false,
        'source': source,
        'createdBy': createdBy,

        // Payment details
        'subtotal': subtotal,
        'serviceCharges': serviceCharges,
        'tax': tax,
        'taxAmount': taxAmount,
        'discount': discount,
        'discountAmount': discountAmount,
        'discountType': discountType,
        'tip': tip,
        'totalTips': tip + serviceTip,
        'serviceTip': serviceTip,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentAmounts': {
          paymentMethod: totalAmount
        },
        'trnNumber': '',
        'cardLast4Digits': '',

        // Service details
        'serviceId': serviceId,
        'serviceName': serviceName,
        'servicePrice': servicePrice,
        'serviceDuration': serviceDuration,
        'serviceCategory': serviceCategory,
        'serviceCategoryId': serviceCategoryId,
        'services': [serviceName],
        'totalDuration': serviceDuration,

        // Staff details
        'staffId': staffId,
        'staffName': staffName,
        'staffRole': staffRole,
        'teamMembers': teamMembers,

        // Branch details
        'branch': branch,
        'branchId': branchId,
        'branches': [branch],
        'branchNames': [branch],
        'userBranchId': userBranchId,
        'userBranchName': userBranchName,
        'userRole': 'admin',

        // Product details
        'products': products,
        'productsTotal': productsTotal,
      };

      // Save booking to Firestore
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .set(bookingData);

      // Refresh bookings list
      await loadBookings();
      if (_isLoggedIn) {
        await loadUserBookings();
      }
      if (bookingId != null) {
        // Show in-app notification
        final notificationController = Get.find<NotificationController>();
        notificationController.showInAppNotification(
          title: 'Booking Placed! 📅',
          message: 'Your booking for $serviceName has been placed successfully.',
          type: NotificationType.booking,
          data: {
            'type': 'booking',
            'bookingId': bookingId,
            'bookingNumber': bookingNum,
          },
        );
      }

      Get.snackbar(
        'Success',
        'Booking created successfully: $bookingNum',
        snackPosition: SnackPosition.BOTTOM,
      );

      return bookingId;
    } catch (e) {
      _errorMessage.value = 'Failed to create booking: $e';
      Get.snackbar(
        'Error',
        'Failed to create booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

// In BookingController's updateBookingStatus method
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    String? notes,
    bool? pointsAwarded,
    String? paymentStatus,
    double? tip,
    double? serviceTip,
    List<Map<String, dynamic>>? teamMembers,
  }) async {
    try {
      _isLoading.value = true;

      // Get booking details before update
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        _errorMessage.value = 'Booking not found';
        return false;
      }

      final updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
        if (notes != null) 'notes': notes,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (tip != null) 'tip': tip,
        if (serviceTip != null) 'serviceTip': serviceTip,
        if (teamMembers != null) 'teamMembers': teamMembers,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      // Loyalty points awarding removed (portal e-wallet only).

      // Refresh bookings list
      await loadBookings();
      if (_isLoggedIn) {
        await loadUserBookings();
      }

        final notificationController = Get.find<NotificationController>();
        String title = '';
        String message = '';

        switch (status) {
          case 'upcoming':
          case 'approved':
          case 'confirmed':
            title = 'Booking Updated 📅';
            message = 'Your booking for ${booking.serviceName} is scheduled.';
            break;
          case 'in-progress':
            title = 'Service Started 🔄';
            message = 'Your ${booking.serviceName} service has started.';
            break;
          case 'closed':
          case 'completed':
            title = 'Service Completed ✨';
            message = 'Thank you for visiting! Hope you enjoyed your ${booking.serviceName}.';
            break;
          case 'cancelled':
            title = 'Booking Cancelled ❌';
            message = 'Your booking for ${booking.serviceName} has been cancelled.';
            break;
        }

        if (title.isNotEmpty) {
          notificationController.showInAppNotification(
            title: title,
            message: message,
            type: NotificationType.booking,
            data: {
              'type': 'booking',
              'bookingId': bookingId,
              'status': status,
            },
          );
        }

      Get.snackbar(
        'Success',
        'Booking status updated to ${status.replaceAll('-', ' ')}',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update booking status: $e';
      Get.snackbar(
        'Error',
        'Failed to update booking status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Check and award points for confirmed bookings
  Future<void> checkAndAwardPointsForConfirmedBookings() async {
    try {
      // Get all bookings that are confirmed but points not awarded
      final confirmedBookings = _allBookings
          .where((booking) =>
      booking.status == 'approved' &&
          !booking.pointsAwarded &&
          booking.customerId.isNotEmpty)
          .toList();

      for (final booking in confirmedBookings) {
        await _awardBookingPoints(
          bookingId: booking.id,
          customerId: booking.customerId,
          serviceName: booking.serviceName,
          amount: booking.servicePrice + booking.productsTotal,
          branchId: booking.branchId,
          branchName: booking.branch,
        );
      }

      if (confirmedBookings.isNotEmpty) {
        print('Awarded points for ${confirmedBookings.length} approved bookings');
      }
    } catch (e) {
      print('Error checking and awarding points for approved bookings: $e');
    }
  }

  // Update booking payment details with loyalty points
  Future<bool> updateBookingPayment({
    required String bookingId,
    required String paymentMethod,
    required String paymentStatus,
    double? tip,
    double? serviceTip,
    String? trnNumber,
    String? cardLast4Digits,
    Map<String, dynamic>? paymentAmounts,
  }) async {
    try {
      // Get booking details before update
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        _errorMessage.value = 'Booking not found';
        return false;
      }

      final updateData = {
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'updatedAt': Timestamp.now(),
        if (tip != null) 'tip': tip,
        if (serviceTip != null) 'serviceTip': serviceTip,
        if (trnNumber != null) 'trnNumber': trnNumber,
        if (cardLast4Digits != null) 'cardLast4Digits': cardLast4Digits,
        if (paymentAmounts != null) 'paymentAmounts': paymentAmounts,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      // Award loyalty points when payment is completed and booking is completed/confirmed
      if (paymentStatus == 'paid' &&
          (booking.status == 'completed' || booking.status == 'approved') &&
          !booking.pointsAwarded &&
          booking.customerId.isNotEmpty) {

        await _awardBookingPoints(
          bookingId: bookingId,
          customerId: booking.customerId,
          serviceName: booking.serviceName,
          amount: booking.servicePrice + booking.productsTotal,
          branchId: booking.branchId,
          branchName: booking.branch,
        );
      }

      // Refresh bookings list
      await loadBookings();
      if (_isLoggedIn) {
        await loadUserBookings();
      }

      Get.snackbar(
        'Success',
        'Payment details updated',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update payment details: $e');
      return false;
    }
  }

  // Award loyalty points for booking
  Future<void> _awardBookingPoints({
    required String bookingId,
    required String customerId,
    required String serviceName,
    required double amount,
    String? branchId,
    String? branchName,
  }) async {
    try {
      // Award points using LoyaltyController
      await _loyaltyController.awardServiceBookingPoints(
        customerId: customerId,
        bookingId: bookingId,
        amount: amount,
        serviceName: serviceName,
        branchId: branchId,
        branchName: branchName,
      );

      // Mark booking as points awarded
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'pointsAwarded': true,
        'updatedAt': Timestamp.now(),
      });

      // Show points notification
      Get.snackbar(
        'Loyalty Points Awarded! 🎉',
        'Customer earned points for booking #$bookingId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

    } catch (e) {
      print('Error awarding booking points: $e');
      // Don't fail the booking update if points awarding fails
      Get.snackbar(
        'Note',
        'Booking processed but points awarding failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // Assign staff to booking
  Future<bool> assignStaffToBooking({
    required String bookingId,
    required String staffId,
    required String staffName,
    required String staffRole,
    List<Map<String, dynamic>>? teamMembers,
  }) async {
    try {
      final updateData = {
        'staffId': staffId,
        'staffName': staffName,
        'staffRole': staffRole,
        'status': 'approved',
        'updatedAt': Timestamp.now(),
        if (teamMembers != null) 'teamMembers': teamMembers,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      await loadBookings();
      if (_isLoggedIn) {
        await loadUserBookings();
      }

      Get.snackbar(
        'Success',
        'Staff assigned to booking',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign staff: $e');
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final updateData = {
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
        if (reason != null && reason.isNotEmpty) 'notes': reason,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      await loadBookings();
      if (_isLoggedIn) {
        await loadUserBookings();
      }

      Get.snackbar(
        'Success',
        'Booking cancelled successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel booking: $e');
      return false;
    }
  }

  // Get bookings by customer ID
  List<Booking> getBookingsByCustomer(String customerId) {
    return _allBookings
        .where((booking) => booking.customerId == customerId)
        .toList();
  }

  // Get bookings by service ID
  List<Booking> getBookingsByService(String serviceId) {
    return _allBookings
        .where((booking) => booking.serviceId == serviceId)
        .toList();
  }

  // Get bookings by staff ID
  List<Booking> getBookingsByStaff(String staffId) {
    return _allBookings
        .where((booking) => booking.staffId == staffId)
        .toList();
  }

  // Get bookings by branch
  List<Booking> getBookingsByBranch(String branch) {
    return _allBookings
        .where((booking) => booking.branch == branch || booking.branchNames.contains(branch))
        .toList();
  }

  // Get bookings by date range
  List<Booking> getBookingsByDateRange(DateTime startDate, DateTime endDate) {
    return _allBookings
        .where((booking) {
      try {
        final bookingDate = booking.serviceDateTime;
        return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            bookingDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    })
        .toList();
  }

  // Get today's bookings
  List<Booking> getTodaysBookings() {
    return _allBookings
        .where((booking) => booking.isToday && !booking.isCancelled)
        .toList();
  }

  // Get upcoming bookings
  List<Booking> getUpcomingBookings() {
    return _allBookings
        .where((booking) => booking.isUpcoming && !booking.isCancelled)
        .toList();
  }

  // Get pending bookings
  List<Booking> getPendingBookings() {
    return _allBookings
        .where((booking) => booking.isPending)
        .toList();
  }

  // Get in-progress bookings
  List<Booking> getInProgressBookings() {
    return _allBookings
        .where((booking) => booking.isInProgress)
        .toList();
  }

  // Get completed bookings
  List<Booking> getCompletedBookings() {
    return _allBookings
        .where((booking) => booking.isCompleted)
        .toList();
  }

  // Get cancelled bookings
  List<Booking> getCancelledBookings() {
    return _allBookings
        .where((booking) => booking.isCancelled)
        .toList();
  }

  // Filter controls
  void setSelectedFilter(String filter) {
    _selectedFilter.value = filter;
    _applyFilters();
  }

  void setSelectedDate(String date) {
    _selectedDate.value = date;
    _applyFilters();
  }

  void setSelectedBranch(String branch) {
    _selectedBranch.value = branch;
    _applyFilters();
  }

  void setSelectedStatus(String status) {
    _selectedStatus.value = status;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _applyFilters();
  }

  void resetFilters() {
    _selectedFilter.value = 'all';
    _selectedDate.value = 'all';
    _selectedBranch.value = 'all';
    _selectedStatus.value = 'all';
    _searchQuery.value = '';
    _applyFilters();
  }

  // Apply all active filters
  void _applyFilters() {
    List<Booking> filtered = _allBookings;

    // Filter by status
    if (_selectedStatus.value != 'all') {
      filtered = filtered.where((booking) => booking.status == _selectedStatus.value).toList();
    }

    // Filter by date
    if (_selectedDate.value != 'all') {
      final now = DateTime.now();
      switch (_selectedDate.value) {
        case 'today':
          filtered = filtered.where((booking) => booking.isToday).toList();
          break;
        case 'tomorrow':
          final tomorrow = now.add(const Duration(days: 1));
          filtered = filtered.where((booking) =>
          booking.date == '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}'
          ).toList();
          break;
        case 'week':
          final weekFromNow = now.add(const Duration(days: 7));
          filtered = filtered.where((booking) {
            final bookingDate = booking.serviceDateTime;
            return bookingDate.isAfter(now) && bookingDate.isBefore(weekFromNow);
          }).toList();
          break;
        case 'month':
          final monthFromNow = now.add(const Duration(days: 30));
          filtered = filtered.where((booking) {
            final bookingDate = booking.serviceDateTime;
            return bookingDate.isAfter(now) && bookingDate.isBefore(monthFromNow);
          }).toList();
          break;
      }
    }

    // Filter by branch
    if (_selectedBranch.value != 'all') {
      filtered = filtered.where((booking) =>
      booking.branch == _selectedBranch.value ||
          booking.branchNames.contains(_selectedBranch.value)
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((booking) =>
      booking.customerName.toLowerCase().contains(query) ||
          booking.serviceName.toLowerCase().contains(query) ||
          booking.staffName.toLowerCase().contains(query) ||
          booking.notes.toLowerCase().contains(query) ||
          booking.bookingNumber.toLowerCase().contains(query)
      ).toList();
    }

    _filteredBookings.assignAll(filtered);
  }

  // Calculate booking statistics
  void _calculateStatistics() {
    final stats = <String, int>{
      'upcoming': 0,
      'approved': 0,
      'in-progress': 0,
      'completed': 0,
      'cancelled': 0,
      'total': _allBookings.length,
    };

    final revenue = <String, double>{
      'today': 0.0,
      'week': 0.0,
      'month': 0.0,
      'total': 0.0,
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    for (final booking in _allBookings) {
      // Status counts
      stats[booking.status] = (stats[booking.status] ?? 0) + 1;

      // Revenue calculations
      if (booking.isCompleted || booking.isInProgress || booking.isConfirmed) {
        revenue['total'] = (revenue['total'] ?? 0) + booking.totalAmount;

        if (booking.isToday) {
          revenue['today'] = (revenue['today'] ?? 0) + booking.totalAmount;
        }

        if (booking.serviceDateTime.isAfter(weekStart)) {
          revenue['week'] = (revenue['week'] ?? 0) + booking.totalAmount;
        }

        if (booking.serviceDateTime.isAfter(monthStart)) {
          revenue['month'] = (revenue['month'] ?? 0) + booking.totalAmount;
        }
      }
    }

    _bookingStats.value = stats;
    _revenueStats.value = revenue;
  }

  // Get available date filters
  List<Map<String, String>> getDateFilters() {
    return [
      {'value': 'all', 'label': 'All Dates'},
      {'value': 'today', 'label': 'Today'},
      {'value': 'tomorrow', 'label': 'Tomorrow'},
      {'value': 'week', 'label': 'This Week'},
      {'value': 'month', 'label': 'This Month'},
    ];
  }

  // Get status filters (portal-canonical)
  List<Map<String, String>> getStatusFilters() {
    return [
      {'value': 'all', 'label': 'All Status'},
      {'value': 'upcoming', 'label': 'Upcoming'},
      {'value': 'in-progress', 'label': 'Check-in'},
      {'value': 'closed', 'label': 'Closed'},
      {'value': 'cancelled', 'label': 'Cancelled'},
    ];
  }

  // Get available branches for filtering
  List<String> getAvailableBranches() {
    final branches = <String>{'all'};

    for (final booking in _allBookings) {
      if (booking.branch.isNotEmpty) {
        branches.add(booking.branch);
      }
      branches.addAll(booking.branchNames);
    }

    return branches.toList()..sort();
  }

  // Get payment methods for filtering
  List<String> getPaymentMethods() {
    final methods = <String>{'all'};

    for (final booking in _allBookings) {
      if (booking.paymentMethod.isNotEmpty) {
        methods.add(booking.paymentMethod);
      }
    }

    return methods.toList()..sort();
  }

  // Check time slot availability
  Future<bool> checkTimeSlotAvailability({
    required String date,
    required String timeSlot,
    required String branch,
    String? staffId,
  }) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('date', isEqualTo: date)
          .where('timeSlot', isEqualTo: timeSlot)
          .where('branchNames', arrayContains: branch)
          .where('status', whereIn: ['upcoming', 'approved', 'confirmed', 'pending', 'in-progress']);

      // If staff is specified, also check staff availability
      if (staffId != null && staffId.isNotEmpty) {
        query = query.where('staffId', isEqualTo: staffId);
      }

      final querySnapshot = await query.get();

      // For now, allow 3 bookings per time slot per staff (or 5 total if no staff specified)
      final maxBookings = staffId != null ? 1 : 3;
      return querySnapshot.docs.length < maxBookings;
    } catch (e) {
      print('Error checking time slot: $e');
      return true;
    }
  }

  // Search bookings with advanced filtering
  List<Booking> searchBookings({
    String? customerName,
    String? serviceName,
    String? staffName,
    String? status,
    String? date,
    String? branch,
    String? timeSlot,
    String? bookingNumber,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    List<Booking> results = _allBookings;

    if (customerName != null && customerName.isNotEmpty) {
      results = results.where((b) =>
          b.customerName.toLowerCase().contains(customerName.toLowerCase())
      ).toList();
    }

    if (serviceName != null && serviceName.isNotEmpty) {
      results = results.where((b) =>
          b.serviceName.toLowerCase().contains(serviceName.toLowerCase())
      ).toList();
    }

    if (staffName != null && staffName.isNotEmpty) {
      results = results.where((b) =>
          b.staffName.toLowerCase().contains(staffName.toLowerCase())
      ).toList();
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      results = results.where((b) => b.status == status).toList();
    }

    if (date != null && date.isNotEmpty) {
      results = results.where((b) => b.date == date).toList();
    }

    if (branch != null && branch.isNotEmpty && branch != 'all') {
      results = results.where((b) =>
      b.branch == branch || b.branchNames.contains(branch)
      ).toList();
    }

    if (timeSlot != null && timeSlot.isNotEmpty) {
      results = results.where((b) => b.timeSlot == timeSlot).toList();
    }

    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      results = results.where((b) =>
          b.bookingNumber.toLowerCase().contains(bookingNumber.toLowerCase())
      ).toList();
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'all') {
      results = results.where((b) => b.paymentMethod == paymentMethod).toList();
    }

    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'all') {
      results = results.where((b) => b.paymentStatus == paymentStatus).toList();
    }

    return results;
  }

  // Get revenue by date range
  Map<String, double> getRevenueByDateRange(DateTime startDate, DateTime endDate) {
    final revenue = <String, double>{};
    final bookings = getBookingsByDateRange(startDate, endDate);

    for (final booking in bookings) {
      if (booking.isCompleted) {
        final dateKey = booking.date;
        revenue[dateKey] = (revenue[dateKey] ?? 0) + booking.totalAmount;
      }
    }

    return revenue;
  }

  // Get staff performance statistics
  Map<String, Map<String, dynamic>> getStaffPerformance() {
    final performance = <String, Map<String, dynamic>>{};

    for (final booking in _allBookings) {
      if (booking.staffId.isNotEmpty && (booking.isCompleted || booking.isInProgress)) {
        if (!performance.containsKey(booking.staffId)) {
          performance[booking.staffId] = {
            'name': booking.staffName,
            'role': booking.staffRole,
            'totalBookings': 0,
            'completedBookings': 0,
            'revenue': 0.0,
            'averageRating': 0.0,
          };
        }

        final staff = performance[booking.staffId]!;
        staff['totalBookings'] = (staff['totalBookings'] as int) + 1;
        staff['revenue'] = (staff['revenue'] as double) + booking.totalAmount;

        if (booking.isCompleted) {
          staff['completedBookings'] = (staff['completedBookings'] as int) + 1;
        }
      }
    }

    return performance;
  }

  // Export bookings to CSV/Excel
  List<Map<String, dynamic>> exportBookings(List<Booking> bookings) {
    return bookings.map((booking) {
      return {
        'Booking Number': booking.bookingNumber,
        'Customer': booking.customerName,
        'Phone': booking.customerPhone,
        'Email': booking.customerEmail,
        'Service': booking.serviceName,
        'Date': booking.formattedDate,
        'Time': booking.formattedTime,
        'Duration': booking.durationFormatted,
        'Staff': booking.staffName,
        'Branch': booking.branch,
        'Status': booking.status,
        'Payment Method': booking.paymentMethod,
        'Payment Status': booking.paymentStatus,
        'Subtotal': booking.formatCurrency(booking.subtotal),
        'Service Charges': booking.formatCurrency(booking.serviceCharges),
        'Tax': booking.formatCurrency(booking.taxAmount),
        'Discount': booking.formatCurrency(booking.discountAmount),
        'Tip': booking.formatCurrency(booking.tip),
        'Total Amount': booking.formatCurrency(booking.totalAmount),
        'Created': booking.createdAt.toLocal().toString(),
        'Notes': booking.notes,
      };
    }).toList();
  }

  // Refresh bookings data
  Future<void> refreshBookings() async {
    await loadBookings();
    if (_isLoggedIn) {
      await loadUserBookings();
    }
  }

  // Real-time listener for bookings updates
  void listenToBookings() {
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
    });
  }

}

// Extension for firstWhereOrNull
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}