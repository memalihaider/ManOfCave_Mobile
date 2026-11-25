// controllers/feedback_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/feedback_model.dart';
import './customer_controller.dart';
import './loyalty_points_controller.dart';
import './service_controller.dart';
import './product_controller.dart';

class FeedbackController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerController _customerController = Get.find<CustomerController>();
  final LoyaltyController _loyaltyController = Get.find<LoyaltyController>();
  final ServiceController _serviceController = Get.find<ServiceController>();
  final ProductController _productController = Get.find<ProductController>();

  // Reactive state
  final RxList<FeedbackModel> _feedbacks = <FeedbackModel>[].obs;
  final RxList<FeedbackModel> _customerFeedbacks = <FeedbackModel>[].obs;
  final RxList<FeedbackModel> _pendingFeedbacks = <FeedbackModel>[].obs;
  final RxList<FeedbackModel> _approvedFeedbacks = <FeedbackModel>[].obs;
  final RxList<FeedbackModel> _rejectedFeedbacks = <FeedbackModel>[].obs;

  final RxBool _isLoading = false.obs;
  final RxString _filterStatus = 'all'.obs;
  final RxString _filterType = 'all'.obs;
  final RxString _filterRating = 'all'.obs;

  // Getters
  List<FeedbackModel> get allFeedbacks => _feedbacks;
  List<FeedbackModel> get customerFeedbacks => _customerFeedbacks;
  List<FeedbackModel> get pendingFeedbacks => _pendingFeedbacks;
  List<FeedbackModel> get approvedFeedbacks => _approvedFeedbacks;
  List<FeedbackModel> get rejectedFeedbacks => _rejectedFeedbacks;

  bool get isLoading => _isLoading.value;
  String? get customerId => _customerController.currentCustomer?.uid;

  // Statistics
  int get totalFeedbacks => _feedbacks.length;
  int get totalCustomerFeedbacks => _customerFeedbacks.length;
  int get totalPending => _pendingFeedbacks.length;
  int get totalApproved => _approvedFeedbacks.length;
  int get totalRejected => _rejectedFeedbacks.length;

  double get averageRating => _customerFeedbacks.isEmpty ? 0.0 :
  _customerFeedbacks.fold(0.0, (sum, feedback) => sum + feedback.rating) / _customerFeedbacks.length;

  @override
  void onInit() {
    super.onInit();
    if (customerId != null) {
      loadCustomerFeedbacks();
    }
  }

  // Load all feedbacks (for admin)
  Future<void> loadAllFeedbacks() async {
    try {
      _isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .get();

      final loadedFeedbacks = querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      _feedbacks.assignAll(loadedFeedbacks);
      _updateFilteredLists();

    } catch (e) {
      print("Failed to load feedbacks: $e");
      Get.snackbar(
        'Error',
        'Failed to load feedbacks: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Load feedbacks for current customer
  Future<void> loadCustomerFeedbacks() async {
    try {
      _isLoading.value = true;

      if (customerId == null) {
        _customerFeedbacks.clear();
        return;
      }

      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      final loadedFeedbacks = querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      _customerFeedbacks.assignAll(loadedFeedbacks);
      _updateFilteredLists();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load your feedbacks: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Load feedbacks for a specific service or product
  Future<List<FeedbackModel>> loadFeedbacksForServiceOrProduct(String id, String type) async {
    try {
      _isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('serviceId', isEqualTo: id)
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'approved') // Only show approved feedbacks
          .orderBy('createdAt', descending: true)
          .get();

      final loadedFeedbacks = querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      return loadedFeedbacks;

    } catch (e) {
      print('Error loading feedbacks for $type: $e');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  // Get feedback by ID
  Future<FeedbackModel?> getFeedbackById(String feedbackId) async {
    try {
      final doc = await _firestore
          .collection('feedbacks')
          .doc(feedbackId)
          .get();

      if (doc.exists) {
        return FeedbackModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting feedback: $e');
      return null;
    }
  }

  // Check if customer has already given feedback for a booking/order
  Future<bool> hasGivenFeedback(String serviceOrProductId, String type, String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedbacks')
          .where('serviceId', isEqualTo: serviceOrProductId)
          .where('type', isEqualTo: type)
          .where('customerId', isEqualTo: customerId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking existing feedback: $e');
      return false;
    }
  }

  // Submit feedback for a completed booking
  // Update this method in FeedbackController
  Future<String?> submitBookingFeedback({
    required String bookingId,
    required String serviceId,
    required String serviceName,
    required int rating,
    required String comment,
    required List<String> serviceBranches,
    required List<String> serviceBranchNames,
    required String serviceCategory,
    required String serviceCategoryId,
    required double servicePrice,
    required int serviceDuration,
    required String serviceImageUrl,
    required String serviceDescription,
  }) async {
    try {
      _isLoading.value = true;

      if (customerId == null || _customerController.currentCustomer == null) {
        Get.snackbar('Error', 'Please login to submit feedback');
        return null;
      }

      // Check if feedback already exists
      final hasFeedback = await hasGivenFeedback(serviceId, 'service', customerId!);
      if (hasFeedback) {
        Get.snackbar('Already Submitted', 'You have already submitted feedback for this service');
        return null;
      }

      // Get service details for additional info
      final service = await _serviceController.getServiceById(serviceId);

      // Create feedback document
      final feedbackDoc = {
        'comment': comment,
        'rating': rating,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'type': 'service',
        'customerId': customerId,
        'customerName': _customerController.currentCustomer!.name,
        'customerEmail': _customerController.currentCustomer!.email,
        'serviceBranches': serviceBranches,
        'serviceBranchNames': serviceBranchNames,
        'serviceCategory': serviceCategory,
        'serviceCategoryId': serviceCategoryId,
        'servicePrice': servicePrice,
        'serviceDuration': serviceDuration,
        'serviceImageUrl': serviceImageUrl,
        'serviceDescription': serviceDescription,
        'status': 'pending', // Admin will approve/reject
        'pointsAwarded': false,
        'createdAt': DateTime.now(),

        // Service metadata
        'serviceCreatedAt': service?.createdAt ?? DateTime.now(),
        'serviceUpdatedAt': service?.updatedAt ?? DateTime.now(),
        'serviceStatus': service?.status ?? 'active',
        'servicePopularity': service?.popularity ?? 'low',
        'serviceRevenue': service?.revenue ?? 0.0,
        'serviceTotalBookings': service?.totalBookings ?? 0,
        'serviceOrProduct': serviceName,
      };

      // Add document and get the reference
      final feedbackRef = await _firestore
          .collection('feedbacks')
          .add(feedbackDoc);

      final feedbackId = feedbackRef.id;

      // Refresh feedbacks
      await loadCustomerFeedbacks();

      Get.snackbar(
        'Feedback Submitted!',
        'Thank you for your feedback. It will be reviewed by our team.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Return the feedback ID
      return feedbackId;

    } catch (e) {
      Get.snackbar(
        'Submission Failed',
        'Error submitting feedback: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }
  //
  // // Add this method to FeedbackController
  // Future<bool> awardPointsImmediatelyForFeedback(String feedbackId) async {
  //   try {
  //     final feedback = await getFeedbackById(feedbackId);
  //     if (feedback == null) {
  //       print('Feedback not found');
  //       return false;
  //     }
  //
  //     // Check if points already awarded
  //     if (feedback.pointsAwarded) {
  //       print('Points already awarded for this feedback');
  //       return true;
  //     }
  //
  //     // Calculate points based on rating
  //     final points = _calculateFeedbackPoints(feedback.rating);
  //
  //     if (points <= 0) {
  //       print('No points to award for rating ${feedback.rating}');
  //       return true;
  //     }
  //
  //     // Award points using LoyaltyController
  //     final success = await _loyaltyController.awardFeedbackPoints(
  //       customerId: feedback.customerId,
  //       feedbackId: feedbackId,
  //       points: points,
  //       rating: feedback.rating,
  //       serviceOrProductName: feedback.serviceName,
  //       type: feedback.type,
  //     );
  //
  //     if (success) {
  //       // Mark feedback as points awarded
  //       await _firestore
  //           .collection('feedbacks')
  //           .doc(feedbackId)
  //           .update({
  //         'pointsAwarded': true,
  //         'pointsAwardedAmount': points,
  //         'pointsAwardedAt': DateTime.now(),
  //         'updatedAt': DateTime.now(),
  //       });
  //
  //       print('Immediately awarded $points points for feedback $feedbackId');
  //       return true;
  //     }
  //
  //     return false;
  //   } catch (e) {
  //     print('Error awarding points immediately: $e');
  //     return false;
  //   }
  // }

// Update this method in FeedbackController
  Future<String?> submitOrderFeedback({
    required String orderId,
    required String productId,
    required String productName,
    required int rating,
    required String comment,
    required List<String> productBranches,
    required List<String> productBranchNames,
    required String productCategory,
    required String productCategoryId,
    required double productPrice,
    required String productImageUrl,
    required String productDescription,
  }) async {
    try {
      _isLoading.value = true;

      if (customerId == null || _customerController.currentCustomer == null) {
        Get.snackbar('Error', 'Please login to submit feedback');
        return null;
      }

      // Check if feedback already exists
      final hasFeedback = await hasGivenFeedback(productId, 'product', customerId!);
      if (hasFeedback) {
        Get.snackbar('Already Submitted', 'You have already submitted feedback for this product');
        return null;
      }

      // Get product details for additional info
      final product = await _productController.getProductById(productId);

      // Create feedback document
      final feedbackDoc = {
        'comment': comment,
        'rating': rating,
        'serviceId': productId,
        'serviceName': productName,
        'type': 'product',
        'customerId': customerId,
        'customerName': _customerController.currentCustomer!.name,
        'customerEmail': _customerController.currentCustomer!.email,
        'serviceBranches': productBranches,
        'serviceBranchNames': productBranchNames,
        'serviceCategory': productCategory,
        'serviceCategoryId': productCategoryId,
        'servicePrice': productPrice,
        'serviceDuration': 0, // Products don't have duration
        'serviceImageUrl': productImageUrl,
        'serviceDescription': productDescription,
        'status': 'pending', // Admin will approve/reject
        'pointsAwarded': false,
        'createdAt': DateTime.now(),

        // Product metadata
        'serviceCreatedAt': product?.createdAt ?? DateTime.now(),
        'serviceUpdatedAt': product?.updatedAt ?? DateTime.now(),
        'serviceStatus': product?.status ?? 'active',
        'servicePopularity': '',
        'serviceRevenue': product?.revenue ?? 0.0,
        'serviceTotalBookings': 0, // Products don't have bookings
        'serviceOrProduct': productName,
      };

      // Add document and get the reference
      final feedbackRef = await _firestore
          .collection('feedbacks')
          .add(feedbackDoc);

      final feedbackId = feedbackRef.id;

      // Refresh feedbacks
      await loadCustomerFeedbacks();

      Get.snackbar(
        'Feedback Submitted!',
        'Thank you for your feedback. It will be reviewed by our team.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Return the feedback ID
      return feedbackId;

    } catch (e) {
      Get.snackbar(
        'Submission Failed',
        'Error submitting feedback: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // // Award loyalty points for approved feedback
  // Future<void> awardFeedbackPoints(String feedbackId) async {
  //   try {
  //     final feedback = await getFeedbackById(feedbackId);
  //     if (feedback == null || feedback.pointsAwarded) return;
  //
  //     // Award points based on rating
  //     final points = _calculateFeedbackPoints(feedback.rating);
  //
  //     if (points > 0) {
  //       await _loyaltyController.awardFeedbackPoints(
  //         customerId: feedback.customerId,
  //         feedbackId: feedbackId,
  //         points: points,
  //         rating: feedback.rating,
  //         serviceOrProductName: feedback.serviceName,
  //         type: feedback.type,
  //       );
  //
  //       // Mark feedback as points awarded
  //       await _firestore
  //           .collection('feedbacks')
  //           .doc(feedbackId)
  //           .update({
  //         'pointsAwarded': true,
  //         'pointsAwardedAmount': points,
  //         'updatedAt': DateTime.now(),
  //       });
  //     }
  //   } catch (e) {
  //     print('Error awarding feedback points: $e');
  //   }
  // }

  // Calculate points based on rating
  int _calculateFeedbackPoints(int rating) {
    switch (rating) {
      case 5:
        return 100; // 100 points for 5-star
      case 4:
        return 50;  // 50 points for 4-star
      case 3:
        return 25;  // 25 points for 3-star
      default:
        return 0;   // No points for lower ratings
    }
  }

  // Get feedback statistics for a service/product
  Future<Map<String, dynamic>> getServiceProductFeedbackStats(String id, String type) async {
    try {
      final feedbacks = await loadFeedbacksForServiceOrProduct(id, type);

      if (feedbacks.isEmpty) {
        return {
          'total': 0,
          'averageRating': 0.0,
          'ratingDistribution': List.filled(5, 0),
          'approvedCount': 0,
        };
      }

      final approvedFeedbacks = feedbacks.where((f) => f.isApproved).toList();
      final ratingDistribution = List.filled(5, 0);

      for (final feedback in approvedFeedbacks) {
        if (feedback.rating >= 1 && feedback.rating <= 5) {
          ratingDistribution[feedback.rating - 1]++;
        }
      }

      final averageRating = approvedFeedbacks.isEmpty ? 0.0 :
      approvedFeedbacks.fold(0.0, (sum, f) => sum + f.rating) / approvedFeedbacks.length;

      return {
        'total': approvedFeedbacks.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
        'approvedCount': approvedFeedbacks.length,
        'latestFeedback': approvedFeedbacks.isNotEmpty ? approvedFeedbacks.first : null,
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      return {
        'total': 0,
        'averageRating': 0.0,
        'ratingDistribution': List.filled(5, 0),
        'approvedCount': 0,
      };
    }
  }

  // Update filtered lists
  void _updateFilteredLists() {
    _pendingFeedbacks.assignAll(_feedbacks.where((f) => f.isPending).toList());
    _approvedFeedbacks.assignAll(_feedbacks.where((f) => f.isApproved).toList());
    _rejectedFeedbacks.assignAll(_feedbacks.where((f) => f.isRejected).toList());
  }

  // Set filters
  void setFilters({String? status, String? type, String? rating}) {
    if (status != null) _filterStatus.value = status;
    if (type != null) _filterType.value = type;
    if (rating != null) _filterRating.value = rating;
    update();
  }

  // Reset filters
  void resetFilters() {
    _filterStatus.value = 'all';
    _filterType.value = 'all';
    _filterRating.value = 'all';
    update();
  }

  // Get filtered feedbacks based on current filters
  List<FeedbackModel> get filteredFeedbacks {
    List<FeedbackModel> filtered = List.from(_feedbacks);

    if (_filterStatus.value != 'all') {
      filtered = filtered.where((f) => f.status == _filterStatus.value).toList();
    }

    if (_filterType.value != 'all') {
      filtered = filtered.where((f) => f.type == _filterType.value).toList();
    }

    if (_filterRating.value != 'all') {
      final rating = int.tryParse(_filterRating.value) ?? 0;
      filtered = filtered.where((f) => f.rating == rating).toList();
    }

    return filtered;
  }

  // Get customer filtered feedbacks
  List<FeedbackModel> get filteredCustomerFeedbacks {
    List<FeedbackModel> filtered = List.from(_customerFeedbacks);

    if (_filterStatus.value != 'all') {
      filtered = filtered.where((f) => f.status == _filterStatus.value).toList();
    }

    if (_filterType.value != 'all') {
      filtered = filtered.where((f) => f.type == _filterType.value).toList();
    }

    if (_filterRating.value != 'all') {
      final rating = int.tryParse(_filterRating.value) ?? 0;
      filtered = filtered.where((f) => f.rating == rating).toList();
    }

    return filtered;
  }

  // Get feedback statistics for admin dashboard
  Map<String, dynamic> getFeedbackStats() {
    final now = DateTime.now();
    final last30Days = now.subtract(Duration(days: 30));

    final recentFeedbacks = _feedbacks.where((f) => f.createdAt.isAfter(last30Days)).toList();
    final recentServiceFeedbacks = recentFeedbacks.where((f) => f.isService).toList();
    final recentProductFeedbacks = recentFeedbacks.where((f) => f.isProduct).toList();

    return {
      'total': totalFeedbacks,
      'pending': totalPending,
      'approved': totalApproved,
      'rejected': totalRejected,
      'averageRating': averageRating,
      'recent30Days': recentFeedbacks.length,
      'serviceFeedbackCount': recentServiceFeedbacks.length,
      'productFeedbackCount': recentProductFeedbacks.length,
      'topRatedService': _getTopRatedService(),
      'topRatedProduct': _getTopRatedProduct(),
    };
  }

  // Get top rated service
  Map<String, dynamic>? _getTopRatedService() {
    final serviceFeedbacks = _approvedFeedbacks.where((f) => f.isService).toList();
    if (serviceFeedbacks.isEmpty) return null;

    final serviceRatings = <String, List<int>>{};

    for (final feedback in serviceFeedbacks) {
      if (!serviceRatings.containsKey(feedback.serviceId)) {
        serviceRatings[feedback.serviceId] = [];
      }
      serviceRatings[feedback.serviceId]!.add(feedback.rating);
    }

    var topServiceId = '';
    var topAvgRating = 0.0;

    serviceRatings.forEach((serviceId, ratings) {
      final avgRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      if (avgRating > topAvgRating) {
        topAvgRating = avgRating;
        topServiceId = serviceId;
      }
    });

    final topServiceFeedback = serviceFeedbacks.firstWhere((f) => f.serviceId == topServiceId);

    return {
      'serviceId': topServiceId,
      'serviceName': topServiceFeedback.serviceName,
      'averageRating': topAvgRating,
      'totalFeedbacks': serviceRatings[topServiceId]?.length ?? 0,
      'imageUrl': topServiceFeedback.serviceImageUrl,
    };
  }

  // Get top rated product
  Map<String, dynamic>? _getTopRatedProduct() {
    final productFeedbacks = _approvedFeedbacks.where((f) => f.isProduct).toList();
    if (productFeedbacks.isEmpty) return null;

    final productRatings = <String, List<int>>{};

    for (final feedback in productFeedbacks) {
      if (!productRatings.containsKey(feedback.serviceId)) {
        productRatings[feedback.serviceId] = [];
      }
      productRatings[feedback.serviceId]!.add(feedback.rating);
    }

    var topProductId = '';
    var topAvgRating = 0.0;

    productRatings.forEach((productId, ratings) {
      final avgRating = ratings.fold(0.0, (sum, rating) => sum + rating) / ratings.length;
      if (avgRating > topAvgRating) {
        topAvgRating = avgRating;
        topProductId = productId;
      }
    });

    final topProductFeedback = productFeedbacks.firstWhere((f) => f.serviceId == topProductId);

    return {
      'productId': topProductId,
      'productName': topProductFeedback.serviceName,
      'averageRating': topAvgRating,
      'totalFeedbacks': productRatings[topProductId]?.length ?? 0,
      'imageUrl': topProductFeedback.serviceImageUrl,
    };
  }

  // Delete feedback (admin only)
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('feedbacks')
          .doc(feedbackId)
          .delete();

      // Refresh lists
      await loadAllFeedbacks();
      if (customerId != null) {
        await loadCustomerFeedbacks();
      }

      Get.snackbar(
        'Success',
        'Feedback deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete feedback: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Refresh all feedback data
  Future<void> refreshFeedbacks() async {
    await loadAllFeedbacks();
    if (customerId != null) {
      await loadCustomerFeedbacks();
    }
  }
}