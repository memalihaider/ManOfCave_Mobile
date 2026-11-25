// models/order_model.dart - Updated with only pickup branch fields (no shipping)
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_strings.dart';

class OrderProduct {
  final String productId;
  final String productName;
  final String productImage;
  final String productCategory;
  final String productCategoryId;
  final double price;
  final double productCost;
  final String productSku;
  final int quantity;
  final List<String> productBranches;
  final List<String> productBranchNames;

  OrderProduct({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productCategory,
    required this.productCategoryId,
    required this.price,
    required this.productCost,
    required this.productSku,
    required this.quantity,
    required this.productBranches,
    required this.productBranchNames,
  });

  double get totalPrice => price * quantity;
  double get totalCost => productCost * quantity;
  double get profit => totalPrice - totalCost;

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? map['image'] ?? '',
      productCategory: map['productCategory'] ?? '',
      productCategoryId: map['productCategoryId'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      productCost: (map['productCost'] as num?)?.toDouble() ?? 0.0,
      productSku: map['productSku'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      productBranches: List<String>.from(map['productBranches'] ?? []),
      productBranchNames: List<String>.from(map['productBranchNames'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productCategory': productCategory,
      'productCategoryId': productCategoryId,
      'price': price,
      'productCost': productCost,
      'productSku': productSku,
      'quantity': quantity,
      'productBranches': productBranches,
      'productBranchNames': productBranchNames,
    };
  }
}

class Order {
  final String id;
  final String transactionId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderProduct> products;
  final List<String> branchNames;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String orderDate;
  final String expectedDeliveryDate;
  final String? orderNotes;
  final bool pointsAwarded;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Pickup branch fields
  final String pickupBranch;
  final String pickupBranchAddress;
  final String pickupBranchPhone;
  final String pickupBranchTiming;

  Order({
    required this.id,
    required this.transactionId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.products,
    required this.branchNames,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderDate,
    required this.expectedDeliveryDate,
    this.orderNotes,
    required this.pointsAwarded,
    required this.createdAt,
    required this.updatedAt,
    required this.pickupBranch,
    required this.pickupBranchAddress,
    required this.pickupBranchPhone,
    required this.pickupBranchTiming,
  });

  // Calculated properties
  int get totalItems => products.fold(0, (sum, product) => sum + product.quantity);
  double get totalCost => products.fold(0.0, (sum, product) => sum + product.totalCost);
  double get totalProfit => products.fold(0.0, (sum, product) => sum + product.profit);

  // Status helpers
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPaymentPending => paymentStatus == 'pending';

  // Pickup info
  bool get hasPickupInfo => pickupBranch.isNotEmpty;

  // Formatted pickup hours for display
  String get formattedPickupHours => pickupBranchTiming;

  // Complete pickup address
  String get fullPickupAddress => '$pickupBranchAddress, $pickupBranch';

  // Format currency
  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ${AppStrings.appCurreny}';
  }

  // Format date for display
  String get formattedOrderDate {
    try {
      final dateParts = orderDate.split('-');
      if (dateParts.length == 3) {
        return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
      }
      return orderDate;
    } catch (e) {
      return orderDate;
    }
  }

  String get formattedExpectedDeliveryDate {
    try {
      final dateParts = expectedDeliveryDate.split('-');
      if (dateParts.length == 3) {
        return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
      }
      return expectedDeliveryDate;
    } catch (e) {
      return expectedDeliveryDate;
    }
  }

  // Factory method to create Order from Firestore Document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper method to safely parse timestamps
    DateTime _parseTimestamp(dynamic timestampData) {
      if (timestampData == null) {
        return DateTime.now();
      }

      if (timestampData is Timestamp) {
        return timestampData.toDate();
      }

      if (timestampData is DateTime) {
        return timestampData;
      }

      try {
        if (timestampData is String) {
          return DateTime.parse(timestampData);
        }

        if (timestampData is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestampData);
        }
      } catch (e) {
        print('Error parsing timestamp: $e');
      }

      return DateTime.now();
    }

    // Safely parse products list
    List<OrderProduct> productsList = [];
    try {
      final productsData = data['products'] as List<dynamic>?;
      if (productsData != null) {
        productsList = productsData
            .where((product) => product is Map<String, dynamic>)
            .map((product) => OrderProduct.fromMap(product as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing products: $e');
    }

    return Order(
      id: doc.id,
      transactionId: data['transactionId']?.toString() ?? '',
      customerId: data['customerId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      customerEmail: data['customerEmail']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      products: productsList,
      branchNames: List<String>.from(data['branchNames'] ?? []),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      orderDate: data['orderDate']?.toString() ?? '',
      expectedDeliveryDate: data['expectedDeliveryDate']?.toString() ?? '',
      orderNotes: data['orderNotes']?.toString(),
      pointsAwarded: data['pointsAwarded'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      pickupBranch: data['pickupBranch']?.toString() ?? '',
      pickupBranchAddress: data['pickupBranchAddress']?.toString() ?? '',
      pickupBranchPhone: data['pickupBranchPhone']?.toString() ?? '',
      pickupBranchTiming: data['pickupBranchTiming']?.toString() ?? '',
    );
  }

  // Convert Order to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'products': products.map((product) => product.toMap()).toList(),
      'branchNames': branchNames,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderDate': orderDate,
      'expectedDeliveryDate': expectedDeliveryDate,
      if (orderNotes != null) 'orderNotes': orderNotes,
      'pointsAwarded': pointsAwarded,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'pickupBranch': pickupBranch,
      'pickupBranchAddress': pickupBranchAddress,
      'pickupBranchPhone': pickupBranchPhone,
      'pickupBranchTiming': pickupBranchTiming,
    };
  }

  // Copy with method for updates
  Order copyWith({
    String? id,
    String? transactionId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    List<OrderProduct>? products,
    List<String>? branchNames,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? orderDate,
    String? expectedDeliveryDate,
    String? orderNotes,
    bool? pointsAwarded,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pickupBranch,
    String? pickupBranchAddress,
    String? pickupBranchPhone,
    String? pickupBranchTiming,
  }) {
    return Order(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      products: products ?? this.products,
      branchNames: branchNames ?? this.branchNames,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      orderNotes: orderNotes ?? this.orderNotes,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupBranch: pickupBranch ?? this.pickupBranch,
      pickupBranchAddress: pickupBranchAddress ?? this.pickupBranchAddress,
      pickupBranchPhone: pickupBranchPhone ?? this.pickupBranchPhone,
      pickupBranchTiming: pickupBranchTiming ?? this.pickupBranchTiming,
    );
  }
}