import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id; // Changed from int to String for Firestore document ID
  final String name;
  final String category;
  final String categoryId;
  final String description;
  final double price;
  final double cost;
  final String sku;
  final double rating;
  final int reviews;
  final int totalSold;
  final int totalStock;
  final double revenue;
  final String status;
  final List<String> branchNames;
  final List<String> branches;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Removed: tag, originalPrice, features, discount, inStock

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.cost,
    required this.sku,
    required this.rating,
    required this.reviews,
    required this.totalSold,
    required this.totalStock,
    required this.revenue,
    required this.status,
    required this.branchNames,
    required this.branches,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if product is in stock based on totalStock
  bool get inStock => totalStock > 0;

  // Check if product is low stock
  bool get isLowStock => status == 'low-stock';

  // Check if product is out of stock
  bool get isOutOfStock => totalStock == 0;

  // Calculate profit margin
  double get profitMargin {
    if (cost == 0) return 0;
    return ((price - cost) / cost * 100);
  }

  // Calculate profit per item
  double get profitPerItem => price - cost;

  // Calculate total profit
  double get totalProfit => profitPerItem * totalSold;

  // Get stock status display
  String get stockStatus {
    if (totalStock == 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Get branches count
  int get branchesCount => branches.length;

  // Check if product is available at a specific branch
  bool isAvailableAtBranch(String branchId) {
    return branches.contains(branchId);
  }

  // Check if product is available at any branch
  bool get isAvailable => branches.isNotEmpty;

  // Factory method to create Product from Firestore Document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      sku: data['sku'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      totalSold: (data['totalSold'] as num?)?.toInt() ?? 0,
      totalStock: (data['totalStock'] as num?)?.toInt() ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'in-stock',
      branchNames: List<String>.from(data['branchNames'] ?? []),
      branches: List<String>.from(data['branches'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Product to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'cost': cost,
      'sku': sku,
      'rating': rating,
      'reviews': reviews,
      'totalSold': totalSold,
      'totalStock': totalStock,
      'revenue': revenue,
      'status': status,
      'branchNames': branchNames,
      'branches': branches,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // For backward compatibility (if needed in UI)
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': 0, // Placeholder for legacy int ID
      'name': name,
      'category': category,
      'tag': null,
      'description': description,
      'price': price,
      'originalPrice': null,
      'rating': rating,
      'reviews': reviews,
      'features': [], // Empty array for features
      'image': imageUrl,
      'inStock': inStock,
      'discount': 0,
    };
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryId,
    String? description,
    double? price,
    double? cost,
    String? sku,
    double? rating,
    int? reviews,
    int? totalSold,
    int? totalStock,
    double? revenue,
    String? status,
    List<String>? branchNames,
    List<String>? branches,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      sku: sku ?? this.sku,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      totalSold: totalSold ?? this.totalSold,
      totalStock: totalStock ?? this.totalStock,
      revenue: revenue ?? this.revenue,
      status: status ?? this.status,
      branchNames: branchNames ?? this.branchNames,
      branches: branches ?? this.branches,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}