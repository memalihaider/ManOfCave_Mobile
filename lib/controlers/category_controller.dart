import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';
import '../utils/safe_firestore.dart';
import 'auth_controller.dart';

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  final RxList<CategoryModel> _serviceCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> _productCategories = <CategoryModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Filter states
  final RxString _selectedType = 'All'.obs;
  final RxString _selectedBranch = 'All'.obs;
  final RxString _selectedCity = 'All'.obs;
  final RxString _searchQuery = ''.obs;

  // Role-based getters
  bool get isSuperAdmin => _authController.isSuperAdmin;
  bool get isBranchAdmin => _authController.isBranchAdmin;
  bool get isCustomer => _authController.isCustomer;
  String? get userBranchId => _authController.getUserBranchId();
  String? get userBranchName => _authController.getUserBranchName();

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get serviceCategories => _serviceCategories;
  List<CategoryModel> get productCategories => _productCategories;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get selectedType => _selectedType.value;
  String get selectedBranch => _selectedBranch.value;
  String get selectedCity => _selectedCity.value;
  String get searchQuery => _searchQuery.value;

  // NEW: Home Screen specific - only categories with images
  List<CategoryModel> get categoriesWithImages => _categories
      .where((c) => c.isActive && c.image.isNotEmpty)
      .toList();

  // NEW: Sorted categories - images first, then others
  List<CategoryModel> get sortedCategories {
    final withImages = _categories.where((c) => c.isActive && c.image.isNotEmpty).toList();
    final withoutImages = _categories.where((c) => c.isActive && c.image.isEmpty).toList();
    return [...withImages, ...withoutImages];
  }

  @override
  void onInit() {
    super.onInit();
    // Loaded by Home / category screens when needed.
  }

  // Load all categories from Firestore with role-based filtering
  Future<void> loadCategories() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final query = _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .limit(60);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedCategories =
            snap.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
        _categories.assignAll(loadedCategories);
        final roleFilteredCategories = _applyRoleFiltering(_categories);
        _organizeCategories(roleFilteredCategories);
        update();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      _errorMessage.value = 'Failed to load categories: $e';
      print('❌ loadCategories: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Apply role-based filtering to categories
  List<CategoryModel> _applyRoleFiltering(List<CategoryModel> categories) {
    if (isSuperAdmin) {
      // Super admin sees all categories
      return categories;
    } else if (isBranchAdmin) {
      // Branch admin only sees categories available in their branch
      final branchId = userBranchId;
      final branchName = userBranchName;

      return categories.where((category) {
        // Check if category is available in admin's branch
        if (branchId != null && category.isAvailableAtBranch(branchId)) {
          return true;
        }
        if (branchName != null && category.branchNames.contains(branchName)) {
          return true;
        }
        // Also include categories that are available at any branch
        return category.isAvailableAnywhere;
      }).toList();
    } else {
      // Customers only see active categories
      return categories.where((category) => category.isActive).toList();
    }
  }

  // Organize categories by type with role-based filtering
  void _organizeCategories(List<CategoryModel> categories) {
    _serviceCategories.value = categories
        .where((category) => category.isActive && category.isServiceCategory)
        .toList();

    _productCategories.value = categories
        .where((category) => category.isActive && category.isProductCategory)
        .toList();
  }

  // Get category by ID with role-based access
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();

      if (doc.exists) {
        final category = CategoryModel.fromFirestore(doc);

        // Check if user has access to this category
        if (_hasAccessToCategory(category)) {
          return category;
        }
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  // Check if user has access to category
  bool _hasAccessToCategory(CategoryModel category) {
    if (isSuperAdmin) return true;
    if (isBranchAdmin) {
      final branchId = userBranchId;
      final branchName = userBranchName;
      return (branchId != null && category.isAvailableAtBranch(branchId)) ||
          (branchName != null && category.branchNames.contains(branchName));
    }
    return category.isActive;
  }

  // Get categories by type
  List<CategoryModel> getCategoriesByType(String type) {
    List<CategoryModel> baseList;

    if (type == 'service') {
      baseList = _serviceCategories;
    } else if (type == 'product') {
      baseList = _productCategories;
    } else {
      baseList = _categories;
    }

    return baseList.where((category) => category.isActive).toList();
  }

  // Get categories by branch ID (multi-branch support)
  List<CategoryModel> getCategoriesByBranchId(String branchId) {
    final baseCategories = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;

    return baseCategories
        .where((category) => category.isActive && category.isAvailableAtBranch(branchId))
        .toList();
  }

  // Get categories by branch name (multi-branch support)
  List<CategoryModel> getCategoriesByBranchName(String branchName) {
    final baseCategories = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;

    return baseCategories
        .where((category) => category.isActive && category.branchNames.contains(branchName))
        .toList();
  }

  // Get categories by city (multi-branch support)
  List<CategoryModel> getCategoriesByCity(String city) {
    final baseCategories = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;

    return baseCategories
        .where((category) => category.isActive && category.branchCities.contains(city))
        .toList();
  }

  // Get all unique types
  List<String> getAllTypes() {
    final types = _categories
        .where((category) => category.isActive)
        .map((category) => category.type)
        .toSet()
        .toList();

    types.sort();
    return ['All', ...types];
  }

  // Get all unique branches (from all branches in categories)
  List<String> getAllBranches() {
    final allBranchNames = <String>{};

    for (final category in _categories) {
      if (category.isActive) {
        allBranchNames.addAll(category.allBranchNames);
      }
    }

    final branches = allBranchNames.toList();
    branches.sort();
    return ['All', ...branches];
  }

  // Get all unique cities
  List<String> getAllCities() {
    final cities = <String>{};

    for (final category in _categories) {
      if (category.isActive) {
        cities.addAll(category.branchCities);
      }
    }

    final cityList = cities.toList();
    cityList.sort();
    return ['All', ...cityList];
  }

  // Filter categories with multi-branch support
  List<CategoryModel> filterCategories({
    String? type,
    String? branch,
    String? city,
    String? query,
  }) {
    // Start with role-filtered active categories
    List<CategoryModel> filtered = isBranchAdmin
        ? _applyRoleFiltering(_categories)
        : _categories.where((c) => c.isActive).toList();

    // Filter by type
    if (type != null && type != 'All') {
      filtered = filtered.where((c) => c.type == type).toList();
    }

    // Filter by branch (checks both single and multi-branch)
    if (branch != null && branch != 'All') {
      filtered = filtered.where((c) => c.allBranchNames.contains(branch)).toList();
    }

    // Filter by city (checks multi-branch cities)
    if (city != null && city != 'All') {
      filtered = filtered.where((c) => c.branchCities.contains(city)).toList();
    }

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      filtered = filtered.where((c) =>
      c.name.toLowerCase().contains(searchQuery) ||
          c.description.toLowerCase().contains(searchQuery) ||
          c.allBranchNames.any((branch) => branch.toLowerCase().contains(searchQuery)) ||
          c.branchCities.any((city) => city.toLowerCase().contains(searchQuery))
      ).toList();
    }

    return filtered;
  }

  // Update filters
  void updateFilters({
    String? type,
    String? branch,
    String? city,
    String? query,
  }) {
    if (type != null) _selectedType.value = type;
    if (branch != null) _selectedBranch.value = branch;
    if (city != null) _selectedCity.value = city;
    if (query != null) _searchQuery.value = query;

    update();
  }

  // Reset all filters
  void resetFilters() {
    _selectedType.value = 'All';
    _selectedBranch.value = 'All';
    _selectedCity.value = 'All';
    _searchQuery.value = '';
    update();
  }

  // Get active categories count (role-based)
  int get activeCategoriesCount {
    final filtered = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    return filtered.where((category) => category.isActive).length;
  }

  // Get service categories count (role-based)
  int get serviceCategoriesCount {
    final filtered = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    return filtered.where((category) => category.isActive && category.isServiceCategory).length;
  }

  // Get product categories count (role-based)
  int get productCategoriesCount {
    final filtered = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    return filtered.where((category) => category.isActive && category.isProductCategory).length;
  }

  // Get categories for home screen (role-based)
  List<CategoryModel> getHomeServiceCategories({int limit = 6}) {
    final filtered = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    return filtered
        .where((category) => category.isActive && category.isServiceCategory)
        .take(limit)
        .toList();
  }

  List<CategoryModel> getHomeProductCategories({int limit = 6}) {
    final filtered = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    return filtered
        .where((category) => category.isActive && category.isProductCategory)
        .take(limit)
        .toList();
  }

  // Check if category exists (with multi-branch support)
  bool categoryExists(String name, String branchId) {
    return _categories.any((c) =>
    c.name.toLowerCase() == name.toLowerCase() &&
        c.isAvailableAtBranch(branchId) &&
        c.isActive
    );
  }

  // Add new category with multi-branch support
  Future<bool> addCategory(CategoryModel category) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // For branch admins, auto-assign their branch
      if (isBranchAdmin && userBranchId != null) {
        final updatedCategory = category.copyWith(
          branchIds: [userBranchId!],
          branchNames: [userBranchName ?? ''],
        );

        await _firestore
            .collection('categories')
            .add(updatedCategory.toFirestore());
      } else {
        await _firestore
            .collection('categories')
            .add(category.toFirestore());
      }

      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add category: $e';
      Get.snackbar('Error', 'Failed to add category: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update category
  Future<bool> updateCategory(String categoryId, CategoryModel updatedCategory) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update(updatedCategory.toFirestore());

      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update category: $e';
      Get.snackbar('Error', 'Failed to update category: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete category (soft delete - set isActive to false)
  Future<bool> deleteCategory(String categoryId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to delete category: $e';
      Get.snackbar('Error', 'Failed to delete category: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Toggle category active status
  Future<bool> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update category status: $e';
      Get.snackbar('Error', 'Failed to update category status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Refresh categories
  Future<void> refreshCategories() async {
    await loadCategories();
  }

  // Get category statistics with role-based filtering
  Map<String, dynamic> get categoryStats {
    final filteredCategories = isBranchAdmin ? _applyRoleFiltering(_categories) : _categories;
    final activeCategories = filteredCategories.where((c) => c.isActive).toList();

    final branchStats = <String, int>{};

    for (final category in activeCategories) {
      for (final branchName in category.allBranchNames) {
        branchStats[branchName] = (branchStats[branchName] ?? 0) + 1;
      }
    }

    return {
      'total': filteredCategories.length,
      'active': activeCategories.length,
      'services': activeCategories.where((c) => c.isServiceCategory).length,
      'products': activeCategories.where((c) => c.isProductCategory).length,
      'byType': {
        'service': activeCategories.where((c) => c.isServiceCategory).length,
        'product': activeCategories.where((c) => c.isProductCategory).length,
      },
      'byBranch': branchStats,
    };
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}