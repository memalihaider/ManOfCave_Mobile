import 'package:cloud_firestore/cloud_firestore.dart';

class BannerItem {
  final String id; // Changed from int to String for Firestore document ID
  final String title;
  final String description;
  final String imageUrl;
  final String offerType; // 'service' or 'product'
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final String status; // 'active' or 'inactive'
  final int? usageLimit;
  final int usedCount;
  final List<String> applicableServices; // Service IDs
  final List<String> applicableProducts; // Product IDs
  final List<String> branchNames;
  final List<String> branches; // Branch IDs
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isExpiringNotificationSent; // Added field for expiring notification tracking

  BannerItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.offerType,
    required this.discountType,
    required this.discountValue,
    required this.status,
    this.usageLimit,
    required this.usedCount,
    required this.applicableServices,
    required this.applicableProducts,
    required this.branchNames,
    required this.branches,
    required this.validFrom,
    required this.validTo,
    required this.createdAt,
    required this.updatedAt,
    this.isExpiringNotificationSent = false, // Default to false
  });

  // Check if banner is active
  bool get isActive => status == 'active';

  // Check if banner is for services
  bool get isServiceOffer => offerType == 'service';

  // Check if banner is for products
  bool get isProductOffer => offerType == 'product';

  // Check if banner has usage limit reached
  bool get isUsageLimitReached {
    if (usageLimit == null) return false;
    return usedCount >= usageLimit!;
  }

  // Check if banner is currently valid
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validTo) &&
        !isUsageLimitReached;
  }

  // Check if banner is expiring soon (within next 3 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return isValid && validTo.isBefore(threeDaysFromNow);
  }

  // Get days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    final difference = validTo.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Get expiry status text
  String get expiryStatusText {
    if (!isValid) return 'Expired';
    if (isExpiringSoon) {
      if (daysUntilExpiry == 0) return 'Expires today';
      if (daysUntilExpiry == 1) return 'Expires tomorrow';
      return 'Expires in $daysUntilExpiry days';
    }
    return 'Valid';
  }

  // Get expiry status color
  String get expiryStatusColor {
    if (!isValid) return 'red';
    if (isExpiringSoon) return 'orange';
    return 'green';
  }

  // Get discount display text
  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.round()}% OFF';
    } else {
      return 'د.إ${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  // Get validity period display
  String get validityPeriod {
    final from = validFrom.toLocal().toString().split(' ')[0];
    final to = validTo.toLocal().toString().split(' ')[0];
    return 'Valid: $from to $to';
  }

  // Check if banner is applicable to specific service
  bool isApplicableToService(String serviceId) {
    return applicableServices.contains(serviceId);
  }

  // Check if banner is applicable to specific product
  bool isApplicableToProduct(String productId) {
    return applicableProducts.contains(productId);
  }

  // Check if banner is applicable to specific branch
  bool isApplicableToBranch(String branchId) {
    return branches.contains(branchId);
  }

  // Get applicable items count
  int get applicableItemsCount {
    if (isServiceOffer) {
      return applicableServices.length;
    } else {
      return applicableProducts.length;
    }
  }

  // Get branches count
  int get branchesCount => branches.length;

  // Factory method to create BannerItem from Firestore Document
  factory BannerItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BannerItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      offerType: data['offerType'] ?? 'service',
      discountType: data['discountType'] ?? 'percentage',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
      usageLimit: data['usageLimit'] as int?,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      applicableServices: List<String>.from(data['applicableServices'] ?? []),
      applicableProducts: List<String>.from(data['applicableProducts'] ?? []),
      branchNames: List<String>.from(data['branchNames'] ?? []),
      branches: List<String>.from(data['branches'] ?? []),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isExpiringNotificationSent: data['isExpiringNotificationSent'] as bool? ?? false,
    );
  }

  // Convert BannerItem to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'offerType': offerType,
      'discountType': discountType,
      'discountValue': discountValue,
      'status': status,
      if (usageLimit != null) 'usageLimit': usageLimit,
      'usedCount': usedCount,
      'applicableServices': applicableServices,
      'applicableProducts': applicableProducts,
      'branchNames': branchNames,
      'branches': branches,
      'validFrom': validFrom,
      'validTo': validTo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isExpiringNotificationSent': isExpiringNotificationSent,
    };
  }

  // For backward compatibility (if needed in UI)
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': 0, // Placeholder for legacy int ID
      'image': imageUrl,
      'title': title,
      'description': description,
      'validUntil': validTo.toLocal().toString().split(' ')[0],
    };
  }

  // Copy with method for updates
  BannerItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? offerType,
    String? discountType,
    double? discountValue,
    String? status,
    int? usageLimit,
    int? usedCount,
    List<String>? applicableServices,
    List<String>? applicableProducts,
    List<String>? branchNames,
    List<String>? branches,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isExpiringNotificationSent,
  }) {
    return BannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      offerType: offerType ?? this.offerType,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      status: status ?? this.status,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      applicableServices: applicableServices ?? this.applicableServices,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      branchNames: branchNames ?? this.branchNames,
      branches: branches ?? this.branches,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isExpiringNotificationSent: isExpiringNotificationSent ?? this.isExpiringNotificationSent,
    );
  }
}