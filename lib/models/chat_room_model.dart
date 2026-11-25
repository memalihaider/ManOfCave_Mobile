import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatRoom {
  final String roomId;
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageSenderName;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String roomType; // 'customer_branch', 'branch_super', 'branch_branch'
  final String? branchId;
  final String? branchName;
  final String? customerId;
  final String? customerName;
  final String? adminId;
  final String? adminName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> readBy; // NEW FIELD: Users who have read the last message

  ChatRoom({
    required this.roomId,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageSenderName,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.participants,
    required this.participantNames,
    required this.participantRoles,
    required this.roomType,
    this.branchId,
    this.branchName,
    this.customerId,
    this.customerName,
    this.adminId,
    this.adminName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.readBy, // NEW: Add this parameter
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatRoom(
      roomId: doc.id,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageSenderName: data['lastMessageSenderName'] ?? '',
      lastMessageTime: _parseTimestamp(data['lastMessageTime']),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantRoles: Map<String, String>.from(data['participantRoles'] ?? {}),
      roomType: data['roomType'] ?? 'customer_branch',
      branchId: data['branchId'],
      branchName: data['branchName'],
      customerId: data['customerId'],
      customerName: data['customerName'],
      adminId: data['adminId'],
      adminName: data['adminName'],
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      readBy: List<String>.from(data['readBy'] ?? []), // NEW: Parse readBy from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'participants': participants,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'roomType': roomType,
      if (branchId != null) 'branchId': branchId,
      if (branchName != null) 'branchName': branchName,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (adminId != null) 'adminId': adminId,
      if (adminName != null) 'adminName': adminName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'readBy': readBy, // NEW: Include readBy in Firestore
    };
  }

  // Helper methods
  String get formattedLastMessageTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      lastMessageTime.year,
      lastMessageTime.month,
      lastMessageTime.day,
    );

    if (messageDate.isAtSameMomentAs(today)) {
      return DateFormat('hh:mm a').format(lastMessageTime);
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(lastMessageTime);
    } else {
      return DateFormat('dd/MM/yy').format(lastMessageTime);
    }
  }

  String get otherParticipantId {
    return participants.firstWhere(
          (id) => id != lastMessageSenderId,
      orElse: () => participants.first,
    );
  }

  String get otherParticipantName {
    return participantNames[otherParticipantId] ?? 'Unknown';
  }

  String get displayName {
    if (roomType == 'customer_branch' && customerName != null) {
      return customerName!;
    } else if (roomType == 'branch_super' && branchName != null) {
      return '$branchName Branch';
    } else if (roomType == 'branch_branch' && branchName != null) {
      return branchName!;
    }
    return otherParticipantName;
  }

  // NEW: Check if user has unread messages
  bool hasUnreadForUser(String userId) {
    // If sender is the user, they've "read" their own message
    if (lastMessageSenderId == userId) return false;

    // Check if user is in readBy list
    return !readBy.contains(userId) && lastMessage.isNotEmpty;
  }

  // Get other participant ID based on current user ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => participants.first,
    );
  }

  // Get other participant name based on current user ID
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  // For backward compatibility
  bool get hasUnread => unreadCount > 0;

  ChatRoom copyWith({
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    DateTime? updatedAt,
    List<String>? readBy, // NEW: Add readBy to copyWith
  }) {
    return ChatRoom(
      roomId: roomId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participants: participants,
      participantNames: participantNames,
      participantRoles: participantRoles,
      roomType: roomType,
      branchId: branchId,
      branchName: branchName,
      customerId: customerId,
      customerName: customerName,
      adminId: adminId,
      adminName: adminName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readBy: readBy ?? this.readBy, // NEW: Include readBy
    );
  }
}