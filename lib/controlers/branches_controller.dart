import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/branch_model.dart';
import '../utils/safe_firestore.dart';

class BranchController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive lists
  var branches = <Branch>[].obs;
  var filteredBranches = <Branch>[].obs;
  var isLoading = false.obs;
  final RxString selectedBranchId = ''.obs;
  final Rx<Branch?> selectedBranch = Rx<Branch?>(null);

  // Filter states
  var selectedCity = 'All'.obs;
  var selectedStatus = 'All'.obs;
  var searchQuery = ''.obs;

  // Weekly timing helper
  final Map<String, String> _dayNameMap = {
    '1': 'monday',
    '2': 'tuesday',
    '3': 'wednesday',
    '4': 'thursday',
    '5': 'friday',
    '6': 'saturday',
    '7': 'sunday',
  };

  @override
  void onInit() {
    super.onInit();
    // Loaded by Home / location screens when needed.
  }

  void selectBranch(Branch branch) {
    selectedBranchId.value = branch.id;
    selectedBranch.value = branch;
    update();
  }

  void changeBranch(String branchName) {
    try {
      // Find branch by name (case-insensitive) - manual implementation
      Branch? foundBranch;
      for (var branch in branches) {
        if (branch.name.toLowerCase() == branchName.toLowerCase()) {
          foundBranch = branch;
          break;
        }
      }

      if (foundBranch != null) {
        selectBranch(foundBranch);
      } else {
        print('Branch "$branchName" not found');
      }
    } catch (e) {
      print('Error selecting branch: $e');
    }
  }

  // Clear selected branch
  void clearSelectedBranch() {
    selectedBranchId.value = '';
    selectedBranch.value = null;
    update();
  }

  // Check if a branch is selected
  bool isBranchSelected(Branch branch) {
    return selectedBranchId.value == branch.id;
  }

  // Helper to find branch by ID (manual)
  Branch? _findBranchById(String branchId) {
    for (var branch in branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }

  // Load all branches
  Future<void> loadBranches() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;

      final query = _firestore
          .collection('branches')
          .orderBy('createdAt', descending: true)
          .limit(40);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedBranches =
            snap.docs.map((doc) => Branch.fromFirestore(doc)).toList();
        branches.assignAll(loadedBranches);
        filteredBranches.assignAll(loadedBranches);
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      print('❌ loadBranches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get branch by ID
  Future<Branch?> getBranchById(String branchId) async {
    try {
      final doc = await _firestore
          .collection('branches')
          .doc(branchId)
          .get();

      if (doc.exists) {
        return Branch.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting branch: $e');
      return null;
    }
  }

  // Add new branch
  Future<bool> addBranch(Branch branch) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('branches')
          .add(branch.toFirestore());

      await loadBranches();
      filterBranches();

      Get.snackbar(
        'Success',
        'Branch added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add branch: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update branch
  Future<bool> updateBranch(String branchId, Branch updatedBranch) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('branches')
          .doc(branchId)
          .update(updatedBranch.toFirestore());

      await loadBranches();
      filterBranches();

      Get.snackbar(
        'Success',
        'Branch updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update branch: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete branch
  Future<bool> deleteBranch(String branchId) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('branches')
          .doc(branchId)
          .delete();

      await loadBranches();
      filterBranches();

      Get.snackbar(
        'Success',
        'Branch deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete branch: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Filter branches
  void filterBranches() {
    List<Branch> filtered = List.from(branches);

    if (selectedCity.value != 'All') {
      filtered = filtered.where((branch) => branch.city == selectedCity.value).toList();
    }

    if (selectedStatus.value != 'All') {
      filtered = filtered.where((branch) => branch.status == selectedStatus.value).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((branch) =>
      branch.name.toLowerCase().contains(query) ||
          branch.address.toLowerCase().contains(query) ||
          branch.city.toLowerCase().contains(query) ||
          branch.country.toLowerCase().contains(query) ||
          (branch.managerName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    filteredBranches.assignAll(filtered);
  }

  // Reset filters
  void resetFilters() {
    selectedCity.value = 'All';
    selectedStatus.value = 'All';
    searchQuery.value = '';
    filteredBranches.assignAll(branches);
  }

  // Update filters
  void updateFilters({
    String? city,
    String? status,
    String? query,
  }) {
    if (city != null) selectedCity.value = city;
    if (status != null) selectedStatus.value = status;
    if (query != null) searchQuery.value = query;
    filterBranches();
  }

  // Get all unique cities
  List<String> get allCities {
    final cities = branches.map((branch) => branch.city).toSet().toList();
    cities.sort();
    return ['All', ...cities];
  }

  // Get all unique statuses
  List<String> get allStatuses {
    final statuses = branches.map((branch) => branch.status).toSet().toList();
    statuses.sort();
    return ['All', ...statuses];
  }

  // Get active branches
  List<Branch> get activeBranches {
    return branches.where((branch) => branch.isActive).toList();
  }

  // Get open branches now (using weekly timings)
  List<Branch> get openNowBranches {
    return branches.where((branch) => branch.isOpenNow()).toList();
  }

  // Get branches by city
  List<Branch> getBranchesByCity(String city) {
    return branches.where((branch) => branch.city == city).toList();
  }

  // Refresh branches
  Future<void> refreshBranches() async {
    await loadBranches();
  }

  // Get branch display name
  String getBranchDisplayName(Branch branch) {
    if (branch.managerName != null && branch.managerName!.isNotEmpty) {
      return '${branch.managerName} - ${branch.name}';
    }
    return branch.name;
  }

  // Get contact information string
  String getBranchContactInfo(Branch branch) {
    final contacts = [];
    if (branch.phone.isNotEmpty) contacts.add('Tel: ${branch.phone}');
    if (branch.email.isNotEmpty) contacts.add('Email: ${branch.email}');
    if (branch.managerPhone != null && branch.managerPhone!.isNotEmpty) {
      contacts.add('Manager: ${branch.managerPhone}');
    }
    return contacts.join(' • ');
  }

  // ========== WEEKLY TIMING FUNCTIONS ==========

  // Helper to get day name from weekday number
  String _getDayName(int weekday) {
    return _dayNameMap[weekday] ?? 'monday';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  // Check if branch is open on a specific date and time
  bool isBranchOpenOnDateTime(String branchId, DateTime dateTime) {
    final branch = _findBranchById(branchId);
    if (branch == null) return false;
    return branch.isOpenOn(dateTime);
  }

  // Check if branch is open on a specific day of week
  bool isBranchOpenOnDay(String branchId, int weekday) {
    final branch = _findBranchById(branchId);
    if (branch == null) return false;

    final dayName = _getDayName(weekday);
    final timing = branch.weeklyTimings[dayName];
    if (timing == null) return false;
    return !timing.closed;
  }

  // Get branch timing for a specific day
  String getBranchTimingForDay(String branchId, int weekday) {
    final branch = _findBranchById(branchId);
    if (branch == null) return 'Closed';

    final dayName = _getDayName(weekday);
    return branch.getBusinessHoursForDay(dayName);
  }

  // Get all available time slots for a branch on a specific date
  List<String> getAvailableTimeSlots({
    required String branchId,
    required DateTime date,
    int slotDurationMinutes = 30,
  }) {
    final branch = _findBranchById(branchId);
    if (branch == null) return [];

    final dayName = _getDayName(date.weekday);
    final timing = branch.weeklyTimings[dayName];

    if (timing == null || timing.closed) return [];

    // Parse opening and closing times
    final openingParts = timing.opening.split(':').map(int.parse).toList();
    final closingParts = timing.closing.split(':').map(int.parse).toList();

    final openingTime = DateTime(
      date.year, date.month, date.day,
      openingParts[0], openingParts[1],
    );
    final closingTime = DateTime(
      date.year, date.month, date.day,
      closingParts[0], closingParts[1],
    );

    // Generate time slots
    final List<String> slots = [];
    var currentSlot = openingTime;

    while (currentSlot.isBefore(closingTime)) {
      final hour = currentSlot.hour;
      final minute = currentSlot.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      slots.add('${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period');

      currentSlot = currentSlot.add(Duration(minutes: slotDurationMinutes));
    }

    return slots;
  }

  // Get branch's weekly schedule as formatted string
  Map<String, String> getBranchWeeklySchedule(String branchId) {
    final branch = _findBranchById(branchId);
    if (branch == null) return {};
    return branch.weeklySchedule;
  }

  // Get all branches that are open on a specific date
  List<Branch> getBranchesOpenOnDate(DateTime date) {
    return branches.where((branch) => branch.isOpenOn(date)).toList();
  }

  // Get all branches that are open on a specific day of week
  List<Branch> getBranchesOpenOnDay(int weekday) {
    final dayName = _getDayName(weekday);
    return branches.where((branch) {
      final timing = branch.weeklyTimings[dayName];
      return timing != null && !timing.closed;
    }).toList();
  }

  // Get next available date for a branch (if closed today)
  DateTime? getNextAvailableDate(String branchId, {DateTime? startFrom}) {
    final branch = _findBranchById(branchId);
    if (branch == null) return null;

    var checkDate = (startFrom ?? DateTime.now()).add(const Duration(days: 1));

    // Check next 30 days
    for (int i = 0; i < 30; i++) {
      final dayName = _getDayName(checkDate.weekday);
      final timing = branch.weeklyTimings[dayName];

      if (timing != null && !timing.closed) {
        return checkDate;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return null;
  }

  // Get branch timing status message
  String getBranchTimingStatus(String branchId) {
    final branch = _findBranchById(branchId);
    if (branch == null) return 'Branch not found';

    if (!branch.isActive) return 'Branch is currently inactive';

    if (branch.isOpenNow()) {
      final closingTime = branch.getBusinessHoursForDay(_getDayName(DateTime.now().weekday)).split(' - ')[1];
      return 'Open now • Closes at $closingTime';
    } else {
      final nextDate = getNextAvailableDate(branchId);
      if (nextDate != null) {
        final dayName = _getDayName(nextDate.weekday);
        final timing = branch.getBusinessHoursForDay(dayName);
        return 'Closed now • Next open: ${_formatDate(nextDate)} ($timing)';
      }
      return 'Closed now';
    }
  }

  // Get today's timing for a branch
  String getTodayTiming(String branchId) {
    return getBranchTimingForDay(branchId, DateTime.now().weekday);
  }

  // Check if branch is currently open
  bool isBranchOpenNow(String branchId) {
    final branch = _findBranchById(branchId);
    if (branch == null) return false;
    return branch.isOpenNow();
  }
}