import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  booking,
  reminder,
  payment,
  offer,
  system,
  order,
  loyalty,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationTypeData {
  final String name;
  final Color color;
  final IconData icon;

  const NotificationTypeData({
    required this.name,
    required this.color,
    required this.icon,
  });

  static NotificationTypeData getData(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return const NotificationTypeData(
          name: 'Booking',
          color: Color(0xFFC5A059),
          icon: Icons.calendar_today,
        );
      case NotificationType.reminder:
        return const NotificationTypeData(
          name: 'Reminder',
          color: Colors.orange,
          icon: Icons.access_time,
        );
      case NotificationType.payment:
        return const NotificationTypeData(
          name: 'Payment',
          color: Colors.green,
          icon: Icons.receipt,
        );
      case NotificationType.offer:
        return const NotificationTypeData(
          name: 'Offer',
          color: Colors.purple,
          icon: Icons.local_offer,
        );
      case NotificationType.system:
        return const NotificationTypeData(
          name: 'System',
          color: Colors.blue,
          icon: Icons.system_update,
        );
      case NotificationType.order:
        return const NotificationTypeData(
          name: 'Order',
          color: Colors.teal,
          icon: Icons.shopping_bag,
        );
      case NotificationType.loyalty:
        return const NotificationTypeData(
          name: 'Loyalty',
          color: Colors.pink,
          icon: Icons.stars,
        );
    }
  }
}

class NotificationPriorityData {
  final String name;
  final Color color;
  final int value;

  const NotificationPriorityData({
    required this.name,
    required this.color,
    required this.value,
  });

  static NotificationPriorityData getData(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return const NotificationPriorityData(
          name: 'Low',
          color: Colors.grey,
          value: 1,
        );
      case NotificationPriority.normal:
        return const NotificationPriorityData(
          name: 'Normal',
          color: Colors.blue,
          value: 2,
        );
      case NotificationPriority.high:
        return const NotificationPriorityData(
          name: 'High',
          color: Colors.orange,
          value: 3,
        );
      case NotificationPriority.urgent:
        return const NotificationPriorityData(
          name: 'Urgent',
          color: Colors.red,
          value: 4,
        );
    }
  }
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationItem({
    required this.id,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });

  // Get formatted time for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get type data
  NotificationTypeData get typeData => NotificationTypeData.getData(type);

  // Get priority data
  NotificationPriorityData get priorityData => NotificationPriorityData.getData(priority);

  // Create from Firestore
  factory NotificationItem.fromFirestore(
      Map<String, dynamic> data,
      String id,
      ) {
    return NotificationItem(
      id: id,
      type: _parseNotificationType(data['type'] ?? 'system'),
      priority: _parseNotificationPriority(data['priority'] ?? 'normal'),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  // Create a copy with modifications
  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Parse notification type from string
  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return NotificationType.booking;
      case 'reminder':
        return NotificationType.reminder;
      case 'payment':
        return NotificationType.payment;
      case 'offer':
        return NotificationType.offer;
      case 'order':
        return NotificationType.order;
      case 'loyalty':
        return NotificationType.loyalty;
      default:
        return NotificationType.system;
    }
  }

  // Parse priority from string
  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}

// For grouping notifications by date
class NotificationGroup {
  final String date;
  final List<NotificationItem> notifications;

  NotificationGroup({
    required this.date,
    required this.notifications,
  });
}