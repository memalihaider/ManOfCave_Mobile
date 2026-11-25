import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../utils/safe_firestore.dart';
import 'category_controller.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<Product> _products = <Product>[].obs;
  final RxList<Product> _filteredProducts = <Product>[].obs;
  final RxList<Product> _featuredProducts = <Product>[].obs;
  final RxList<Product> _inStockProducts = <Product>[].obs;
  final RxBool _isLoading = false.obs;

  // Filter states
  final RxString _selectedCategory = 'All'.obs;
  final RxString _selectedCategoryId = ''.obs;
  final RxString _selectedBranch = 'All'.obs;
  final RxString _selectedPriceRange = 'All'.obs;
  final RxString _selectedStockStatus = 'All'.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedSortBy = 'name'.obs;

  // NEW: Role-based flags
  final RxString _userRole = 'user'.obs; // 'super admin', 'branch admin', 'user', 'admin'
  final RxString _branchAdminBranchId = ''.obs; // For branch admin
  final RxString _branchAdminBranchName = ''.obs; // For branch admin
  final RxList<Product> _roleFilteredProducts = <Product>[].obs; // NEW: Products filtered by role

  // Pagination state
  final RxList<Product> _paginatedProducts = <Product>[].obs;
  DocumentSnapshot? _lastDocument;
  final RxBool _hasMore = true.obs;
  final RxBool _isLoadMoreLoading = false.obs;
  static const int _pageSize = 15;

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get inStockProducts => _inStockProducts;
  List<Product> get roleFilteredProducts => _roleFilteredProducts;
  List<Product> get paginatedProducts => _paginatedProducts;
  bool get hasMore => _hasMore.value;
  bool get isLoadMoreLoading => _isLoadMoreLoading.value;
  bool get isLoading => _isLoading.value;
  String get selectedCategory => _selectedCategory.value;
  String get selectedCategoryId => _selectedCategoryId.value;
  String get selectedBranch => _selectedBranch.value;
  String get selectedPriceRange => _selectedPriceRange.value;
  String get selectedStockStatus => _selectedStockStatus.value;
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
    // Loaded by Home / product screens when needed.
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

  // Load all products from Firestore
  Future<void> loadProducts() async {
    if (_isLoading.value) return;
    try {
      _isLoading.value = true;

      final query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(40);

      void apply(QuerySnapshot<Map<String, dynamic>> snap) {
        final loadedProducts =
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList();
        _products.assignAll(loadedProducts);
        _applyRoleBasedFiltering();
        _organizeProducts();
        update();
      }

      final querySnapshot = await SafeFirestore.getQuery(
        query,
        onCache: apply,
      );
      apply(querySnapshot);
    } catch (e) {
      print('❌ loadProducts: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Paginated load for All Products screen
  Future<void> loadProductsPaginated({bool isRefresh = false}) async {
    if (_isLoadMoreLoading.value || (!isRefresh && !_hasMore.value)) return;

    try {
      if (isRefresh) {
        _isLoading.value = true;
        _lastDocument = null;
        _hasMore.value = true;
        _paginatedProducts.clear();
      } else {
        _isLoadMoreLoading.value = true;
      }

      Query query = _firestore.collection('products');

      // Apply Filters at Server Side where possible
      if (isUser) {
        query = query.where('totalStock', isGreaterThan: 0); // basic in-stock filter
      }

      if (_selectedCategory.value != 'All') {
        query = query.where('category', isEqualTo: _selectedCategory.value);
      }

      if (_selectedCategoryId.value.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: _selectedCategoryId.value);
      }

      // Search (Prefix Search)
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
        case 'rating':
          query = query.orderBy('rating', descending: true);
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
        final newProducts = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();

        // Secondary filtering
        var filteredNewProducts = newProducts;

        if (_selectedBranch.value != 'All') {
          filteredNewProducts = filteredNewProducts.where((p) => p.branchNames.contains(_selectedBranch.value)).toList();
        }

        if (_selectedPriceRange.value != 'All') {
          final range = _selectedPriceRange.value.replaceAll('د.إ', '').split('-');
          if (range.length == 2) {
            final min = double.tryParse(range[0]) ?? 0;
            final max = double.tryParse(range[1]) ?? double.infinity;
            filteredNewProducts = filteredNewProducts.where((p) => p.price >= min && p.price <= max).toList();
          }
        }

        if (_selectedStockStatus.value != 'All') {
          switch (_selectedStockStatus.value) {
            case 'in-stock':
              filteredNewProducts = filteredNewProducts.where((p) => p.inStock && !p.isLowStock).toList();
              break;
            case 'low-stock':
              filteredNewProducts = filteredNewProducts.where((p) => p.isLowStock).toList();
              break;
            case 'out-of-stock':
              filteredNewProducts = filteredNewProducts.where((p) => !p.inStock).toList();
              break;
          }
        }

        _paginatedProducts.addAll(filteredNewProducts);
      }

      update();
    } catch (e) {
      print('❌ Error loading paginated products: $e');
    } finally {
      _isLoading.value = false;
      _isLoadMoreLoading.value = false;
    }
  }

  // NEW: Apply role-based filtering
  void _applyRoleBasedFiltering() {
    List<Product> filtered;

    if (isSuperAdmin) {
      // Super admin sees all products
      filtered = _products.toList();
    } else if (isBranchAdmin) {
      // Branch admin sees only products in their branch
      filtered = _getBranchAdminProducts();
    } else {
      // User sees only in-stock products initially
      filtered = _products.where((product) => product.inStock).toList();
    }

    _roleFilteredProducts.assignAll(filtered);

    // Also update filteredProducts based on role
    if (isUser) {
      // For users, apply normal filters
      _filteredProducts.assignAll(filtered);
      filterProducts();
    } else {
      // For admins, just show the role-filtered products
      _filteredProducts.assignAll(filtered);
    }
  }

  // NEW: Get products for branch admin
  List<Product> _getBranchAdminProducts() {
    if (_branchAdminBranchId.value.isEmpty && _branchAdminBranchName.value.isEmpty) {
      return _products; // Fallback to all products if no branch info
    }

    return _products.where((product) {
      // Check if product is available in branch admin's branch
      final hasBranchId = _branchAdminBranchId.value.isNotEmpty &&
          product.branches.contains(_branchAdminBranchId.value);
      final hasBranchName = _branchAdminBranchName.value.isNotEmpty &&
          product.branchNames.contains(_branchAdminBranchName.value);

      return hasBranchId || hasBranchName;
    }).toList();
  }

  // Organize products
  void _organizeProducts() {
    // Featured products (in stock and good rating)
    _featuredProducts.value = _products
        .where((product) => product.rating >= 0)
        .take(6)
        .toList();

    // In-stock products
    _inStockProducts.value = _products
        .where((product) => product.inStock)
        .toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Get products by category name
  List<Product> getProductsByCategory(String category) {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts
        .where((product) => product.inStock && product.category == category)
        .toList();
  }

  // Get products by category ID
  List<Product> getProductsByCategoryId(String categoryId) {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts
        .where((product) => product.inStock && product.categoryId == categoryId)
        .toList();
  }

  // Get products by branch
  List<Product> getProductsByBranch(String branchId) {
    return _products
        .where((product) => product.inStock && product.isAvailableAtBranch(branchId))
        .toList();
  }

  // Get products by branch name
  List<Product> getProductsByBranchName(String branchName) {
    return _products
        .where((product) => product.inStock && product.branchNames.contains(branchName))
        .toList();
  }

  // Get all unique categories from products (legacy)
  List<String> getAllCategories() {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    final categories = baseProducts
        .where((product) => product.inStock)
        .map((product) => product.category)
        .toSet()
        .toList();

    categories.sort();
    return ['All', ...categories];
  }

  // Get categories from CategoryController for product type
  List<String> getProductCategoriesFromController() {
    try {
      final categoryController = Get.find<CategoryController>();
      return ['All', ...categoryController.productCategories.map((c) => c.name).toList()];
    } catch (e) {
      print('Error getting categories from controller: $e');
      return getAllCategories(); // Fallback
    }
  }

  // Get all unique branches (from branchNames)
  List<String> getAllBranches() {
    final allBranches = <String>{};

    for (final product in _products) {
      allBranches.addAll(product.branchNames);
    }

    final branchesList = allBranches.toList();
    branchesList.sort();
    return ['All', ...branchesList];
  }

  // Filter products
  void filterProducts() {
    List<Product> filtered;

    // Get base products based on role
    if (isSuperAdmin) {
      filtered = _products.toList(); // Super admin sees all
    } else if (isBranchAdmin) {
      filtered = _getBranchAdminProducts(); // Branch admin sees only their branch
    } else {
      filtered = _products.where((product) => product.inStock).toList(); // User sees in-stock
    }

    // Apply filters only for users
    if (isUser) {
      // Filter by category name
      if (_selectedCategory.value != 'All') {
        filtered = filtered.where((product) => product.category == _selectedCategory.value).toList();
      }

      // Filter by category ID
      if (_selectedCategoryId.value.isNotEmpty) {
        filtered = filtered.where((product) => product.categoryId == _selectedCategoryId.value).toList();
      }

      // Filter by branch
      if (_selectedBranch.value != 'All') {
        filtered = filtered.where((product) => product.branchNames.contains(_selectedBranch.value)).toList();
      }

      // Filter by price range
      if (_selectedPriceRange.value != 'All') {
        final range = _selectedPriceRange.value.split('-');
        if (range.length == 2) {
          final minPrice = double.tryParse(range[0]) ?? 0;
          final maxPrice = double.tryParse(range[1]) ?? double.infinity;
          filtered = filtered.where((product) =>
          product.price >= minPrice && product.price <= maxPrice
          ).toList();
        } else if (_selectedPriceRange.value.startsWith('>')) {
          final minPrice = double.tryParse(_selectedPriceRange.value.substring(1)) ?? 0;
          filtered = filtered.where((product) => product.price >= minPrice).toList();
        }
      }

      // Filter by stock status
      if (_selectedStockStatus.value != 'All') {
        switch (_selectedStockStatus.value) {
          case 'in-stock':
            filtered = filtered.where((product) => product.inStock && !product.isLowStock).toList();
            break;
          case 'low-stock':
            filtered = filtered.where((product) => product.isLowStock).toList();
            break;
          case 'out-of-stock':
            filtered = filtered.where((product) => !product.inStock).toList();
            break;
        }
      }

    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((product) =>
      product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query)
      ).toList();
    }

    // Sort products
    filtered = _sortProducts(filtered);
    
    _filteredProducts.assignAll(filtered);
    _roleFilteredProducts.assignAll(filtered);
  }}

  // Sort products
  List<Product> _sortProducts(List<Product> products) {
    switch (_selectedSortBy.value) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popularity':
        products.sort((a, b) => b.totalSold.compareTo(a.totalSold));
        break;
      case 'revenue':
        products.sort((a, b) => b.revenue.compareTo(a.revenue));
        break;
      case 'stock':
        products.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        break;
      case 'profit':
        products.sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
        break;
      default: // 'name' or any other
        products.sort((a, b) => a.name.compareTo(b.name));
    }
    return products;
  }

  // Update filters
  void updateFilters({
    String? category,
    String? categoryId,
    String? branch,
    String? priceRange,
    String? stockStatus,
    String? query,
    String? sortBy,
  }) {
    if (category != null) _selectedCategory.value = category;
    if (categoryId != null) _selectedCategoryId.value = categoryId;
    if (branch != null) _selectedBranch.value = branch;
    if (priceRange != null) _selectedPriceRange.value = priceRange;
    if (stockStatus != null) _selectedStockStatus.value = stockStatus;
    if (query != null) _searchQuery.value = query;
    if (sortBy != null) _selectedSortBy.value = sortBy;

    loadProductsPaginated(isRefresh: true);
  }

  // Filter by category from CategoryController
  void filterByCategoryFromController(String categoryId, String categoryName) {
    _selectedCategoryId.value = categoryId;
    _selectedCategory.value = categoryName;
    filterProducts();
  }

  // Reset all filters
  void resetFilters() {
    _selectedCategory.value = 'All';
    _selectedCategoryId.value = '';
    _selectedBranch.value = 'All';
    _selectedPriceRange.value = 'All';
    _selectedStockStatus.value = 'All';
    _searchQuery.value = '';
    _selectedSortBy.value = 'name';
    _applyRoleBasedFiltering(); // Reset based on role
  }

  // Search products with query
  void searchProducts(String query) {
    _searchQuery.value = query;
    loadProductsPaginated(isRefresh: true);
  }

  // Get price ranges for filtering
  List<String> getPriceRanges() {
    if (_products.isEmpty) return ['All'];

    final prices = _products.map((p) => p.price).toList();
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return [
      'All',
      '0-100',
      '100-500',
      '500-1000',
      '1000-5000',
      '>5000'
    ];
  }

  // Get stock status options
  List<String> getStockStatusOptions() {
    return ['All', 'in-stock', 'low-stock', 'out-of-stock'];
  }

  // Get sort options
  List<Map<String, String>> getSortOptions() {
    return [
      {'value': 'name', 'label': 'Name (A-Z)'},
      {'value': 'price_low', 'label': 'Price (Low to High)'},
      {'value': 'price_high', 'label': 'Price (High to Low)'},
      {'value': 'rating', 'label': 'Highest Rating'},
    ];
  }

  // Get active products count
  int get activeProductsCount {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.where((product) => product.inStock).length;
  }

  // Get low stock products count
  int get lowStockProductsCount {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.where((product) => product.isLowStock).length;
  }

  // Get out of stock products count
  int get outOfStockProductsCount {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.where((product) => !product.inStock).length;
  }

  // Get total revenue from all products
  double get totalRevenue {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.fold(0.0, (sum, product) => sum + product.revenue);
  }

  // Get total sold from all products
  int get totalSold {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.fold(0, (sum, product) => sum + product.totalSold);
  }

  // Get total profit from all products
  double get totalProfit {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts.fold(0.0, (sum, product) => sum + product.totalProfit);
  }

  // Get products statistics by category
  Future<Map<String, Map<String, dynamic>>> getCategoryStats() async {
    final stats = <String, Map<String, dynamic>>{};

    try {
      final categoryController = Get.find<CategoryController>();
      final productCategories = categoryController.productCategories;
      final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;

      for (final category in productCategories) {
        final productsInCategory = baseProducts
            .where((product) => product.categoryId == category.id)
            .toList();

        stats[category.name] = {
          'id': category.id,
          'count': productsInCategory.length,
          'totalRevenue': productsInCategory.fold(0.0, (sum, product) => sum + product.revenue),
          'totalSold': productsInCategory.fold(0, (sum, product) => sum + product.totalSold),
          'totalProfit': productsInCategory.fold(0.0, (sum, product) => sum + product.totalProfit),
          'products': productsInCategory,
        };
      }
    } catch (e) {
      print('Error getting category stats: $e');
      // Fallback to old method
      final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;

      for (final product in baseProducts) {
        if (!stats.containsKey(product.category)) {
          stats[product.category] = {
            'count': 0,
            'totalRevenue': 0.0,
            'totalSold': 0,
            'totalProfit': 0.0,
            'products': <Product>[],
          };
        }

        final categoryData = stats[product.category]!;
        categoryData['count'] = categoryData['count']! + 1;
        categoryData['totalRevenue'] = categoryData['totalRevenue']! + product.revenue;
        categoryData['totalSold'] = categoryData['totalSold']! + product.totalSold;
        categoryData['totalProfit'] = categoryData['totalProfit']! + product.totalProfit;
        (categoryData['products'] as List<Product>).add(product);
      }
    }

    return stats;
  }

  // Format price for display
  String formatPrice(double price) {
    return 'د.إ${price.toStringAsFixed(2)}';
  }

  // Get products with discount (for legacy compatibility)
  List<Product> getDiscountedProducts() {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return [];
  }

  // Get sale products (products with good profit margin)
  List<Product> getSaleProducts() {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;
    return baseProducts
        .where((product) => product.inStock && product.profitMargin > 50)
        .toList();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Add new product with category validation
  Future<bool> addProduct(Product product) async {
    try {
      _isLoading.value = true;

      // Validate category exists
      try {
        final categoryController = Get.find<CategoryController>();
        final category = await categoryController.getCategoryById(product.categoryId);
        if (category == null) {
          Get.snackbar('Error', 'Category does not exist');
          return false;
        }
      } catch (e) {
        print('Category validation skipped: $e');
      }

      await _firestore
          .collection('products')
          .add(product.toFirestore());

      await loadProducts();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update product
  Future<bool> updateProduct(String productId, Product updatedProduct) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('products')
          .doc(productId)
          .update(updatedProduct.toFirestore());

      await loadProducts();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading.value = true;

      await _firestore
          .collection('products')
          .doc(productId)
          .delete();

      await loadProducts();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get products for home screen by category
  List<Product> getHomeProductsByCategory(String categoryId, {int limit = 4}) {
    return getProductsByCategoryId(categoryId)
        .take(limit)
        .toList();
  }

  // Clear category filters
  void clearCategoryFilter() {
    _selectedCategory.value = 'All';
    _selectedCategoryId.value = '';
    filterProducts();
  }

  // Get product statistics
  Map<String, dynamic> getProductStats() {
    final baseProducts = isBranchAdmin ? _getBranchAdminProducts() : _products;

    return {
      'totalProducts': baseProducts.length,
      'inStock': baseProducts.where((product) => product.inStock).length,
      'lowStock': baseProducts.where((product) => product.isLowStock).length,
      'outOfStock': baseProducts.where((product) => !product.inStock).length,
      'totalRevenue': baseProducts.fold(0.0, (sum, product) => sum + product.revenue),
      'totalSold': baseProducts.fold(0, (sum, product) => sum + product.totalSold),
      'totalProfit': baseProducts.fold(0.0, (sum, product) => sum + product.totalProfit),
      'avgProfitMargin': baseProducts.isEmpty ? 0 :
      baseProducts.fold(0.0, (sum, p) => sum + p.profitMargin) / baseProducts.length,
    };
  }
}