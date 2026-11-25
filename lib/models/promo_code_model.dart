// models/promo_code_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_strings.dart';

class PromoCodeModel {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? maximumDiscount; // For percentage discounts, max discount amount
  final double? minimumPurchase;
  final String status; // 'active' or 'inactive'
  final String? imageUrl; // Optional image URL for promo code banner
  final int? usageLimit;
  final int usedCount;
  final List<String> branchNames;
  final List<String> branches; // Branch IDs
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maximumDiscount,
    this.minimumPurchase,
    required this.status,
    this.imageUrl,
    this.usageLimit,
    required this.usedCount,
    required this.branchNames,
    required this.branches,
    required this.validFrom,
    required this.validTo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if promo code is active
  bool get isActive => status == 'active';

  // Check if promo code is currently valid
  bool get isValid {
    final now = DateTime.now();
    final isValid = isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validTo) &&
        !isUsageLimitReached;

    print('🔍 Checking promo code validity: ${code}');
    print('   - isActive: $isActive');
    print('   - validFrom: $validFrom');
    print('   - validTo: $validTo');
    print('   - now: $now');
    print('   - isUsageLimitReached: $isUsageLimitReached');
    print('   - isValid: $isValid');

    return isValid;
  }

  // Check if usage limit reached
  bool get isUsageLimitReached {
    if (usageLimit == null) return false;
    final reached = usedCount >= usageLimit!;
    if (reached) {
      print('⚠️ Promo code ${code} has reached usage limit: $usedCount/${usageLimit}');
    }
    return reached;
  }

  // Check if promo code is applicable to specific branch
  bool isApplicableToBranch(String branchId) {
    final applicable = branches.contains(branchId);
    print('🔍 Checking promo code ${code} applicability to branch ID $branchId: $applicable');
    return applicable;
  }

  // Check if promo code is applicable to branch name
  bool isApplicableToBranchName(String branchName) {
    final applicable = branchNames.contains(branchName);
    print('🔍 Checking promo code ${code} applicability to branch name $branchName: $applicable');
    return applicable;
  }

  // Check if promo code has minimum purchase requirement
  bool meetsMinimumPurchase(double orderTotal) {
    if (minimumPurchase == null) return true;
    final meets = orderTotal >= minimumPurchase!;
    if (!meets) {
      print('⚠️ Promo code ${code} requires minimum purchase of ${minimumPurchase}, order total: $orderTotal');
    }
    return meets;
  }

  // Calculate discount amount for a given price
  double calculateDiscount(double price) {
    if (!isValid) {
      print('⚠️ Promo code ${code} is not valid, discount = 0');
      return 0;
    }

    if (!meetsMinimumPurchase(price)) {
      print('⚠️ Promo code ${code} does not meet minimum purchase requirement');
      return 0;
    }

    double discount = 0;
    if (discountType == 'percentage') {
      discount = price * (discountValue / 100);
      if (maximumDiscount != null && discount > maximumDiscount!) {
        print('📊 Applying maximum discount limit: ${maximumDiscount} (original: $discount)');
        discount = maximumDiscount!;
      }
      print('📊 Percentage discount: ${discountValue}% on $price = $discount');
    } else {
      discount = discountValue;
      print('📊 Fixed discount: $discountValue on $price');
    }

    // Ensure discount doesn't exceed price
    if (discount > price) {
      print('⚠️ Discount $discount exceeds price $price, limiting to price');
      discount = price;
    }

    return discount;
  }

  // Get discount display text
  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.round()}% OFF';
    } else {
      return '${discountValue.toStringAsFixed(0)} ${AppStrings.appCurreny} OFF';
    }
  }

  // Get validity period display
  String get validityPeriod {
    final from = validFrom.toLocal().toString().split(' ')[0];
    final to = validTo.toLocal().toString().split(' ')[0];
    return 'Valid: $from to $to';
  }

  // Check if promo code has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Factory method to create from Firestore
  factory PromoCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    print('📦 Creating PromoCodeModel from Firestore: ${doc.id}');
    print('   - Code: ${data['code']}');
    print('   - Discount: ${data['discountValue']} ${data['discountType']}');
    print('   - Image URL exists: ${data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty}');

    return PromoCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] ?? 'fixed',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      maximumDiscount: (data['maximumDiscount'] as num?)?.toDouble(),
      minimumPurchase: (data['minimumPurchase'] as num?)?.toDouble(),
      status: data['status'] ?? 'active',
      imageUrl: data['imageUrl'] as String?,
      usageLimit: data['usageLimit'] as int?,
      usedCount: (data['usedCount'] as num?)?.toInt() ?? 0,
      branchNames: List<String>.from(data['branchNames'] ?? []),
      branches: List<String>.from(data['branches'] ?? []),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    final data = {
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
      if (minimumPurchase != null) 'minimumPurchase': minimumPurchase,
      'status': status,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (usageLimit != null) 'usageLimit': usageLimit,
      'usedCount': usedCount,
      'branchNames': branchNames,
      'branches': branches,
      'validFrom': validFrom,
      'validTo': validTo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    print('📦 Converting PromoCodeModel to Firestore: $code');
    print('   - Has image: ${imageUrl != null && imageUrl!.isNotEmpty}');

    return data;
  }

  // Copy with method for updates
  PromoCodeModel copyWith({
    String? id,
    String? code,
    String? description,
    String? discountType,
    double? discountValue,
    double? maximumDiscount,
    double? minimumPurchase,
    String? status,
    String? imageUrl,
    int? usageLimit,
    int? usedCount,
    List<String>? branchNames,
    List<String>? branches,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      branchNames: branchNames ?? this.branchNames,
      branches: branches ?? this.branches,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get promo code summary for UI
  Map<String, dynamic> get summary {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discountDisplay': discountDisplay,
      'isValid': isValid,
      'hasImage': hasImage,
      'imageUrl': imageUrl,
      'validityPeriod': validityPeriod,
      'branches': branchNames.isNotEmpty ? branchNames.first : 'All Branches',
    };
  }

  // Debug method to print all details
  void debugPrint() {
    print('========== PROMO CODE DETAILS ==========');
    print('ID: $id');
    print('Code: $code');
    print('Description: $description');
    print('Discount Type: $discountType');
    print('Discount Value: $discountValue');
    print('Maximum Discount: $maximumDiscount');
    print('Minimum Purchase: $minimumPurchase');
    print('Status: $status');
    print('Has Image: ${hasImage}');
    if (hasImage) print('Image URL: $imageUrl');
    print('Usage Limit: $usageLimit');
    print('Used Count: $usedCount');
    print('Branch Names: $branchNames');
    print('Branch IDs: $branches');
    print('Valid From: $validFrom');
    print('Valid To: $validTo');
    print('Created At: $createdAt');
    print('Updated At: $updatedAt');
    print('Is Valid: ${isValid}');
    print('=======================================');
  }
}