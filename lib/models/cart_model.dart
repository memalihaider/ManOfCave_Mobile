import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String status;
  final DateTime addedAt;
  final DateTime purchasedAt;

  CartItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.addedAt,
    required this.purchasedAt,
  });

  // Calculate total price for this cart item
  double get totalPrice => price * quantity;

  // Check if item is purchased
  bool get isPurchased => status == 'purchased';

  // Check if item is in cart (pending)
  bool get isInCart => status == 'active';

  // Factory method to create CartItem from Firestore Document
  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CartItem(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      status: data['status'] ?? 'cart',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      purchasedAt: (data['purchasedAt'] as Timestamp).toDate(),
    );
  }

  // Convert CartItem to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'status': status,
      'addedAt': addedAt,
      'purchasedAt': purchasedAt,
    };
  }

  // Copy with method for updates
  CartItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? status,
    DateTime? addedAt,
    DateTime? purchasedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }
}