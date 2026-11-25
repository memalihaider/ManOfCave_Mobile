// models/loyalty_config_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyConfig {
  final String id;
  final String name;
  final String description;
  final int pointsPerDollar; // 5 points per $1
  final double redemptionRate; // 0.03 (3% value)
  final int minimumPoints; // 100 points minimum for redemption
  final int expiryDays; // 365 days
  final List<String> branches; // Contains document IDs like "tzE78GugjeTAkFXdztle"
  final List<String> branchNames; // Contains names like "first branch"
  final String status; // 'active', 'inactive'
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsPerDollar,
    required this.redemptionRate,
    required this.minimumPoints,
    required this.expiryDays,
    required this.branches,
    required this.branchNames,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create from Firestore Document
  factory LoyaltyConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert arrays properly
    final branches = data['branches'] != null
        ? List<String>.from(data['branches'])
        : <String>[];

    final branchNames = data['branchNames'] != null
        ? List<String>.from(data['branchNames'])
        : <String>[];

    return LoyaltyConfig(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      pointsPerDollar: (data['pointsPerDollar'] as num?)?.toInt() ?? 5,
      redemptionRate: (data['redemptionRate'] as num?)?.toDouble() ?? 0.03,
      minimumPoints: (data['minimumPoints'] as num?)?.toInt() ?? 100,
      expiryDays: (data['expiryDays'] as num?)?.toInt() ?? 365,
      branches: branches,
      branchNames: branchNames,
      status: data['status']?.toString() ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'pointsPerDollar': pointsPerDollar,
      'redemptionRate': redemptionRate,
      'minimumPoints': minimumPoints,
      'expiryDays': expiryDays,
      'branches': branches,
      'branchNames': branchNames,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Check if config is active
  bool get isActive => status == 'active';

  // Calculate points for amount
  int calculatePoints(double amount) {
    return (amount * pointsPerDollar).floor();
  }

  // Calculate monetary value of points
  double calculateValue(int points) {
    return points * redemptionRate;
  }

  // Get formatted points required for minimum redemption
  String get formattedMinimumPoints => '$minimumPoints points';

  // Get formatted value of minimum points
  String get formattedMinimumValue {
    final value = calculateValue(minimumPoints);
    return 'AED ${value.toStringAsFixed(2)}';
  }

  // Get expiry duration text
  String get expiryText {
    if (expiryDays >= 365) {
      final years = expiryDays ~/ 365;
      return years == 1 ? '1 year' : '$years years';
    } else if (expiryDays >= 30) {
      final months = expiryDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '$expiryDays days';
    }
  }

  // Check if branch is included by ID
  bool includesBranchById(String branchId) {
    return branches.isEmpty || branches.contains(branchId);
  }

  // Check if branch is included by name
  bool includesBranchByName(String branchName) {
    return branchNames.isEmpty || branchNames.contains(branchName);
  }

  // Get redemption value for points
  String getRedemptionValue(int points) {
    final value = calculateValue(points);
    return 'AED ${value.toStringAsFixed(2)}';
  }

  // Get branch info for a specific branch ID
  String? getBranchName(String branchId) {
    final index = branches.indexOf(branchId);
    return index >= 0 && index < branchNames.length ? branchNames[index] : null;
  }

  // Get branch ID for a specific branch name
  String? getBranchId(String branchName) {
    final index = branchNames.indexOf(branchName);
    return index >= 0 && index < branches.length ? branches[index] : null;
  }

  // Get all branch info as a list of maps
  List<Map<String, String>> get branchInfo {
    final List<Map<String, String>> info = [];
    for (int i = 0; i < branches.length; i++) {
      if (i < branchNames.length) {
        info.add({
          'id': branches[i],
          'name': branchNames[i],
        });
      }
    }
    return info;
  }

  // Check if config is valid
  bool get isValid {
    return name.isNotEmpty &&
        pointsPerDollar > 0 &&
        redemptionRate > 0 &&
        minimumPoints > 0 &&
        expiryDays > 0 &&
        status.isNotEmpty;
  }

  // Copy with method for updates
  LoyaltyConfig copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsPerDollar,
    double? redemptionRate,
    int? minimumPoints,
    int? expiryDays,
    List<String>? branches,
    List<String>? branchNames,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoyaltyConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsPerDollar: pointsPerDollar ?? this.pointsPerDollar,
      redemptionRate: redemptionRate ?? this.redemptionRate,
      minimumPoints: minimumPoints ?? this.minimumPoints,
      expiryDays: expiryDays ?? this.expiryDays,
      branches: branches ?? this.branches,
      branchNames: branchNames ?? this.branchNames,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LoyaltyConfig(id: $id, name: $name, pointsPerDollar: $pointsPerDollar, '
        'redemptionRate: $redemptionRate, minimumPoints: $minimumPoints, '
        'expiryDays: $expiryDays, status: $status, branches: ${branches.length}, '
        'branchNames: ${branchNames.length})';
  }
}