import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/banner_model.dart';
import '../controlers/notification_controller.dart';
import '../models/notification_model.dart'; // Add this import
import '../utils/safe_firestore.dart';

class BannerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  NotificationController get _notificationController =>
      Get.find<NotificationController>();

  final RxList<BannerItem> _banners = <BannerItem>[].obs;
  final RxList<BannerItem> _activeBanners = <BannerItem>[].obs;
  final RxList<BannerItem> _serviceBanners = <BannerItem>[].obs;
  final RxList<BannerItem> _productBanners = <BannerItem>[].obs;
  final RxInt _currentBannerIndex = 0.obs;
  final RxBool _isLoading = false.obs;

  // Track sent notifications to avoid duplicates
  final Set<String> _sentOfferNotifications = {};
  StreamSubscription? _offersSubscription;
  bool _listenerStarted = false;

  List<BannerItem> get banners => _banners;
  List<BannerItem> get activeBanners => _activeBanners;
  List<BannerItem> get serviceBanners => _serviceBanners;
  List<BannerItem> get productBanners => _productBanners;
  int get currentBannerIndex => _currentBannerIndex.value;
  BannerItem? get currentBanner => _activeBanners.isNotEmpty ? _activeBanners[_currentBannerIndex.value] : null;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Banners load when Home (or admin) requests them — no cold-start listener.
  }

  @override
  void onClose() {
    _offersSubscription?.cancel();
    super.onClose();
  }

  // Setup real-time listener for new banners (once, after first load)
  void _setupBannerListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;
    _offersSubscription = _firestore
        .collection('offers')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final newBanner = BannerItem.fromFirestore(change.doc);
          _sendNewOfferNotification(newBanner);
        }
      }
    });
  }

  // Send notification for new offer
  Future<void> _sendNewOfferNotification(BannerItem banner) async {
    // Check if notification already sent for this banner
    final notificationKey = 'new_offer_${banner.id}';
    if (_sentOfferNotifications.contains(notificationKey)) {
      return;
    }

    if (!banner.isValid) return;

    // Add to sent set
    _sentOfferNotifications.add(notificationKey);

    // Format discount message
    String discountText = banner.discountType == 'percentage'
        ? '${banner.discountValue}% OFF'
        : '${banner.discountValue} AED OFF';

    // Send in-app notification
    _notificationController.showInAppNotification(
      title: '🎉 New Offer Available!',
      message: '${banner.title} - $discountText',
      type: NotificationType.offer,
      data: {
        'type': 'offer',
        'offerId': banner.id,
        'offerTitle': banner.title,
        'discountValue': banner.discountValue,
        'discountType': banner.discountType,
      },
    );

    // Also add to notification list in Firestore for persistence
    await _addOfferToNotifications(banner, discountText);
  }

  // Add offer to user's notifications collection
  Future<void> _addOfferToNotifications(BannerItem banner, String discountText) async {
    try {
      // Get all users to send notification to (or you can send to specific topics)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      final batch = _firestore.batch();

      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();

        batch.set(notificationRef, {
          'type': 'offer',
          'title': 'New Offer Available! 🎉',
          'message': '${banner.title} - $discountText',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': {
            'offerId': banner.id,
            'offerTitle': banner.title,
            'discountValue': banner.discountValue,
            'discountType': banner.discountType,
          },
          'imageUrl': banner.imageUrl,
          'actionUrl': '/offers/${banner.id}',
        });
      }

      await batch.commit();
      print('✅ Offer notification added to ${usersSnapshot.docs.length} users');

    } catch (e) {
      print('❌ Error adding offer to notifications: $e');
    }
  }

  // Check for banners expiring soon and send reminders
  Future<void> _checkExpiringBanners() async {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));

    final expiringBanners = _activeBanners.where((banner) {
      return banner.validTo.isAfter(now) &&
          banner.validTo.isBefore(threeDaysFromNow) &&
          !banner.isExpiringNotificationSent;
    }).toList();

    for (final banner in expiringBanners) {
      await _sendExpiringNotification(banner);
    }
  }

  // Send notification for expiring offer
  Future<void> _sendExpiringNotification(BannerItem banner) async {
    final daysLeft = banner.validTo.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return;

    // Format discount message
    String discountText = banner.discountType == 'percentage'
        ? '${banner.discountValue}% OFF'
        : '${banner.discountValue} AED OFF';

    // Send in-app notification
    _notificationController.showInAppNotification(
      title: '⏰ Offer Ending Soon!',
      message: '${banner.title} - $discountText ends in $daysLeft day${daysLeft > 1 ? 's' : ''}. Hurry!',
      type: NotificationType.offer,
      data: {
        'type': 'offer',
        'offerId': banner.id,
        'offerTitle': banner.title,
        'expiringInDays': daysLeft,
      },
    );

    // Mark as notification sent to avoid duplicates
    await _markExpiringNotificationSent(banner.id);
  }

  // Mark expiring notification as sent
  Future<void> _markExpiringNotificationSent(String bannerId) async {
    try {
      await _firestore
          .collection('offers')
          .doc(bannerId)
          .update({
        'expiringNotificationSent': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local banner
      final index = _banners.indexWhere((b) => b.id == bannerId);
      if (index != -1) {
        final updatedBanner = _banners[index].copyWith(
          isExpiringNotificationSent: true,
        );
        _banners[index] = updatedBanner;
      }

    } catch (e) {
      print('Error marking expiring notification sent: $e');
    }
  }

  // Send offer notification manually (for admin panel)
  Future<bool> sendOfferNotification(String bannerId) async {
    try {
      final banner = await getBannerById(bannerId);
      if (banner == null || !banner.isValid) {
        Get.snackbar('Error', 'Offer not found or inactive');
        return false;
      }

      String discountText = banner.discountType == 'percentage'
          ? '${banner.discountValue}% OFF'
          : '${banner.discountValue} AED OFF';

      // Send to all users topic
      await _firestore.collection('notifications').add({
        'type': 'offer',
        'title': '🎉 Special Offer!',
        'message': '${banner.title} - $discountText',
        'timestamp': FieldValue.serverTimestamp(),
        'targetAudience': 'all_users',
        'data': {
          'offerId': banner.id,
          'offerTitle': banner.title,
          'discountValue': banner.discountValue,
          'discountType': banner.discountType,
        },
      });

      Get.snackbar('Success', 'Offer notification sent to all users');
      return true;

    } catch (e) {
      print('Error sending offer notification: $e');
      Get.snackbar('Error', 'Failed to send notification');
      return false;
    }
  }

  // Load all banners/offers from Firestore
  Future<void> loadBanners() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;

      final query = _firestore
          .collection('offers')
          .orderBy('createdAt', descending: true)
          .limit(20);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedBanners =
            snap.docs.map((doc) => BannerItem.fromFirestore(doc)).toList();
        _banners.assignAll(loadedBanners);
        _organizeBanners();
        update();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
      _setupBannerListener();
      unawaited(_checkExpiringBanners());
    } catch (e) {
      print('❌ loadBanners: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Organize banners into categories
  void _organizeBanners() {
    // Active banners (currently valid)
    _activeBanners.value = _banners
        .where((banner) => banner.isValid)
        .toList();

    // Service banners
    _serviceBanners.value = _banners
        .where((banner) => banner.isValid && banner.isServiceOffer)
        .toList();

    // Product banners
    _productBanners.value = _banners
        .where((banner) => banner.isValid && banner.isProductOffer)
        .toList();
  }

  // Add new banner with notification
  Future<bool> addBanner(BannerItem banner) async {
    try {
      _isLoading.value = true;

      final docRef = await _firestore
          .collection('offers')
          .add(banner.toFirestore());

      // Get the created banner with ID
      final createdBanner = banner.copyWith(id: docRef.id);

      // Send notification for new offer
      await _sendNewOfferNotification(createdBanner);

      await loadBanners();

      Get.snackbar('Success', 'Banner added and notification sent');
      return true;

    } catch (e) {
      Get.snackbar('Error', 'Failed to add banner: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update banner
  Future<bool> updateBanner(String bannerId, BannerItem updatedBanner) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('offers')
          .doc(bannerId)
          .update(updatedBanner.toFirestore());

      await loadBanners();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update banner: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete banner
  Future<bool> deleteBanner(String bannerId) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('offers')
          .doc(bannerId)
          .delete();

      await loadBanners();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete banner: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Toggle banner status
  Future<bool> toggleBannerStatus(String bannerId, bool isActive) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('offers')
          .doc(bannerId)
          .update({
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': DateTime.now(),
      });

      // If activating, send notification
      if (isActive) {
        final banner = await getBannerById(bannerId);
        if (banner != null && banner.isValid) {
          await _sendNewOfferNotification(banner);
        }
      }

      await loadBanners();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update banner status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get banner by ID
  Future<BannerItem?> getBannerById(String bannerId) async {
    try {
      final doc = await _firestore
          .collection('offers')
          .doc(bannerId)
          .get();

      if (doc.exists) {
        return BannerItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting banner: $e');
      return null;
    }
  }

  // Get banners by offer type
  List<BannerItem> getBannersByType(String offerType) {
    return _banners
        .where((banner) => banner.isValid && banner.offerType == offerType)
        .toList();
  }

  // Get banners applicable to specific service
  List<BannerItem> getBannersForService(String serviceId) {
    return _banners
        .where((banner) => banner.isValid && banner.isApplicableToService(serviceId))
        .toList();
  }

  // Get banners applicable to specific product
  List<BannerItem> getBannersForProduct(String productId) {
    return _banners
        .where((banner) => banner.isValid && banner.isApplicableToProduct(productId))
        .toList();
  }

  // Get banners applicable to specific branch
  List<BannerItem> getBannersForBranch(String branchId) {
    return _banners
        .where((banner) => banner.isValid && banner.isApplicableToBranch(branchId))
        .toList();
  }

  // Get banners with highest discount value
  List<BannerItem> getTopDiscountBanners({int limit = 3}) {
    final sorted = List<BannerItem>.from(_activeBanners);
    sorted.sort((a, b) => b.discountValue.compareTo(a.discountValue));
    return sorted.take(limit).toList();
  }

  // Banner navigation methods
  void setCurrentBannerIndex(int index) {
    if (index >= 0 && index < _activeBanners.length) {
      _currentBannerIndex.value = index;
    }
  }

  void nextBanner() {
    if (_activeBanners.isEmpty) return;

    final nextIndex = (_currentBannerIndex.value + 1) % _activeBanners.length;
    _currentBannerIndex.value = nextIndex;
  }

  void previousBanner() {
    if (_activeBanners.isEmpty) return;

    final prevIndex = (_currentBannerIndex.value - 1 + _activeBanners.length) % _activeBanners.length;
    _currentBannerIndex.value = prevIndex;
  }

  // Increment usage count for a banner
  Future<bool> incrementUsageCount(String bannerId) async {
    try {
      final banner = await getBannerById(bannerId);
      if (banner == null || banner.isUsageLimitReached) return false;

      await _firestore
          .collection('offers')
          .doc(bannerId)
          .update({
        'usedCount': banner.usedCount + 1,
        'updatedAt': DateTime.now(),
      });

      await loadBanners();
      return true;
    } catch (e) {
      print('Error incrementing usage count: $e');
      return false;
    }
  }

  // Check if a banner can be applied to an item
  bool canApplyBanner(String bannerId, String itemId, String itemType) {
    final banner = _banners.firstWhereOrNull((b) => b.id == bannerId);
    if (banner == null || !banner.isValid) return false;

    if (itemType == 'service') {
      return banner.isServiceOffer && banner.isApplicableToService(itemId);
    } else if (itemType == 'product') {
      return banner.isProductOffer && banner.isApplicableToProduct(itemId);
    }

    return false;
  }

  // Calculate discounted price
  double calculateDiscountedPrice(double originalPrice, BannerItem banner) {
    if (!banner.isValid) return originalPrice;

    if (banner.discountType == 'percentage') {
      return originalPrice * (1 - banner.discountValue / 100);
    } else {
      return originalPrice - banner.discountValue;
    }
  }

  // Get discount amount
  double getDiscountAmount(double originalPrice, BannerItem banner) {
    if (!banner.isValid) return 0.0;

    if (banner.discountType == 'percentage') {
      return originalPrice * (banner.discountValue / 100);
    } else {
      return banner.discountValue;
    }
  }

  // Get banners for home screen (limited active banners)
  List<BannerItem> getHomeBanners({int limit = 5}) {
    return _activeBanners.take(limit).toList();
  }

  // Get banner statistics
  Map<String, dynamic> getBannerStats() {
    final now = DateTime.now();

    return {
      'total': _banners.length,
      'active': _activeBanners.length,
      'expired': _banners.where((b) => !b.isValid).length,
      'serviceOffers': _serviceBanners.length,
      'productOffers': _productBanners.length,
      'usageLimitReached': _banners.where((b) => b.isUsageLimitReached).length,
      'expiringSoon': _banners.where((b) =>
      b.isActive &&
          b.validTo.isAfter(now) &&
          b.validTo.isBefore(now.add(const Duration(days: 7)))
      ).length,
    };
  }

  // Get banners with filters
  List<BannerItem> filterBanners({
    String? offerType,
    String? status,
    String? branchId,
    bool? validOnly,
  }) {
    List<BannerItem> filtered = List.from(_banners);

    if (offerType != null) {
      filtered = filtered.where((b) => b.offerType == offerType).toList();
    }

    if (status != null) {
      filtered = filtered.where((b) => b.status == status).toList();
    }

    if (branchId != null) {
      filtered = filtered.where((b) => b.isApplicableToBranch(branchId)).toList();
    }

    if (validOnly == true) {
      filtered = filtered.where((b) => b.isValid).toList();
    }

    return filtered;
  }

  // Refresh banners
  Future<void> refreshBanners() async {
    await loadBanners();
  }

  // Get best applicable banner for an item
  BannerItem? getBestApplicableBanner({
    required String itemId,
    required String itemType,
    required String branchId,
    double? itemPrice,
  }) {
    List<BannerItem> applicableBanners = [];

    if (itemType == 'service') {
      applicableBanners = getBannersForService(itemId);
    } else if (itemType == 'product') {
      applicableBanners = getBannersForProduct(itemId);
    }

    // Filter by branch applicability
    applicableBanners = applicableBanners
        .where((banner) => banner.isApplicableToBranch(branchId))
        .toList();

    if (applicableBanners.isEmpty) return null;

    // Sort by discount value (highest first)
    applicableBanners.sort((a, b) => b.discountValue.compareTo(a.discountValue));

    // If item price is provided, calculate actual discount value
    if (itemPrice != null) {
      applicableBanners.sort((a, b) {
        final discountA = getDiscountAmount(itemPrice, a);
        final discountB = getDiscountAmount(itemPrice, b);
        return discountB.compareTo(discountA);
      });
    }

    return applicableBanners.first;
  }
}