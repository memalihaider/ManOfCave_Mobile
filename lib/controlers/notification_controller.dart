import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Screens/booking_details_screen.dart';
import '../Screens/chats/chat_room_screen.dart';
import '../Screens/customer_shell.dart';
import '../Screens/my_booking_screen.dart';
import '../Screens/notification_screen.dart';
import '../Screens/order_details_screen.dart';
import '../Screens/profile_screen.dart';
import '../constants/app_colors.dart';
import '../models/notification_model.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt unreadCount = 0.obs;

  // Filter state
  final Rx<NotificationType?> selectedType = Rx<NotificationType?>(null);
  final RxBool showOnlyUnread = false.obs;

  // Stream subscription
  StreamSubscription? _notificationsStream;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state to load notifications when user logs in
    ever(_authController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        loadNotifications();
        _setupFCMHandlers();
      } else {
        notifications.clear();
        unreadCount.value = 0;
      }
    });

    // If already logged in, load immediately
    if (_authController.isLoggedIn.value) {
      loadNotifications();
      _setupFCMHandlers();
    }
  }

  @override
  void onClose() {
    _notificationsStream?.cancel();
    super.onClose();
  }

  // Load notifications from Firestore
  void loadNotifications() {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    isLoading.value = true;

    _notificationsStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        notifications.value = snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc.data(), doc.id))
            .toList();
        _updateUnreadCount();
        isLoading.value = false;
      },
      onError: (error) {
        errorMessage.value = error.toString();
        isLoading.value = false;
      },
    );
  }

  // controlers/notification_controller.dart - Add this method to handle in-app notifications

// Add this method to show in-app notification snackbar
  void showInAppNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) {
    // Add to local notifications list
    final notification = NotificationItem(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
      isRead: false,
    );

    notifications.insert(0, notification);
    _updateUnreadCount();

    // Show snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primaryGold.withOpacity(0.95),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(
          NotificationTypeData.getData(type).icon,
          color: Colors.white,
          size: 20,
        ),
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            handleNotificationTap(data ?? {});
          },
          child: Text(
            'VIEW',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  // Update unread count
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local list
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        _updateUnreadCount();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();

      for (var notification in unreadNotifications) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notification.id);
        batch.update(ref, {'isRead': true});
      }

      await batch.commit();

      // Update local list
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
      }
      unreadCount.value = 0;

      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error marking all as read: $e');
      Get.snackbar(
        'Error',
        'Failed to mark notifications as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();

      Get.snackbar(
        'Deleted',
        'Notification removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final notificationsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      for (var notification in notifications) {
        batch.delete(notificationsRef.doc(notification.id));
      }

      await batch.commit();
      notifications.clear();
      unreadCount.value = 0;

      Get.snackbar(
        'Cleared',
        'All notifications cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Add notification (can be called from cloud functions or locally)
  Future<void> addNotification(NotificationItem notification) async {
    final userId = _authController.currentUser.value?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  // Setup FCM handlers
// Setup FCM handlers
  void _setupFCMHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleFCMessage(message);
    });

    // Handle when app is opened from background - USE PUBLIC METHOD
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data); // Changed from _handleNotificationTap
    });

    // Check for initial message (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        Future.delayed(const Duration(seconds: 2), () {
          handleNotificationTap(message.data); // Changed from _handleNotificationTap
        });
      }
    });
  }
  // Handle FCM message
// Handle FCM message
  void _handleFCMessage(RemoteMessage message) {
    try {
      // Extract notification data
      final type = message.data['type'] ?? 'system';
      final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      // Parse priority if available
      final priority = message.data['priority'] ?? 'normal';

      print('📱 Processing FCM message - Type: $type, Title: $title');

      // Determine notification type
      NotificationType notificationType;
      switch (type.toLowerCase()) {
        case 'booking':
          notificationType = NotificationType.booking;
          break;
        case 'reminder':
          notificationType = NotificationType.reminder;
          break;
        case 'payment':
          notificationType = NotificationType.payment;
          break;
        case 'offer':
          notificationType = NotificationType.offer;
          break;
        case 'order':
          notificationType = NotificationType.order;
          break;
        case 'loyalty':
          notificationType = NotificationType.loyalty;
          break;
        default:
          notificationType = NotificationType.system;
      }

      // Determine priority
      NotificationPriority notificationPriority;
      switch (priority.toLowerCase()) {
        case 'low':
          notificationPriority = NotificationPriority.low;
          break;
        case 'high':
          notificationPriority = NotificationPriority.high;
          break;
        case 'urgent':
          notificationPriority = NotificationPriority.urgent;
          break;
        default:
          notificationPriority = NotificationPriority.normal;
      }

      // Create notification item
      final notification = NotificationItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        type: notificationType,
        priority: notificationPriority,
        title: title,
        message: body,
        timestamp: DateTime.now(),
        data: message.data,
        imageUrl: message.data['imageUrl'],
        actionUrl: message.data['actionUrl'],
      );

      // Add to local list
      notifications.insert(0, notification);
      _updateUnreadCount();

      // Optionally save to Firestore if user is logged in
      final userId = _authController.currentUser.value?.uid;
      if (userId != null) {
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add(notification.toFirestore())
            .catchError((e) => print('Error saving notification to Firestore: $e'));
      }

      print('✅ FCM message processed and added to notifications');
    } catch (e) {
      print('❌ Error handling FCM message: $e');
    }
  }
  // Handle notification tap
// Change this (private method):

// To this (public method):
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final targetId = data['targetId'];
    final actionUrl = data['actionUrl'];
    print("target Id: $targetId");
    print("type: $type");

    print('🔔 Handling notification tap - Type: $type, TargetId: $targetId');

    // Navigate based on notification type
    switch (type) {
      case 'booking':
        if (targetId != null) {
          Get.to(()=>BookingDetailScreen(bookingId: targetId,));
        } else {
          Get.to(()=>MyBookingsScreen());
        }
        break;
      case 'order':
        if (targetId != null) {
          Get.to(()=>OrderDetailScreen(orderId: targetId));
        } else {
          Get.to(()=>MyBookingsScreen());
        }
        break;
      case 'chat':
        if (targetId != null) {
          Get.to(()=>ChatRoomScreen(roomId: targetId));
        }
        break;
      case 'offer':
        Get.to(() => const CustomerShell());
        break;
      case 'loyalty':
        Get.to(()=>ProfileScreen());
        break;
      default:
        Get.to(()=>NotificationsScreen());
    }
  }
  // Filter notifications
  List<NotificationItem> getFilteredNotifications({
    NotificationType? type,
    bool? unreadOnly,
  }) {
    return notifications.where((n) {
      bool matchesType = type == null || n.type == type;
      bool matchesRead = unreadOnly == null || (unreadOnly && !n.isRead);
      return matchesType && matchesRead;
    }).toList();
  }

  // Group notifications by date
  List<NotificationGroup> getGroupedNotifications() {
    if (notifications.isEmpty) return [];

    final Map<String, List<NotificationItem>> groups = {};

    for (var notification in notifications) {
      final now = DateTime.now();
      final date = notification.timestamp;

      String groupKey;
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groupKey = 'Today';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        groupKey = 'Yesterday';
      } else if (date.year == now.year &&
          date.weekday == now.weekday - 1) {
        groupKey = 'This Week';
      } else {
        groupKey = '${date.day}/${date.month}/${date.year}';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(notification);
    }

    return groups.entries
        .map((e) => NotificationGroup(date: e.key, notifications: e.value))
        .toList()
      ..sort((a, b) {
        if (a.date == 'Today') return -1;
        if (b.date == 'Today') return 1;
        if (a.date == 'Yesterday') return -1;
        if (b.date == 'Yesterday') return 1;
        return 0;
      });
  }

  // Get count by type
  int getCountByType(NotificationType type) {
    return notifications.where((n) => n.type == type).length;
  }

  // Get unread count by type
  int getUnreadCountByType(NotificationType type) {
    return notifications.where((n) => n.type == type && !n.isRead).length;
  }
}