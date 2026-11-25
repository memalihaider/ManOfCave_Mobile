import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id; // Changed from int to String for Firestore document ID
  final String name;
  final String category;
  final String categoryId;
  final String description;
  final int duration; // Changed from String to int
  final double price;
  final String popularity; // Changed from bool popular to String popularity
  final int totalBookings;
  final double revenue;
  final List<String> branches; // List of branch document IDs
  final List<String> branchNames; // List of branch names
  final String imageUrl; // Changed from image to imageUrl
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Removed: originalPrice, rating, reviews, locations, branchesCount, features, popular

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.description,
    required this.duration,
    required this.price,
    required this.popularity,
    required this.totalBookings,
    required this.revenue,
    required this.branches,
    required this.branchNames,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if service is active
  bool get isActive => status == 'active';

  // Check if service is popular based on popularity field
  bool get isPopular => popularity == 'high';

  // Get display duration (e.g., "69 min")
  String get displayDuration => '$duration min';

  // Calculate average revenue per booking
  double get averageRevenuePerBooking {
    return totalBookings > 0 ? revenue / totalBookings : 0;
  }

  // Check if service is available at a specific branch
  bool isAvailableAtBranch(String branchId) {
    return branches.contains(branchId);
  }

  // Check if service is available at any branch
  bool get isAvailable => branches.isNotEmpty;

  // Get branches count
  int get branchesCount => branches.length;

  // Factory method to create Service from Firestore Document
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      popularity: data['popularity'] ?? 'low',
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
      branches: List<String>.from(data['branches'] ?? []),
      branchNames: List<String>.from(data['branchNames'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Service to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'description': description,
      'duration': duration,
      'price': price,
      'popularity': popularity,
      'totalBookings': totalBookings,
      'revenue': revenue,
      'branches': branches,
      'branchNames': branchNames,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for updates
  ServiceModel copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryId,
    String? description,
    int? duration,
    double? price,
    String? popularity,
    int? totalBookings,
    double? revenue,
    List<String>? branches,
    List<String>? branchNames,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      popularity: popularity ?? this.popularity,
      totalBookings: totalBookings ?? this.totalBookings,
      revenue: revenue ?? this.revenue,
      branches: branches ?? this.branches,
      branchNames: branchNames ?? this.branchNames,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // For backward compatibility (if needed in UI)
  Map<String, dynamic> toLegacyMap() {
    return {
      'id': 0, // Placeholder for legacy int ID
      'name': name,
      'category': category,
      'description': description,
      'duration': '$duration min',
      'price': price,
      'rating': 0.0, // Default rating
      'reviews': 0, // Default reviews
      'locations': branchNames,
      'branchesCount': branchesCount,
      'features': [], // Empty array for features
      'image': imageUrl,
      'popular': isPopular,
    };
  }
}