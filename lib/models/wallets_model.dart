import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer e-wallet snapshot aligned with portal `wallets` docs.
/// [balance] is AED (never loyalty points).
class CustomerWallet {
  final String id;
  final String customerId;
  final int balance;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final DateTime updatedAt;

  CustomerWallet({
    required this.id,
    required this.customerId,
    required this.balance,
    required this.totalPointsEarned,
    required this.totalPointsRedeemed,
    required this.updatedAt,
  });

  factory CustomerWallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final balance = (data['balance'] as num?)?.toInt() ?? 0;

    return CustomerWallet(
      id: doc.id,
      customerId: data['customerId']?.toString() ?? doc.id,
      balance: balance < 0 ? 0 : balance,
      totalPointsEarned: (data['totalPointsEarned'] as num?)?.toInt() ?? 0,
      totalPointsRedeemed: (data['totalPointsRedeemed'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'balance': balance,
      'totalPointsEarned': totalPointsEarned,
      'totalPointsRedeemed': totalPointsRedeemed,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CustomerWallet copyWith({
    String? id,
    String? customerId,
    int? balance,
    int? totalPointsEarned,
    int? totalPointsRedeemed,
    DateTime? updatedAt,
  }) {
    return CustomerWallet(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      balance: balance ?? this.balance,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsRedeemed: totalPointsRedeemed ?? this.totalPointsRedeemed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedBalance => 'AED ${balance.toStringAsFixed(2)}';
}
