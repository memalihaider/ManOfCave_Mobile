import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/controlers/auth_controller.dart';
import '../models/staff.dart';
import '../utils/safe_firestore.dart';

class StaffController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController=Get.find<AuthController>();

  // Reactive state
  final RxList<Staff> _allStaff = <Staff>[].obs;
  final RxList<Staff> _activeStaff = <Staff>[].obs;
  final Rx<Staff?> selectedStaff = Rx<Staff?>(null);
  final RxBool assignAnyStaff = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<String> _staffRoles=<String>[].obs;
  final RxList<Map<String,String>> _filters=<Map<String,String>>[].obs;

  // Getters
  List<Staff> get allStaff => _allStaff;
  List<Staff> get activeStaff => _activeStaff;
  List<Staff> get availableStaff => _activeStaff.where((staff) => staff.isActive).toList();
  List<String> get staffRoles => _staffRoles;
  List<Map<String,String>> get filters => _filters;


  @override
  void onInit() {
    super.onInit();
    // Loaded when booking / admin staff screens open.
  }

  Future<void> ensureLoaded() async {
    if (_allStaff.isNotEmpty || isLoading.value) return;
    await loadStaff();
  }

  Future<void> getStaffRoles() async {
    try {
      final Set<String> uniqueRoles = {};
      final bool isSuperAdmin = authController.isSuperAdmin;
      final bool isBranchAdmin = authController.isBranchAdmin;
      final String? userBranch = authController.currentUser.value?.branchName;

      List<Staff> staffToFilter;

      if (isSuperAdmin) {
        // Super Admin sees all staff roles from all branches
        staffToFilter = _allStaff;
      } else if (isBranchAdmin) {
        // Branch Admin only sees staff roles from their branch
        if (userBranch != null) {
          staffToFilter = getStaffByBranch(userBranch);
        } else {
          staffToFilter = [];
        }
      } else {
        // For other roles (customers, etc.) show only active staff from all branches
        staffToFilter = _allStaff.where((staff) => staff.isActive).toList();
      }

      // Collect unique roles from filtered staff
      for (var staff in staffToFilter) {
        if (staff.role.isNotEmpty) {
          uniqueRoles.add(staff.role);
        }
        // Also add staffType if it's different from role
        if (staff.staffType.isNotEmpty && staff.staffType != staff.role) {
          uniqueRoles.add(staff.staffType);
        }
      }

      print("Unique Staff Roles: $uniqueRoles");
      _staffRoles.assignAll(uniqueRoles.toList()..sort());
      print('✅ Found ${_staffRoles.length} staff roles: $_staffRoles');

      // Build filters list
      final List<Map<String, String>> filtersList = [
        {'value': 'all', 'label': 'All'},
        {'value': 'active', 'label': 'Active'},
      ];

      // Add role filters
      for (var role in uniqueRoles) {
        final valueRole = role.toLowerCase();
        final displayLabel = role[0].toUpperCase() + role.substring(1);
        filtersList.add({
          'value': valueRole,
          'label': displayLabel
        });
      }

      _filters.assignAll(filtersList);
      print('✅ Found ${_filters.length} filters: $_filters');
    } catch (e) {
      errorMessage.value = 'Failed to load staff roles: $e';
      Get.snackbar(
        'Error',
        'Failed to load staff roles',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // In your StaffController

  void debugPrintStaffStructure() {
    print("\n========== STAFF STRUCTURE DEBUG ==========");
    print("Total staff: ${_allStaff.length}");

    for (var staff in _allStaff.take(3)) { // Show first 3 staff
      print("\nStaff: ${staff.name}");
      print("  - Fields in this staff object:");
      print("    status: ${staff.status}");
      print("    isActive: ${staff.isActive}");
      print("    role: ${staff.role}");
      print("    branch: ${staff.branch}");
    }

    // Check what values are in status field
    final statusValues = _allStaff.map((s) => s.status).toSet();
    print("\nUnique status values found: $statusValues");

    final activeCount = _allStaff.where((s) => s.status == 'active').length;
    print("Staff with status='active': $activeCount");
    print("===========================================\n");
  }

  // Load all staff from Firestore
  Future<void> loadStaff() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final query = _firestore
          .collection('staff')
          .orderBy('createdAt', descending: true)
          .limit(80);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedStaff =
            snap.docs.map((doc) => Staff.fromFirestore(doc)).toList();
        _allStaff.assignAll(loadedStaff);
        _activeStaff.value =
            loadedStaff.where((staff) => staff.isActive).toList();
        update();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      errorMessage.value = 'Failed to load staff: $e';
      print('❌ loadStaff: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get staff by ID
  Future<Staff?> getStaffById(String staffId) async {
    try {
      final doc = await _firestore
          .collection('staff')
          .doc(staffId)
          .get();

      if (doc.exists) {
        return Staff.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting staff: $e');
      return null;
    }
  }

  // // Get staff by role (e.g., 'makeup', 'barber', etc.)
  // List<Staff> getStaffByRole(String role) {
  //   return _allStaff
  //       .where((staff) => staff.role.toLowerCase() == role.toLowerCase())
  //       .toList();
  // }

  // Get staff by staff type (uses staffType getter from model)
  List<Staff> getStaffByStaffType(String staffType) {
    return _allStaff
        .where((staff) => staff.staffType.toLowerCase() == staffType.toLowerCase())
        .toList();
  }

  // Get staff by branch
  List<Staff> getStaffByBranch(String branchName) {
    return _allStaff
        .where((staff) => staff.branch.toLowerCase() == branchName.toLowerCase())
        .toList();
  }

  // Get staff by specialization
  List<Staff> getStaffBySpecialization(String specialization) {
    return _allStaff
        .where((staff) => staff.specialization.any(
            (spec) => spec.toLowerCase().contains(specialization.toLowerCase())
    ))
        .toList();
  }

  // Get top rated staff
  List<Staff> getTopRatedStaff({int limit = 5}) {
    final staffList = _allStaff
        .where((staff) => staff.isActive)
        .toList();

    staffList.sort((a, b) => b.rating.compareTo(a.rating));
    return staffList.take(limit).toList();
  }

  // Get staff with specific experience
  List<Staff> getStaffByExperience({int minYears = 0, int maxYears = 100}) {
    final staffList = _allStaff
        .where((staff) =>
    staff.isActive &&
        staff.experienceYears >= minYears &&
        staff.experienceYears <= maxYears)
        .toList();

    staffList.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    return staffList;
  }

  // Select staff for booking
  void selectStaff(Staff staff) {
    if (assignAnyStaff.value) {
      assignAnyStaff.value = false;
    }
    selectedStaff.value = staff;
    update();
  }

  // Select "Any Available Staff" option
  void selectAnyStaff() {
    selectedStaff.value = null;
    assignAnyStaff.value = true;
    update();
  }

  // Clear selection
  void clearSelection() {
    selectedStaff.value = null;
    assignAnyStaff.value = false;
    update();
  }

  // Check if staff is selected
  bool isStaffSelected(Staff staff) {
    if (assignAnyStaff.value) return false;
    return selectedStaff.value?.id == staff.id;
  }

  // Check if "Any Staff" is selected
  bool get isAnyStaffSelected => assignAnyStaff.value;

  // Get selected staff name for display
  String get selectedStaffDisplayName {
    if (assignAnyStaff.value) return 'Any Available Staff';
    return selectedStaff.value?.displayNameWithRole ?? 'Select Staff'; // Updated
  }

  // Get selected staff ID
  String? get selectedStaffId {
    if (assignAnyStaff.value) return null;
    return selectedStaff.value?.id;
  }

  // Get selected staff document ID
  String? get selectedStaffDocumentId {
    if (assignAnyStaff.value) return null;
    return selectedStaff.value?.documentId;
  }

  // Search staff by name, role, specialization, or branch
  List<Staff> searchStaff(String query) {
    if (query.isEmpty) return _allStaff;

    final searchQuery = query.toLowerCase();
    return _allStaff.where((staff) {
      return staff.name.toLowerCase().contains(searchQuery) ||
          staff.role.toLowerCase().contains(searchQuery) ||
          staff.staffType.toLowerCase().contains(searchQuery) || // Added
          staff.specialization.any((spec) => spec.toLowerCase().contains(searchQuery)) ||
          staff.branch.toLowerCase().contains(searchQuery) ||
          staff.documentId.toLowerCase().contains(searchQuery) || // Added
          staff.phone.toLowerCase().contains(searchQuery); // Added
    }).toList();
  }

  // Filter staff by multiple criteria
  List<Staff> filterStaff({
    String? role,
    String? branch,
    double? minRating,
    int? minExperience,
    bool? isActive,
    String? status,
    String? gender,
    String? nationality,
    double? minSalary,
    double? maxSalary,
  }) {
    List<Staff> filtered = _allStaff;

    if (role != null && role.isNotEmpty) {
      filtered = filtered.where((staff) => staff.role.toLowerCase() == role.toLowerCase()).toList();
    }

    if (branch != null && branch.isNotEmpty) {
      filtered = filtered.where((staff) => staff.branch.toLowerCase() == branch.toLowerCase()).toList();
    }

    if (minRating != null) {
      filtered = filtered.where((staff) => staff.rating >= minRating).toList();
    }

    if (minExperience != null) {
      filtered = filtered.where((staff) => staff.experienceYears >= minExperience).toList();
    }

    if (isActive != null) {
      filtered = filtered.where((staff) => staff.isActive == isActive).toList();
    }

    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((staff) => staff.status.toLowerCase() == status.toLowerCase()).toList();
    }

    if (gender != null && gender.isNotEmpty) {
      filtered = filtered.where((staff) => staff.gender.toLowerCase() == gender.toLowerCase()).toList();
    }

    if (nationality != null && nationality.isNotEmpty) {
      filtered = filtered.where((staff) => staff.nationality.toLowerCase().contains(nationality.toLowerCase())).toList();
    }

    if (minSalary != null) {
      filtered = filtered.where((staff) => staff.salary >= minSalary).toList();
    }

    if (maxSalary != null) {
      filtered = filtered.where((staff) => staff.salary <= maxSalary).toList();
    }

    return filtered;
  }

  // Check staff availability using model's method
  Future<bool> checkStaffAvailability({
    required String staffId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      final staff = await getStaffById(staffId);
      if (staff == null) return false;

      // Use the model's availability method
      return staff.isAvailableForBooking(date: date, timeSlot: timeSlot);
    } catch (e) {
      print('Error checking staff availability: $e');
      return false;
    }
  }

  // Check visa expiry status for staff
  List<Staff> getStaffWithExpiringVisa({int daysThreshold = 30}) {
    final staffList = _allStaff.where((staff) {
      if (!staff.hasVisaExpiry) return false;
      final daysLeft = staff.daysUntilVisaExpiry;
      return daysLeft != null && daysLeft > 0 && daysLeft <= daysThreshold;
    }).toList();

    staffList.sort((a, b) {
      final daysA = a.daysUntilVisaExpiry ?? 9999;
      final daysB = b.daysUntilVisaExpiry ?? 9999;
      return daysA.compareTo(daysB);
    });

    return staffList;
  }

  // Update staff status (activate/deactivate)
  Future<bool> updateStaffStatus(String staffId, bool isActive) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('staff')
          .doc(staffId)
          .update({
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': Timestamp.now(),
      });

      // Refresh staff list
      await loadStaff();

      Get.snackbar(
        'Success',
        'Staff status updated',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update staff status: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update staff profile
  Future<bool> updateStaff(Staff updatedStaff) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('staff')
          .doc(updatedStaff.id)
          .update(updatedStaff.toFirestore());

      // Refresh staff list
      await loadStaff();

      Get.snackbar(
        'Success',
        'Staff profile updated',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update staff: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add new staff with all model fields
  Future<bool> addStaff({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String branch,
    required String address,
    required String dateOfBirth,
    required String gender,
    required String hireDate,
    required String nationality,
    required double salary,
    List<String> specialization = const [],
    String? avatar,
    String? bloodGroup,
    String? description,
    String? emergencyContact,
    String? maritalStatus,
    String? visaExpiry,
    String? documentId, // Optional custom document ID
    String experience = '0',
    String status = 'active',
  }) async {
    try {
      isLoading.value = true;

      final now = Timestamp.now();
      final staffData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'branch': branch,
        'status': status,
        'createdAt': now,
        'updatedAt': now,

        // Personal details
        'address': address,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'hireDate': hireDate,
        'nationality': nationality,
        'experience': experience,
        'documentId': documentId ?? '', // Will be populated by fromFirestore

        // Professional details
        'rating': 0.0,
        'reviews': 0,
        'salary': salary,
        'specialization': specialization,

        // Optional fields
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
        if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
        if (description != null && description.isNotEmpty) 'description': description,
        if (emergencyContact != null && emergencyContact.isNotEmpty) 'emergencyContact': emergencyContact,
        if (maritalStatus != null && maritalStatus.isNotEmpty) 'maritalStatus': maritalStatus,
        if (visaExpiry != null && visaExpiry.isNotEmpty) 'visaExpiry': visaExpiry,
      };

      final docRef = await _firestore
          .collection('staff')
          .add(staffData);

      // Update with document ID if not provided
      if (documentId == null) {
        await docRef.update({
          'documentId': docRef.id,
        });
      }

      // Refresh staff list
      await loadStaff();

      Get.snackbar(
        'Success',
        'Staff added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add staff: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update staff rating (after service/review)
  Future<void> updateStaffRating(String staffId, double newRating) async {
    try {
      final staff = await getStaffById(staffId);
      if (staff == null) return;

      // Calculate new average rating
      final totalRating = (staff.rating * staff.reviews) + newRating;
      final newReviews = staff.reviews + 1;
      final newAverageRating = totalRating / newReviews;

      await _firestore
          .collection('staff')
          .doc(staffId)
          .update({
        'rating': newAverageRating,
        'reviews': newReviews,
        'updatedAt': Timestamp.now(),
      });

      // Refresh staff list
      await loadStaff();
    } catch (e) {
      print('Error updating staff rating: $e');
    }
  }

  // Get staff statistics with enhanced data
  Map<String, dynamic> getStaffStatistics() {
    final totalStaff = _allStaff.length;
    final activeStaffCount = _allStaff.where((s) => s.isActive).length;

    final averageRating = _allStaff.isEmpty ? 0 :
    _allStaff.map((s) => s.rating).reduce((a, b) => a + b) / totalStaff;

    final averageExperience = _allStaff.isEmpty ? 0 :
    _allStaff.map((s) => s.experienceYears).reduce((a, b) => a + b) / totalStaff;

    final totalSalary = _allStaff.isEmpty ? 0 :
    _allStaff.map((s) => s.salary).reduce((a, b) => a + b);
    final averageSalary = _allStaff.isEmpty ? 0 : totalSalary / totalStaff;

    // Group by role
    final roleCounts = <String, int>{};
    // Group by staff type
    final staffTypeCounts = <String, int>{};
    // Group by branch
    final branchCounts = <String, int>{};
    // Group by status
    final statusCounts = <String, int>{};
    // Group by nationality
    final nationalityCounts = <String, int>{};

    for (final staff in _allStaff) {
      roleCounts[staff.role] = (roleCounts[staff.role] ?? 0) + 1;
      staffTypeCounts[staff.staffType] = (staffTypeCounts[staff.staffType] ?? 0) + 1;
      branchCounts[staff.branch] = (branchCounts[staff.branch] ?? 0) + 1;
      statusCounts[staff.status] = (statusCounts[staff.status] ?? 0) + 1;
      nationalityCounts[staff.nationality] = (nationalityCounts[staff.nationality] ?? 0) + 1;
    }

    // Get visa statistics
    final staffWithVisa = _allStaff.where((s) => s.hasVisaExpiry).length;
    final expiredVisa = _allStaff.where((s) => s.isVisaExpired).length;
    final expiringVisa = _allStaff.where((s) {
      final daysLeft = s.daysUntilVisaExpiry;
      return daysLeft != null && daysLeft > 0 && daysLeft <= 30;
    }).length;

    return {
      'totalStaff': totalStaff,
      'activeStaff': activeStaffCount,
      'inactiveStaff': totalStaff - activeStaffCount,
      'averageRating': double.parse(averageRating.toStringAsFixed(1)),
      'averageExperience': averageExperience.round(),
      'averageSalary': averageSalary,
      'totalSalary': totalSalary,

      'roleDistribution': roleCounts,
      'staffTypeDistribution': staffTypeCounts,
      'branchDistribution': branchCounts,
      'statusDistribution': statusCounts,
      'nationalityDistribution': nationalityCounts,

      'visaStatistics': {
        'withVisa': staffWithVisa,
        'withoutVisa': totalStaff - staffWithVisa,
        'expired': expiredVisa,
        'expiringSoon': expiringVisa,
      },

      'genderDistribution': {
        'male': _allStaff.where((s) => s.gender.toLowerCase() == 'male').length,
        'female': _allStaff.where((s) => s.gender.toLowerCase() == 'female').length,
        'other': _allStaff.where((s) => !['male', 'female'].contains(s.gender.toLowerCase())).length,
      }
    };
  }

  // Get staff summary for quick views
  List<Map<String, dynamic>> getStaffSummaries() {
    return _allStaff.map((staff) => staff.summary).toList();
  }

  // Get staff by specific type checks
  List<Staff> getMakeupArtists() {
    return _allStaff.where((staff) => staff.isMakeupArtist && staff.isActive).toList();
  }

  List<Staff> getBarbers() {
    return _allStaff.where((staff) => staff.isBarber && staff.isActive).toList();
  }

  List<Staff> getHairStylists() {
    return _allStaff.where((staff) => staff.isHairStylist && staff.isActive).toList();
  }

  // Refresh staff data
  Future<void> refreshStaff() async {
    await loadStaff();
  }

  // Delete staff
  Future<bool> deleteStaff(String staffId) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('staff')
          .doc(staffId)
          .delete();

      // Refresh staff list
      await loadStaff();

      Get.snackbar(
        'Success',
        'Staff deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete staff: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sort staff by various criteria
  List<Staff> sortStaff({
    required List<Staff> staffList,
    String sortBy = 'name',
    bool ascending = true,
  }) {
    final sortedList = List<Staff>.from(staffList);

    switch (sortBy) {
      case 'name':
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        sortedList.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'experience':
        sortedList.sort((a, b) => a.experienceYears.compareTo(b.experienceYears));
        break;
      case 'salary':
        sortedList.sort((a, b) => a.salary.compareTo(b.salary));
        break;
      case 'hireDate':
        sortedList.sort((a, b) => a.hireDate.compareTo(b.hireDate));
        break;
      case 'createdAt':
        sortedList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    if (!ascending) {
      sortedList.reversed.toList();
    }

    return sortedList;
  }

  // // Get staff by multiple roles
  // List<Staff> getStaffByRoles(List<String> roles) {
  //   return _allStaff
  //       .where((staff) => roles.contains(staff.role.toLowerCase()))
  //       .toList();
  // }

  // Get staff with high rating
  List<Staff> getHighRatedStaff({double minRating = 4.0}) {
    return _allStaff
        .where((staff) => staff.rating >= minRating && staff.isActive)
        .toList();
  }

  // Check if staff exists by email
  Future<bool> staffExistsByEmail(String email) async {
    final query = await _firestore
        .collection('staff')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Check if staff exists by phone
  Future<bool> staffExistsByPhone(String phone) async {
    final query = await _firestore
        .collection('staff')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}