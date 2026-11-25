// models/loyalty_transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  earned,
  redeemed,
  bonus,
  expired,
  adjustment,
  feedback
}

enum TransactionSource {
  serviceBooking,
  productPurchase,
  registration,
  birthday,
  adminAdded,
  rewardRedemption,
  expiry, // ADD THIS LINE
  feedback
}

class LoyaltyTransaction {
  final String id;
  final String customerId;
  final TransactionType type;
  final TransactionSource source;
  final String sourceId; // bookingId, purchaseId, etc.
  final int points;
  final String description;
  final DateTime date;
  final DateTime? expiryDate;
  final String? branchId;
  final String? branchName;
  final String? adminId;
  final String? adminName;
  final Map<String, dynamic>? metadata;

  LoyaltyTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.source,
    required this.sourceId,
    required this.points,
    required this.description,
    required this.date,
    this.expiryDate,
    this.branchId,
    this.branchName,
    this.adminId,
    this.adminName,
    this.metadata,
  });

  // Factory method to create from Firestore Document
  factory LoyaltyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse type
    TransactionType parseType(String type) {
      switch (type) {
        case 'redeemed':
          return TransactionType.redeemed;
        case 'bonus':
          return TransactionType.bonus;
        case 'expired':
          return TransactionType.expired;
        case 'adjustment':
          return TransactionType.adjustment;
        case 'feedback':
          return TransactionType.feedback;
        default:
          return TransactionType.earned;
      }
    }

    // Parse source
    TransactionSource parseSource(String source) {
      switch (source) {
        case 'product_purchase':
          return TransactionSource.productPurchase;
        case 'registration':
          return TransactionSource.registration;
        case 'birthday':
          return TransactionSource.birthday;
        case 'admin_added':
          return TransactionSource.adminAdded;
        case 'feedback':
          return TransactionSource.feedback;
        case 'reward_redemption':
          return TransactionSource.rewardRedemption;
        case 'expiry':
          return TransactionSource.expiry;
        default:
          return TransactionSource.serviceBooking;
      }
    }

    return LoyaltyTransaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      type: parseType(data['type'] ?? 'earned'),
      source: parseSource(data['source'] ?? 'service_booking'),
      sourceId: data['sourceId'] ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      branchId: data['branchId'],
      branchName: data['branchName'],
      adminId: data['adminId'],
      adminName: data['adminName'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final typeString = type.toString().split('.').last;
    final sourceString = source.toString().split('.').last;

    return {
      'customerId': customerId,
      'type': typeString,
      'source': sourceString,
      'sourceId': sourceId,
      'points': points,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      if (branchId != null) 'branchId': branchId,
      if (branchName != null) 'branchName': branchName,
      if (adminId != null) 'adminId': adminId,
      if (adminName != null) 'adminName': adminName,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Get transaction icon
  String get icon {
    switch (type) {
      case TransactionType.earned:
        return '💰';
      case TransactionType.bonus:
        return '🎁';
      case TransactionType.redeemed:
        return '🛒';
      case TransactionType.expired:
        return '⏰';
      case TransactionType.feedback:
        return '⚙️';
      case TransactionType.adjustment:
        return '⚙️';
    }
  }

  // Get transaction color
  String get color {
    switch (type) {
      case TransactionType.earned:
      case TransactionType.bonus:
        return 'green';
      case TransactionType.redeemed:
        return 'orange';
      case TransactionType.expired:
        return 'red';
      case TransactionType.feedback:
        return 'yellow';
      case TransactionType.adjustment:
        return 'blue';
    }
  }

  // Check if it's a positive transaction
  bool get isPositive =>
      type == TransactionType.earned ||
          type == TransactionType.bonus;

  // Get points with sign
  String get pointsWithSign => isPositive ? '+$points' : '-$points';

  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Check if transaction is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Get remaining days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    if (expiryDate!.isBefore(now)) return 0;
    return expiryDate!.difference(now).inDays;
  }
}