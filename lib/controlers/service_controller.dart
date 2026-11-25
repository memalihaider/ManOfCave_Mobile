import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../models/service_model.dart';
import '../utils/safe_firestore.dart';
import 'category_controller.dart';

class ServiceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<ServiceModel> _services = <ServiceModel>[].obs;
  final RxList<ServiceModel> _filteredServices = <ServiceModel>[].obs;
  final RxList<ServiceModel> _featuredServices = <ServiceModel>[].obs;
  final RxList<ServiceModel> _popularServices = <ServiceModel>[].obs;
  final RxBool _isLoading = false.obs;

  // Filter states
  final RxString _selectedCategory = 'All'.obs;
  final RxString _selectedCategoryId = ''.obs;
  final RxString _selectedBranch = 'All'.obs;
  final RxString _selectedPriceRange = 'All'.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedSortBy = 'name'.obs;

  // NEW: Role-based flags
  final RxString _userRole = 'user'.obs; // 'super admin', 'branch admin', 'user', 'admin'
  final RxString _branchAdminBranchId = ''.obs; // For branch admin
  final RxString _branchAdminBranchName = ''.obs; // For branch admin
  final RxList<ServiceModel> _roleFilteredServices = <ServiceModel>[].obs; // NEW: Services filtered by role

  // Pagination state
  final RxList<ServiceModel> _paginatedServices = <ServiceModel>[].obs;
  DocumentSnapshot? _lastDocument;
  final RxBool _hasMore = true.obs;
  final RxBool _isLoadMoreLoading = false.obs;
  static const int _pageSize = 15;

  List<ServiceModel> get services => _services;
  List<ServiceModel> get filteredServices => _filteredServices;
  List<ServiceModel> get featuredServices => _featuredServices;
  List<ServiceModel> get popularServices => _popularServices;
  List<ServiceModel> get roleFilteredServices => _roleFilteredServices;
  List<ServiceModel> get paginatedServices => _paginatedServices;
  bool get hasMore => _hasMore.value;
  bool get isLoadMoreLoading => _isLoadMoreLoading.value;
  bool get isLoading => _isLoading.value;
  String get selectedCategory => _selectedCategory.value;
  String get selectedCategoryId => _selectedCategoryId.value;
  String get selectedBranch => _selectedBranch.value;
  String get selectedPriceRange => _selectedPriceRange.value;
  String get searchQuery => _searchQuery.value;
  String get selectedSortBy => _selectedSortBy.value;

  // NEW: Role-based getters
  String get userRole => _userRole.value;
  String get branchAdminBranchId => _branchAdminBranchId.value;
  String get branchAdminBranchName => _branchAdminBranchName.value;

  // NEW: Check if user can see filters
  bool get canShowFilters => _userRole.value == 'user' || _userRole.value == 'customer';

  // NEW: Check if it's super admin
  bool get isSuperAdmin => _userRole.value == 'super_admin';

  // NEW: Check if it's branch admin
  bool get isBranchAdmin => _userRole.value == 'admin';

  // NEW: Check if it's regular user/customer
  bool get isUser => !isSuperAdmin && !isBranchAdmin;

  @override
  void onInit() {
    super.onInit();
    // Catalog loads on Home / screen demand — not at cold start.
  }

  // NEW: Set user role (call this when user logs in)
  void setUserRole(String role, {String? branchId, String? branchName}) {
    _userRole.value = role.toLowerCase();
    if (role.toLowerCase() == 'admin') {
      _branchAdminBranchId.value = branchId ?? '';
      _branchAdminBranchName.value = branchName ?? '';
    }
    _applyRoleBasedFiltering(); // Apply role filtering
  }

  // Load all services from Firestore
  Future<void> loadServices() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;

      final query = _firestore
          .collection('services')
          .orderBy('createdAt', descending: true)
          .limit(40);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedServices =
            snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
        _services.assignAll(loadedServices);
        _applyRoleBasedFiltering();
        _organizeServices();
        update();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      print('❌ loadServices: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Paginated load for All Services screen
  Future<void> loadServicesPaginated({bool isRefresh = false}) async {
    if (_isLoadMoreLoading.value || (!isRefresh && !_hasMore.value)) return;

    try {
      if (isRefresh) {
        _isLoading.value = true;
        _lastDocument = null;
        _hasMore.value = true;
        _paginatedServices.clear();
      } else {
        _isLoadMoreLoading.value = true;
      }

      Query query = _firestore.collection('services');

      // Apply Filters at Server Side where possible
      if (!isSuperAdmin) {
        query = query.where('status', isEqualTo: 'active');
      }

      if (_selectedCategory.value != 'All') {
        query = query.where('category', isEqualTo: _selectedCategory.value);
      }

      if (_selectedCategoryId.value.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: _selectedCategoryId.value);
      }

      // Note: Branch and Price range filtering usually require indexes or are complex for server-side
      // For now, we apply basic status and category at server side.

      // Search (Prefix Search) - Case sensitive and limited, but global
      if (_searchQuery.value.isNotEmpty) {
        final queryText = _searchQuery.value.trim();
        query = query.where('name', isGreaterThanOrEqualTo: queryText)
                     .where('name', isLessThanOrEqualTo: '$queryText\uf8ff');
      }

      // Sort
      switch (_selectedSortBy.value) {
        case 'price_low':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_high':
          query = query.orderBy('price', descending: true);
          break;
        default:
          query = query.orderBy('name', descending: false);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_pageSize);

      final querySnapshot =
          await query.get().timeout(SafeFirestore.defaultTimeout);

      if (querySnapshot.docs.length < _pageSize) {
        _hasMore.value = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        final newServices = querySnapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList();

        // Secondary filtering for things Firestore can't easily do without extra indexes
        var filteredNewServices = newServices;

        if (_selectedBranch.value != 'All') {
          filteredNewServices = filteredNewServices.where((s) => s.branchNames.contains(_selectedBranch.value)).toList();
        }

        if (_selectedPriceRange.value != 'All') {
          final range = _selectedPriceRange.value.split('-');
          if (range.length == 2) {
            final min = double.tryParse(range[0]) ?? 0;
            final max = double.tryParse(range[1]) ?? double.infinity;
            filteredNewServices = filteredNewServices.where((s) => s.price >= min && s.price <= max).toList();
          }
        }

        _paginatedServices.addAll(filteredNewServices);
      }

      update();
    } catch (e) {
      print('❌ Error loading paginated services: $e');
    } finally {
      _isLoading.value = false;
      _isLoadMoreLoading.value = false;
    }
  }

  // NEW: Apply role-based filtering
  void _applyRoleBasedFiltering() {
    List<ServiceModel> filtered;

    if (isSuperAdmin) {
      // Super admin sees all services
      filtered = _services.toList();
    } else if (isBranchAdmin) {
      // Branch admin sees only services in their branch
      filtered = _getBranchAdminServices();
    } else {
      // User sees only active services initially
      filtered = _services.where((service) => service.isActive).toList();
    }

    _roleFilteredServices.assignAll(filtered);

    // Also update filteredServices based on role
    if (isUser) {
      // For users, apply normal filters
      _filteredServices.assignAll(filtered);
      filterServices();
    } else {
      // For admins, just show the role-filtered services
      _filteredServices.assignAll(filtered);
    }
  }

  // NEW: Get services for branch admin
  List<ServiceModel> _getBranchAdminServices() {
    if (_branchAdminBranchId.value.isEmpty && _branchAdminBranchName.value.isEmpty) {
      return _services; // Fallback to all services if no branch info
    }

    return _services.where((service) {
      // Check if service is available in branch admin's branch
      final hasBranchId = _branchAdminBranchId.value.isNotEmpty &&
          service.branches.contains(_branchAdminBranchId.value);
      final hasBranchName = _branchAdminBranchName.value.isNotEmpty &&
          service.branchNames.contains(_branchAdminBranchName.value);

      return hasBranchId || hasBranchName;
    }).toList();
  }

  // Organize services into categories and featured lists
  void _organizeServices() {
    // Featured services (active and available)
    _featuredServices.value = _services
        .where((service) => service.isActive && service.isAvailable)
        .take(6)
        .toList();

    // Popular services (high popularity)
    _popularServices.value = _services
        .where((service) => service.isActive && service.isPopular)
        .toList();
  }

  // Get service by ID
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();

      if (doc.exists) {
        return ServiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting service: $e');
      return null;
    }
  }

  // Get services by category name
  List<ServiceModel> getServicesByCategory(String category) {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return baseServices
        .where((service) => service.isActive && service.category == category)
        .toList();
  }

  // Get services by category ID
  List<ServiceModel> getServicesByCategoryId(String categoryId) {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return baseServices
        .where((service) => service.isActive && service.categoryId == categoryId)
        .toList();
  }

  // Get services by branch
  List<ServiceModel> getServicesByBranch(String branchId) {
    return _services
        .where((service) => service.isActive && service.isAvailableAtBranch(branchId))
        .toList();
  }

  // Get services by branch name
  List<ServiceModel> getServicesByBranchName(String branchName) {
    return _services
        .where((service) => service.isActive && service.branchNames.contains(branchName))
        .toList();
  }

  // Get all unique categories from services (legacy)
  List<String> getAllCategories() {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    final categories = baseServices
        .where((service) => service.isActive)
        .map((service) => service.category)
        .toSet()
        .toList();

    categories.sort();
    return ['All', ...categories];
  }

  // Get categories from CategoryController for service type
  List<String> getServiceCategoriesFromController() {
    try {
      final categoryController = Get.find<CategoryController>();
      return ['All', ...categoryController.serviceCategories.map((c) => c.name).toList()];
    } catch (e) {
      print('Error getting categories from controller: $e');
      return getAllCategories(); // Fallback
    }
  }

  // Get all unique branches (from branchNames)
  List<String> getAllBranches() {
    final allBranches = <String>{};

    for (final service in _services) {
      allBranches.addAll(service.branchNames);
    }

    final branchesList = allBranches.toList();
    branchesList.sort();
    return ['All', ...branchesList];
  }

  // Filter services
  void filterServices() {
    List<ServiceModel> filtered;

    // Get base services based on role
    if (isSuperAdmin) {
      filtered = _services.toList(); // Super admin sees all
    } else if (isBranchAdmin) {
      filtered = _getBranchAdminServices(); // Branch admin sees only their branch
    } else {
      filtered = _services.where((service) => service.isActive).toList(); // User sees active
    }

    // Apply filters only for users
    if (isUser) {
      // Filter by category name
      if (_selectedCategory.value != 'All') {
        filtered = filtered.where((service) => service.category == _selectedCategory.value).toList();
      }

      // Filter by category ID
      if (_selectedCategoryId.value.isNotEmpty) {
        filtered = filtered.where((service) => service.categoryId == _selectedCategoryId.value).toList();
      }

      // Filter by branch
      if (_selectedBranch.value != 'All') {
        filtered = filtered.where((service) => service.branchNames.contains(_selectedBranch.value)).toList();
      }

      // Filter by price range
      if (_selectedPriceRange.value != 'All') {
        final range = _selectedPriceRange.value.split('-');
        if (range.length == 2) {
          final minPrice = double.tryParse(range[0]) ?? 0;
          final maxPrice = double.tryParse(range[1]) ?? double.infinity;
          filtered = filtered.where((service) =>
          service.price >= minPrice && service.price <= maxPrice
          ).toList();
        } else if (_selectedPriceRange.value.startsWith('>')) {
          final minPrice = double.tryParse(_selectedPriceRange.value.substring(1)) ?? 0;
          filtered = filtered.where((service) => service.price >= minPrice).toList();
        }
      }

      // Filter by search query
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        filtered = filtered.where((service) =>
        service.name.toLowerCase().contains(query) ||
            service.category.toLowerCase().contains(query) ||
            service.description.toLowerCase().contains(query) ||
            service.popularity.toLowerCase().contains(query)
        ).toList();
      }

      // Sort services
      filtered = _sortServices(filtered);
    }

    _filteredServices.assignAll(filtered);
    _roleFilteredServices.assignAll(filtered);
  }

  // Sort services
  List<ServiceModel> _sortServices(List<ServiceModel> services) {
    switch (_selectedSortBy.value) {
      case 'price_low':
        services.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        services.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popularity':
        services.sort((a, b) {
          final popularityOrder = {'high': 3, 'medium': 2, 'low': 1};
          return popularityOrder[b.popularity]!.compareTo(popularityOrder[a.popularity]!);
        });
        break;
      case 'bookings':
        services.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
        break;
      case 'revenue':
        services.sort((a, b) => b.revenue.compareTo(a.revenue));
        break;
      case 'duration':
        services.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      default: // 'name' or any other
        services.sort((a, b) => a.name.compareTo(b.name));
    }
    return services;
  }

  // Update filters
  void updateFilters({
    String? category,
    String? categoryId,
    String? branch,
    String? priceRange,
    String? query,
    String? sortBy,
  }) {
    if (category != null) _selectedCategory.value = category;
    if (categoryId != null) _selectedCategoryId.value = categoryId;
    if (branch != null) _selectedBranch.value = branch;
    if (priceRange != null) _selectedPriceRange.value = priceRange;
    if (query != null) _searchQuery.value = query;
    if (sortBy != null) _selectedSortBy.value = sortBy;

    // Reset pagination and reload
    loadServicesPaginated(isRefresh: true);
  }

  // Filter by category from CategoryController
  void filterByCategoryFromController(String categoryId, String categoryName) {
    _selectedCategoryId.value = categoryId;
    _selectedCategory.value = categoryName;
    filterServices();
  }

  // Reset all filters
  void resetFilters() {
    _selectedCategory.value = 'All';
    _selectedCategoryId.value = '';
    _selectedBranch.value = 'All';
    _selectedPriceRange.value = 'All';
    _searchQuery.value = '';
    _selectedSortBy.value = 'name';
    _applyRoleBasedFiltering(); // Reset based on role
  }

  // Search services with query
  void searchServices(String query) {
    _searchQuery.value = query;
    loadServicesPaginated(isRefresh: true);
  }

  // Get price ranges for filtering
  List<String> getPriceRanges() {
    if (_services.isEmpty) return ['All'];

    final prices = _services.map((s) => s.price).toList();
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return [
      'All',
      '0-50',
      '50-100',
      '100-200',
      '200-500',
      '>500'
    ];
  }

  // Get sort options
  List<Map<String, String>> getSortOptions() {
    return [
      {'value': 'name', 'label': 'Name (A-Z)'},
      {'value': 'price_low', 'label': 'Price (Low to High)'},
      {'value': 'price_high', 'label': 'Price (High to Low)'},

    ];
  }

  // Get active services count
  int get activeServicesCount {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return baseServices.where((service) => service.isActive).length;
  }

  // Get total revenue from all services
  double get totalRevenue {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return baseServices.fold(0.0, (sum, service) => sum + service.revenue);
  }

  // Get total bookings from all services
  int get totalBookings {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return baseServices.fold(0, (sum, service) => sum + service.totalBookings);
  }

  // Get services statistics by category (using CategoryController)
  Future<Map<String, Map<String, dynamic>>> getCategoryStats() async {
    final stats = <String, Map<String, dynamic>>{};

    try {
      final categoryController = Get.find<CategoryController>();
      final serviceCategories = categoryController.serviceCategories;
      final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;

      for (final category in serviceCategories) {
        final servicesInCategory = baseServices
            .where((service) => service.categoryId == category.id)
            .toList();

        stats[category.name] = {
          'id': category.id,
          'count': servicesInCategory.length,
          'totalRevenue': servicesInCategory.fold(0.0, (sum, service) => sum + service.revenue),
          'totalBookings': servicesInCategory.fold(0, (sum, service) => sum + service.totalBookings),
          'services': servicesInCategory,
        };
      }
    } catch (e) {
      print('Error getting category stats: $e');
      // Fallback to old method
      final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;

      for (final service in baseServices) {
        if (!stats.containsKey(service.category)) {
          stats[service.category] = {
            'count': 0,
            'totalRevenue': 0.0,
            'totalBookings': 0,
            'services': <ServiceModel>[],
          };
        }

        final categoryData = stats[service.category]!;
        categoryData['count'] = categoryData['count']! + 1;
        categoryData['totalRevenue'] = categoryData['totalRevenue']! + service.revenue;
        categoryData['totalBookings'] = categoryData['totalBookings']! + service.totalBookings;
        (categoryData['services'] as List<ServiceModel>).add(service);
      }
    }

    return stats;
  }

  // Format price for display
  String formatPrice(double price) {
    return '${price.toStringAsFixed(2)} ${AppStrings.appCurreny}';
  }

  // Format duration for display
  String formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  // Get services with discount (for legacy compatibility)
  List<ServiceModel> getDiscountedServices() {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;
    return [];
  }

  // Refresh services
  Future<void> refreshServices() async {
    await loadServices();
  }

  // Add new service with category validation
  Future<bool> addService(ServiceModel service) async {
    try {
      _isLoading.value = true;

      // Validate category exists
      try {
        final categoryController = Get.find<CategoryController>();
        final category = await categoryController.getCategoryById(service.categoryId);
        if (category == null) {
          Get.snackbar('Error', 'Category does not exist');
          return false;
        }
      } catch (e) {
        print('Category validation skipped: $e');
      }

      await _firestore
          .collection('services')
          .add(service.toFirestore());

      await loadServices();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add service: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update service
  Future<bool> updateService(String serviceId, ServiceModel updatedService) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('services')
          .doc(serviceId)
          .update(updatedService.toFirestore());

      await loadServices();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update service: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('services')
          .doc(serviceId)
          .delete();

      await loadServices();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete service: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get services for home screen by category
  List<ServiceModel> getHomeServicesByCategory(String categoryId, {int limit = 4}) {
    return getServicesByCategoryId(categoryId)
        .take(limit)
        .toList();
  }

  // Get featured services by category
  List<ServiceModel> getFeaturedServicesByCategory(String categoryId) {
    return getServicesByCategoryId(categoryId)
        .where((service) => service.isActive && service.isPopular)
        .take(3)
        .toList();
  }

  // Clear category filters
  void clearCategoryFilter() {
    _selectedCategory.value = 'All';
    _selectedCategoryId.value = '';
    filterServices();
  }

  // NEW: Get service statistics
  Map<String, dynamic> getServiceStats() {
    final baseServices = isBranchAdmin ? _getBranchAdminServices() : _services;

    return {
      'totalServices': baseServices.length,
      'activeServices': baseServices.where((service) => service.isActive).length,
      'popularServices': baseServices.where((service) => service.isPopular).length,
      'totalRevenue': baseServices.fold(0.0, (sum, service) => sum + service.revenue),
      'totalBookings': baseServices.fold(0, (sum, service) => sum + service.totalBookings),
      'avgRevenuePerBooking': baseServices.fold(0.0, (sum, service) => sum + service.averageRevenuePerBooking) / baseServices.length,
    };
  }
}