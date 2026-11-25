// models/feedback_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String comment;
  final DateTime createdAt;
  final String customerEmail;
  final String customerId;
  final String customerName;
  final bool pointsAwarded;
  final int rating;
  final List<String> serviceBranchNames;
  final List<String> serviceBranches;
  final String serviceCategory;
  final String serviceCategoryId;
  final DateTime serviceCreatedAt;
  final String serviceDescription;
  final int serviceDuration;
  final String serviceId;
  final String serviceImageUrl;
  final String serviceName;
  final String serviceOrProduct;
  final String servicePopularity;
  final double servicePrice;
  final double serviceRevenue;
  final String serviceStatus;
  final int serviceTotalBookings;
  final DateTime serviceUpdatedAt;
  final String status; // feedback status: pending, approved, rejected
  final String type; // service or product

  FeedbackModel({
    required this.id,
    required this.comment,
    required this.createdAt,
    required this.customerEmail,
    required this.customerId,
    required this.customerName,
    required this.pointsAwarded,
    required this.rating,
    required this.serviceBranchNames,
    required this.serviceBranches,
    required this.serviceCategory,
    required this.serviceCategoryId,
    required this.serviceCreatedAt,
    required this.serviceDescription,
    required this.serviceDuration,
    required this.serviceId,
    required this.serviceImageUrl,
    required this.serviceName,
    required this.serviceOrProduct,
    required this.servicePopularity,
    required this.servicePrice,
    required this.serviceRevenue,
    required this.serviceStatus,
    required this.serviceTotalBookings,
    required this.serviceUpdatedAt,
    required this.status,
    required this.type,
  });

  // Factory constructor to create a FeedbackModel from Firestore Document
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FeedbackModel(
      id: doc.id,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerEmail: data['customerEmail'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      pointsAwarded: data['pointsAwarded'] ?? false,
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      serviceBranchNames: List<String>.from(data['serviceBranchNames'] ?? []),
      serviceBranches: List<String>.from(data['serviceBranches'] ?? []),
      serviceCategory: data['serviceCategory'] ?? '',
      serviceCategoryId: data['serviceCategoryId'] ?? '',
      serviceCreatedAt: (data['serviceCreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      serviceDescription: data['serviceDescription'] ?? '',
      serviceDuration: (data['serviceDuration'] as num?)?.toInt() ?? 0,
      serviceId: data['serviceId'] ?? '',
      serviceImageUrl: data['serviceImageUrl'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceOrProduct: data['serviceOrProduct'] ?? '',
      servicePopularity: data['servicePopularity'] ?? 'low',
      servicePrice: (data['servicePrice'] as num?)?.toDouble() ?? 0.0,
      serviceRevenue: (data['serviceRevenue'] as num?)?.toDouble() ?? 0.0,
      serviceStatus: data['serviceStatus'] ?? 'active',
      serviceTotalBookings: (data['serviceTotalBookings'] as num?)?.toInt() ?? 0,
      serviceUpdatedAt: (data['serviceUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'service',
    );
  }

  // Convert FeedbackModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerEmail': customerEmail,
      'customerId': customerId,
      'customerName': customerName,
      'pointsAwarded': pointsAwarded,
      'rating': rating,
      'serviceBranchNames': serviceBranchNames,
      'serviceBranches': serviceBranches,
      'serviceCategory': serviceCategory,
      'serviceCategoryId': serviceCategoryId,
      'serviceCreatedAt': Timestamp.fromDate(serviceCreatedAt),
      'serviceDescription': serviceDescription,
      'serviceDuration': serviceDuration,
      'serviceId': serviceId,
      'serviceImageUrl': serviceImageUrl,
      'serviceName': serviceName,
      'serviceOrProduct': serviceOrProduct,
      'servicePopularity': servicePopularity,
      'servicePrice': servicePrice,
      'serviceRevenue': serviceRevenue,
      'serviceStatus': serviceStatus,
      'serviceTotalBookings': serviceTotalBookings,
      'serviceUpdatedAt': Timestamp.fromDate(serviceUpdatedAt),
      'status': status,
      'type': type,
    };
  }

  // Helper method to create a copy of the model with updated values
  FeedbackModel copyWith({
    String? id,
    String? comment,
    DateTime? createdAt,
    String? customerEmail,
    String? customerId,
    String? customerName,
    bool? pointsAwarded,
    int? rating,
    List<String>? serviceBranchNames,
    List<String>? serviceBranches,
    String? serviceCategory,
    String? serviceCategoryId,
    DateTime? serviceCreatedAt,
    String? serviceDescription,
    int? serviceDuration,
    String? serviceId,
    String? serviceImageUrl,
    String? serviceName,
    String? serviceOrProduct,
    String? servicePopularity,
    double? servicePrice,
    double? serviceRevenue,
    String? serviceStatus,
    int? serviceTotalBookings,
    DateTime? serviceUpdatedAt,
    String? status,
    String? type,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      customerEmail: customerEmail ?? this.customerEmail,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      rating: rating ?? this.rating,
      serviceBranchNames: serviceBranchNames ?? this.serviceBranchNames,
      serviceBranches: serviceBranches ?? this.serviceBranches,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
      serviceCreatedAt: serviceCreatedAt ?? this.serviceCreatedAt,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      serviceId: serviceId ?? this.serviceId,
      serviceImageUrl: serviceImageUrl ?? this.serviceImageUrl,
      serviceName: serviceName ?? this.serviceName,
      serviceOrProduct: serviceOrProduct ?? this.serviceOrProduct,
      servicePopularity: servicePopularity ?? this.servicePopularity,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceRevenue: serviceRevenue ?? this.serviceRevenue,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      serviceTotalBookings: serviceTotalBookings ?? this.serviceTotalBookings,
      serviceUpdatedAt: serviceUpdatedAt ?? this.serviceUpdatedAt,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get isService => type == 'service';
  bool get isProduct => type == 'product';

  double get getRating => rating.toDouble();

  bool get hasPointsAwarded => pointsAwarded;

  // Get star rating for display
  List<bool> get starRating {
    return List.generate(5, (index) => index < rating);
  }

  // Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get formatted time
  String get formattedTime {
    return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted date and time
  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  // Get first branch name
  String get firstBranchName {
    return serviceBranchNames.isNotEmpty ? serviceBranchNames.first : 'No Branch';
  }
}