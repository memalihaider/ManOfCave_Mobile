import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'customer', etc.
  final String status; // 'active', 'inactive'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool emailVerified; // New field for email verification status

  // Optional fields based on role
  final String? phone;
  final String? dateOfBirth;
  final String? branchId;
  final String? branchName;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.phone,
    this.dateOfBirth,
    this.branchId,
    this.branchName,
    this.emailVerified = false, // Default to false
  });

  factory UserModel.fromLocalStorage(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'customer',
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : null,
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'],
      branchId: data['branchId'],
      branchName: data['branchName'],
      emailVerified: data['emailVerified'] ?? false, // Read from storage
    );
  }

  // Convert User to Map for Local Storage
  Map<String, dynamic> toLocalStorage() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'branchId': branchId,
      'branchName': branchName,
      'emailVerified': emailVerified, // Save to storage
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'customer',
      status: data['status'] ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'],
      branchId: data['branchId'],
      branchName: data['branchName'],
      emailVerified: data['emailVerified'] ?? false, // Read from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (branchId != null) 'branchId': branchId,
      if (branchName != null) 'branchName': branchName,
      'emailVerified': emailVerified, // Save to Firestore
    };
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  // Helper methods based on role
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isBranchAdmin => role == 'admin' || role == 'branch_admin';
  bool get isCustomer => role == 'customer';
  bool get isStaff => role == 'staff';
  bool get isActive => status == 'active';

  // Helper for email verification
  bool get isEmailVerified => emailVerified;

  // Helper to check if user can access app features
  bool get canAccessApp {
    // Super admins and branch admins can always access
    if (isSuperAdmin || isBranchAdmin) return true;

    // Customers need email verified to access full features
    return isCustomer ? emailVerified : true;
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phone,
    String? dateOfBirth,
    String? branchId,
    String? branchName,
    bool? emailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  // Method to get user display info
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  // Method to get user initials for avatar
  String get initials {
    if (name.isNotEmpty) {
      final nameParts = name.trim().split(' ');
      if (nameParts.length > 1) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }
    return email[0].toUpperCase();
  }

  // Method to check if user has complete profile
  bool get hasCompleteProfile {
    return name.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        dateOfBirth != null &&
        dateOfBirth!.isNotEmpty;
  }

  // Method to get role display name
  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
      case 'branch_admin':
        return 'Branch Admin';
      case 'staff':
        return 'Staff';
      case 'customer':
        return 'Customer';
      default:
        return role;
    }
  }

  // Method to check if user belongs to a branch
  bool get hasBranch => branchId != null && branchId!.isNotEmpty;

  // Method to get branch display info
  String get branchDisplayName => branchName ?? 'No Branch';

  // Method to check if user needs to verify email
  bool get needsEmailVerification => isCustomer && !emailVerified;

  // Method to check if user can perform admin actions
  bool get canPerformAdminActions => isSuperAdmin || isBranchAdmin;

  // Method to check if user can manage services
  bool get canManageServices => isSuperAdmin || isBranchAdmin;

  // Method to check if user can manage products
  bool get canManageProducts => isSuperAdmin || isBranchAdmin;

  // Method to check if user can view all data
  bool get canViewAllData => isSuperAdmin;
}