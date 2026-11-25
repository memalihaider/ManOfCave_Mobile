class PaymentIntent {
  final String id;
  final String clientSecret;
  final String paymentId;
  final double amount;
  final String currency;
  final String status;

  PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] ?? '',
      clientSecret: json['clientSecret'] ?? json['client_secret'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'AED',
      status: json['status'] ?? 'pending',
    );
  }
}