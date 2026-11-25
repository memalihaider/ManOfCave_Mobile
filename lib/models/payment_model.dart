import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

enum PaymentType {
  booking,
  order,
}

class Payment {
  final String id;
  final String userId;
  final String transactionId;
  final PaymentStatus status;
  final PaymentType type;
  final String referenceId;
  final double amount;
  final String currency;
  final String? description;
  final Map<String, dynamic> stripeData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  Payment({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.status,
    required this.type,
    required this.referenceId,
    required this.amount,
    required this.currency,
    this.description,
    this.stripeData = const {},
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.errorMessage,
  });

  bool get isSuccessful => status == PaymentStatus.succeeded;
  bool get isPending => status == PaymentStatus.pending;

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      transactionId: data['transactionId'] ?? '',
      status: _parseStatus(data['status'] ?? 'pending'),
      type: _parseType(data['type'] ?? 'booking'),
      referenceId: data['referenceId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'AED',
      description: data['description'],
      stripeData: Map<String, dynamic>.from(data['stripeData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'transactionId': transactionId,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'referenceId': referenceId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'stripeData': stripeData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'errorMessage': errorMessage,
    };
  }

  static PaymentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded': return PaymentStatus.succeeded;
      case 'failed': return PaymentStatus.failed;
      case 'cancelled': return PaymentStatus.cancelled;
      case 'refunded': return PaymentStatus.refunded;
      case 'processing': return PaymentStatus.processing;
      default: return PaymentStatus.pending;
    }
  }

  static PaymentType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'order': return PaymentType.order;
      default: return PaymentType.booking;
    }
  }
}