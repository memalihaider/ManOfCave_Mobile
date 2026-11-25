import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLogin;

  // Referral fields
  final String? referralCode; // Unique code for this user to share
  final String? referredBy; // UID of the user who referred this customer
  final String? referredByCode; // Code used to sign up
  final int referralCount; // Number of successful referrals made by this user
  final double referralEarnings; // Total discount earned from referrals
  final double referralDiscountUsed; // Total discount used from referrals

  CustomerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
    this.referralCode,
    this.referredBy,
    this.referredByCode,
    this.referralCount = 0,
    this.referralEarnings = 0.0,
    this.referralDiscountUsed = 0.0,
  });

  // Check if user has referral code
  bool get hasReferralCode => referralCode != null && referralCode!.isNotEmpty;

  // Check if user was referred
  bool get wasReferred => referredBy != null && referredBy!.isNotEmpty;

  // Factory method from Firestore
  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
      return DateTime.now();
    }

    return CustomerModel(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      role: data['role']?.toString() ?? 'customer',
      status: data['status']?.toString() ?? 'active',
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastLogin: _parseTimestamp(data['lastLogin']),
      referralCode: data['referralCode']?.toString(),
      referredBy: data['referredBy']?.toString(),
      referredByCode: data['referredByCode']?.toString(),
      referralCount: (data['referralCount'] as num?)?.toInt() ?? 0,
      referralEarnings: (data['referralEarnings'] as num?)?.toDouble() ?? 0.0,
      referralDiscountUsed: (data['referralDiscountUsed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Factory from User Firestore (for backward compatibility)
  factory CustomerModel.fromUserFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
      return DateTime.now();
    }

    return CustomerModel(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      role: data['role']?.toString() ?? 'customer',
      status: data['status']?.toString() ?? 'active',
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      lastLogin: _parseTimestamp(data['lastLogin']),
      referralCode: data['referralCode']?.toString(),
      referredBy: data['referredBy']?.toString(),
      referredByCode: data['referredByCode']?.toString(),
      referralCount: (data['referralCount'] as num?)?.toInt() ?? 0,
      referralEarnings: (data['referralEarnings'] as num?)?.toDouble() ?? 0.0,
      referralDiscountUsed: (data['referralDiscountUsed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      if (referralCode != null) 'referralCode': referralCode,
      if (referredBy != null) 'referredBy': referredBy,
      if (referredByCode != null) 'referredByCode': referredByCode,
      'referralCount': referralCount,
      'referralEarnings': referralEarnings,
      'referralDiscountUsed': referralDiscountUsed,
    };
  }

  // Copy with method
  CustomerModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    String? referralCode,
    String? referredBy,
    String? referredByCode,
    int? referralCount,
    double? referralEarnings,
    double? referralDiscountUsed,
  }) {
    return CustomerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referredByCode: referredByCode ?? this.referredByCode,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      referralDiscountUsed: referralDiscountUsed ?? this.referralDiscountUsed,
    );
  }

  // Getters
  bool get isActive => status == 'active';
  bool get isVerified => emailVerified;
  String get displayName => name;

  String get avatarInitials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  int get accountAgeInDays {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  String get lastLoginDisplay {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}