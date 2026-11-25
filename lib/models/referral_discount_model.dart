// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ReferralDiscountModel {
//   final String id;
//   final double friendDiscount; // Discount for the friend who uses the code (percentage or fixed)
//   final double referrerDiscountPerUsage; // Discount for the referrer per usage
//   final bool isPercentageDiscount; // true = percentage, false = fixed amount
//   final bool isActive;
//   final int maxUsagesPerReferralCode; // Max times a referral code can be used
//   final int maxDiscountPerUser; // Max discount a user can earn from referrals
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String? description;
//
//   ReferralDiscountModel({
//     required this.id,
//     required this.friendDiscount,
//     required this.referrerDiscountPerUsage,
//     required this.isPercentageDiscount,
//     required this.isActive,
//     required this.maxUsagesPerReferralCode,
//     required this.maxDiscountPerUser,
//     required this.createdAt,
//     required this.updatedAt,
//     this.description,
//   });
//
//   factory ReferralDiscountModel.fromFirestore(Map<String, dynamic> data, String id) {
//     return ReferralDiscountModel(
//       id: id,
//       friendDiscount: (data['friendDiscount'] as num?)?.toDouble() ?? 10.0,
//       referrerDiscountPerUsage: (data['referrerDiscountPerUsage'] as num?)?.toDouble() ?? 5.0,
//       isPercentageDiscount: data['isPercentageDiscount'] ?? true,
//       isActive: data['isActive'] ?? true,
//       maxUsagesPerReferralCode: data['maxUsagesPerReferralCode'] ?? 10,
//       maxDiscountPerUser: data['maxDiscountPerUser'] ?? 100,
//       createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
//       updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
//       description: data['description'],
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'friendDiscount': friendDiscount,
//       'referrerDiscountPerUsage': referrerDiscountPerUsage,
//       'isPercentageDiscount': isPercentageDiscount,
//       'isActive': isActive,
//       'maxUsagesPerReferralCode': maxUsagesPerReferralCode,
//       'maxDiscountPerUser': maxDiscountPerUser,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//       if (description != null) 'description': description,
//     };
//   }
//
//   static DateTime? _parseTimestamp(dynamic timestamp) {
//     if (timestamp == null) return null;
//     if (timestamp is DateTime) return timestamp;
//     if (timestamp is Timestamp) return timestamp.toDate();
//     return null;
//   }
//
//   // Helper method to apply discount
//   double applyDiscount(double originalPrice, bool isFriend) {
//     final discount = isFriend ? friendDiscount : referrerDiscountPerUsage;
//     if (isPercentageDiscount) {
//       return originalPrice * (discount / 100);
//     } else {
//       return discount > originalPrice ? originalPrice : discount;
//     }
//   }
//
//   // Get discount amount based on price
//   double getDiscountAmount(double originalPrice, bool isFriend) {
//     if (isPercentageDiscount) {
//       return originalPrice * (friendDiscount / 100);
//     } else {
//       return friendDiscount;
//     }
//   }
//
//   ReferralDiscountModel copyWith({
//     String? id,
//     double? friendDiscount,
//     double? referrerDiscountPerUsage,
//     bool? isPercentageDiscount,
//     bool? isActive,
//     int? maxUsagesPerReferralCode,
//     int? maxDiscountPerUser,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     String? description,
//   }) {
//     return ReferralDiscountModel(
//       id: id ?? this.id,
//       friendDiscount: friendDiscount ?? this.friendDiscount,
//       referrerDiscountPerUsage: referrerDiscountPerUsage ?? this.referrerDiscountPerUsage,
//       isPercentageDiscount: isPercentageDiscount ?? this.isPercentageDiscount,
//       isActive: isActive ?? this.isActive,
//       maxUsagesPerReferralCode: maxUsagesPerReferralCode ?? this.maxUsagesPerReferralCode,
//       maxDiscountPerUser: maxDiscountPerUser ?? this.maxDiscountPerUser,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       description: description ?? this.description,
//     );
//   }
// }
