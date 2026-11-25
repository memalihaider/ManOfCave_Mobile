import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'service' or 'product'
  final String description;
  final String image;
  final bool isActive;

  // Branch support - can be single branch or multiple branches
  final String? branchId; // For single branch
  final String? branchName; // For single branch
  final String? branchCity; // For single branch
  final List<String> branchIds; // For multiple branches
  final List<String> branchNames; // For multiple branches
  final List<String> branchCities; // For multiple branches

  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.image,
    required this.isActive,
    this.branchId,
    this.branchName,
    this.branchCity,
    this.branchIds = const [],
    this.branchNames = const [],
    this.branchCities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create Category from Firestore Document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse branch fields - support both old and new structure
    final branchId = data['branchId'] as String?;
    final branchName = data['branchName'] as String?;
    final branchCity = data['branchCity'] as String?;
    final branchIds = List<String>.from(data['branchIds'] ?? []);
    final branchNames = List<String>.from(data['branchNames'] ?? []);
    final branchCities = List<String>.from(data['branchCities'] ?? []);

    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'service',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      isActive: data['isActive'] ?? true,
      branchId: branchId,
      branchName: branchName,
      branchCity: branchCity,
      branchIds: branchIds,
      branchNames: branchNames,
      branchCities: branchCities,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Category to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final data = {
      'name': name,
      'type': type,
      'description': description,
      'image': image,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    // Add branch fields if they exist
    if (branchId != null && branchId!.isNotEmpty) {
      data['branchId'] = branchId.toString();
    }
    if (branchName != null && branchName!.isNotEmpty) {
      data['branchName'] = branchName.toString();
    }
    if (branchCity != null && branchCity!.isNotEmpty) {
      data['branchCity'] = branchCity.toString();
    }
    if (branchIds.isNotEmpty) {
      data['branchIds'] = branchIds;
    }
    if (branchNames.isNotEmpty) {
      data['branchNames'] = branchNames;
    }
    if (branchCities.isNotEmpty) {
      data['branchCities'] = branchCities;
    }

    return data;
  }

  // Helper methods
  bool get isServiceCategory => type == 'service';
  bool get isProductCategory => type == 'product';

  // Check if category is available at a specific branch
  bool isAvailableAtBranch(String branchIdToCheck) {
    // Check multiple branches first
    if (branchIds.contains(branchIdToCheck)) return true;
    // Check single branch
    if (branchId == branchIdToCheck) return true;
    return false;
  }

  // Check if category is available at any branch
  bool get isAvailableAnywhere =>
      branchIds.isNotEmpty ||
          (branchId != null && branchId!.isNotEmpty);

  // Get all branch IDs where category is available
  List<String> get allBranchIds {
    final ids = <String>{};
    if (branchId != null && branchId!.isNotEmpty) {
      ids.add(branchId!);
    }
    ids.addAll(branchIds);
    return ids.toList();
  }

  // Get all branch names where category is available
  List<String> get allBranchNames {
    final names = <String>{};
    if (branchName != null && branchName!.isNotEmpty) {
      names.add(branchName!);
    }
    names.addAll(branchNames);
    return names.toList();
  }

  // Get branches count
  int get branchesCount => allBranchIds.length;

  // Get display branches string
  String get branchesDisplay {
    final names = allBranchNames;
    if (names.isEmpty) return 'No branches';
    if (names.length == 1) return names.first;
    return '${names.length} branches';
  }

  // Check if category is available at all branches
  bool get isAvailableAtAllBranches => branchesCount > 3;

  // Get primary branch name (first available)
  String get primaryBranchName {
    if (allBranchNames.isNotEmpty) return allBranchNames.first;
    return 'All Branches';
  }

  // Copy with method for updates
  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? image,
    bool? isActive,
    String? branchId,
    String? branchName,
    String? branchCity,
    List<String>? branchIds,
    List<String>? branchNames,
    List<String>? branchCities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchCity: branchCity ?? this.branchCity,
      branchIds: branchIds ?? this.branchIds,
      branchNames: branchNames ?? this.branchNames,
      branchCities: branchCities ?? this.branchCities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}