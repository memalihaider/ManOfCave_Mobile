import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/Screens/service_details_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/service_controller.dart';
import '../controlers/category_controller.dart';
import '../controlers/auth_controller.dart';
import '../models/service_model.dart';
import '../widgets/service_card.dart';
import '../widgets/shimmer_loading.dart';
import 'AdminScreens/admin_service_details_screen.dart';

class AllServicesScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const AllServicesScreen({
    super.key,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  late final ServiceController serviceController;
  late final CategoryController categoryController;
  late final AuthController authController;

  // Search related controllers
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  final RxBool _isSearching = false.obs;

  // Pagination related
  late final ScrollController _scrollController;
  final RxBool _isInitialLoading = true.obs;

  // Track if category filter is applied from navigation
  final RxBool _isCategoryFilterApplied = false.obs;
  final RxString _appliedCategoryId = ''.obs;
  final RxString _appliedCategoryName = ''.obs;

  bool get isSuperAdmin {
    try {
      return serviceController.isSuperAdmin;
    } catch (e) {
      return false;
    }
  }

  bool get isBranchAdmin {
    try {
      return serviceController.isBranchAdmin;
    } catch (e) {
      return false;
    }
  }

  bool get isUser {
    try {
      return serviceController.isUser;
    } catch (e) {
      return true;
    }
  }

  bool get shouldShowFilters => isUser;
  bool get shouldShowCategoryChips => isUser;
  bool get shouldShowSearchBar => true;
  bool get shouldShowFilterButton => isUser;

  String get screenTitle {
    try {
      if (_isCategoryFilterApplied.value && _appliedCategoryName.value.isNotEmpty) {
        return _appliedCategoryName.value;
      }
      if (isSuperAdmin) return 'All Services (Admin View)';
      if (isBranchAdmin) return 'Services - ${serviceController.branchAdminBranchName ?? 'My Branch'}';
      return 'All Services';
    } catch (e) {
      return 'All Services';
    }
  }

  @override
  void initState() {
    super.initState();
    serviceController = Get.find<ServiceController>();
    categoryController = Get.find<CategoryController>();
    authController = Get.find<AuthController>();

    _initializeUserRole();
    _initializeCategoryFilter();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    _isInitialLoading.value = true;
    try {
      await serviceController
          .loadServicesPaginated(isRefresh: true)
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      print('❌ services initial load: $e');
    } finally {
      _isInitialLoading.value = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      serviceController.loadServicesPaginated();
    }
  }

  void _initializeUserRole() {
    try {
      final user = authController.currentUser.value;
      if (user != null) {
        serviceController.setUserRole(
          user.role,
          branchId: user.branchId,
          branchName: user.branchName,
        );
      } else {
        serviceController.setUserRole('user');
      }
    } catch (e) {
      print('Error initializing user role: $e');
      serviceController.setUserRole('user');
    }
  }

  void _initializeCategoryFilter() {
    // Check if categoryId was passed from navigation
    if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      _isCategoryFilterApplied.value = true;
      _appliedCategoryId.value = widget.categoryId!;
      _appliedCategoryName.value = widget.categoryName ?? 'Category';

      // Apply category filter to service controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        serviceController.updateFilters(
          categoryId: widget.categoryId,
          category: widget.categoryName ?? '',
        );
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    // Reset filters when leaving if category filter was applied
    if (_isCategoryFilterApplied.value) {
      serviceController.resetFilters();
    }
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _isSearching.close();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentQuery = _searchController.text.trim();

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    if (currentQuery.isEmpty) {
      _lastSearchQuery = '';
      _isSearching.value = false;
      serviceController.updateFilters(query: '');
      setState(() {});
      return;
    }

    _isSearching.value = true;

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (currentQuery.length >= 2 || currentQuery != _lastSearchQuery) {
        _performSearch(currentQuery);
      } else {
        _isSearching.value = false;
      }
    });
  }

  void _performSearch(String query) {
    try {
      _lastSearchQuery = query;
      serviceController.updateFilters(query: query);
      _isSearching.value = false;
      setState(() {});
    } catch (e) {
      print('Search error: $e');
      _isSearching.value = false;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _lastSearchQuery = '';
    _isSearching.value = false;
    serviceController.updateFilters(query: '');
    _searchFocusNode.unfocus();
  }

  void _clearCategoryFilter() {
    _isCategoryFilterApplied.value = false;
    _appliedCategoryId.value = '';
    _appliedCategoryName.value = '';
    serviceController.updateFilters(categoryId: '', category: 'All');
  }

  String get selectedCategory {
    try {
      if (_isCategoryFilterApplied.value) {
        return _appliedCategoryName.value;
      }
      return serviceController.selectedCategory;
    } catch (e) {
      return 'All';
    }
  }

  String get selectedSort {
    try {
      return serviceController.selectedSortBy;
    } catch (e) {
      return 'name';
    }
  }

  void _updateCategory(String category) {
    try {
      if (_isCategoryFilterApplied.value && category == _appliedCategoryName.value) {
        return;
      }
      if (_isCategoryFilterApplied.value) {
        _isCategoryFilterApplied.value = false;
      }
      serviceController.updateFilters(category: category);
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  void _updateSort(String sort) {
    try {
      serviceController.updateFilters(sortBy: sort);
    } catch (e) {
      print('Error updating sort: $e');
    }
  }

  List<ServiceModel> _getFilteredServices() {
    return serviceController.paginatedServices;
  }

  String _getSortLabel(String sortValue) {
    try {
      final sortOptions = serviceController.getSortOptions();
      final option = sortOptions.firstWhere(
            (option) => option['value'] == sortValue,
        orElse: () => {'value': 'name', 'label': 'Name (A-Z)'},
      );
      return option['label'] ?? 'Name (A-Z)';
    } catch (e) {
      return 'Name (A-Z)';
    }
  }

  List<String> _getSortOptionsForUI() {
    try {
      final sortOptions = serviceController.getSortOptions();
      return sortOptions.map((option) => option['value']!).toList();
    } catch (e) {
      return ['name', 'price_low', 'price_high'];
    }
  }

  List<String> _getSortLabelsForUI() {
    try {
      final sortOptions = serviceController.getSortOptions();
      return sortOptions.map((option) => option['label']!).toList();
    } catch (e) {
      return ['Name (A-Z)', 'Price: Low to High', 'Price: High to Low'];
    }
  }

  List<String> _getCategoriesForFilter() {
    try {
      final categories = serviceController.getServiceCategoriesFromController();
      return categories.isNotEmpty ? categories : ['All'];
    } catch (e) {
      print('Error getting categories from controller: $e');
      try {
        return serviceController.getAllCategories();
      } catch (e) {
        return ['All'];
      }
    }
  }

  void _showFilterBottomSheet() {
    final categories = _getCategoriesForFilter();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge20),
                  topRight: Radius.circular(AppSizes.radiusLarge20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8, bottom: AppSizes.spaceSmall8),
                    width: AppSizes.width(40),
                    height: AppSizes.height(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                  ),
                  Padding(
                    padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: AppSizes.textLarge18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            try {
                              if (_isCategoryFilterApplied.value) {
                                _clearCategoryFilter();
                              }
                              serviceController.resetFilters();
                            } catch (e) {
                              print('Error resetting filters: $e');
                            }
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: Text(
                            'Reset All',
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      children: [
                        if (isUser && !_isCategoryFilterApplied.value) ...[
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: AppSizes.spaceSmall8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: categories.map((category) {
                              return RadioListTile<String>(
                                title: Text(category),
                                value: category,
                                groupValue: selectedCategory,
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(() {
                                      _updateCategory(value);
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ),
                          SizedBox(height: AppSizes.spaceMedium16),
                        ],

                        if (isUser && !_isCategoryFilterApplied.value) ...[
                          Text(
                            'Branch',
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: AppSizes.spaceSmall8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: serviceController.getAllBranches().map((branch) {
                              return RadioListTile<String>(
                                title: Text(branch),
                                value: branch,
                                groupValue: serviceController.selectedBranch,
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(() {
                                      try {
                                        serviceController.updateFilters(branch: value);
                                      } catch (e) {
                                        print('Error updating branch: $e');
                                      }
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ),
                          SizedBox(height: AppSizes.spaceMedium16),
                        ],

                        if (isUser && !_isCategoryFilterApplied.value) ...[
                          Text(
                            'Price Range',
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: AppSizes.spaceSmall8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPriceRangeTile('All', 'All Prices'),
                              _buildPriceRangeTile('0-50', '\$0 - \$50'),
                              _buildPriceRangeTile('50-100', '\$50 - \$100'),
                              _buildPriceRangeTile('100-200', '\$100 - \$200'),
                              _buildPriceRangeTile('200+', '\$200+'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGold,
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.spaceMedium16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                                side: BorderSide(color: AppColors.primaryGold),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.spaceMedium16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceRangeTile(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: serviceController.selectedPriceRange,
      onChanged: (selectedValue) {
        if (selectedValue != null) {
          try {
            serviceController.updateFilters(priceRange: selectedValue);
            setState(() {});
          } catch (e) {
            print('Error updating price range: $e');
          }
        }
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  void _showSortBottomSheet() {
    final sortOptions = _getSortOptionsForUI();
    final sortLabels = _getSortLabelsForUI();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge20),
                  topRight: Radius.circular(AppSizes.radiusLarge20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: AppSizes.paddingOnly(top: AppSizes.spaceSmall8, bottom: AppSizes.spaceSmall8),
                    width: AppSizes.width(40),
                    height: AppSizes.height(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                  ),
                  Padding(
                    padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                    child: Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: AppSizes.textLarge18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ...List.generate(sortOptions.length, (index) {
                    final sortValue = sortOptions[index];
                    final sortLabel = sortLabels[index];

                    return RadioListTile<String>(
                      title: Text(sortLabel),
                      value: sortValue,
                      groupValue: selectedSort,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            _updateSort(value);
                          });
                          Navigator.pop(context);
                        }
                      },
                      contentPadding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
                    );
                  }),
                  SizedBox(height: AppSizes.spaceLarge24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategoriesForFilter();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          screenTitle,
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isCategoryFilterApplied.value)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearCategoryFilter,
              tooltip: 'Clear Category Filter',
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Banner (when filtering by category)
          if (_isCategoryFilterApplied.value)
            Container(
              margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16, vertical: AppSizes.spaceSmall8),
              padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    size: AppSizes.iconSmall18,
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Text(
                      'Showing services in: ${_appliedCategoryName.value}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearCategoryFilter,
                    child: Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      child: Icon(
                        Icons.close,
                        size: AppSizes.iconSmall14,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          if (shouldShowSearchBar)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? AppColors.primaryGold
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16.w),
                          Icon(
                            Icons.search,
                            size: 20.sp,
                            color: _searchFocusNode.hasFocus ? AppColors.primaryGold : Colors.grey[400],
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search services...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13.sp,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Padding(
                                padding: EdgeInsets.all(8.r),
                                child: Icon(Icons.clear, size: 18.sp, color: Colors.grey[400]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (shouldShowFilterButton && !_isCategoryFilterApplied.value) ...[
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        height: 48.h,
                        width: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.tune, color: AppColors.white, size: 20.sp),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Search Hint
          if (_searchController.text.isNotEmpty && _searchController.text.length < 2)
            Padding(
              padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
              child: Row(
                children: [
                  Container(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceSmall8,
                      vertical: AppSizes.spaceSmall8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppSizes.iconSmall14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          'Type at least 2 characters to search',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Active Search Indicator
          if (_searchController.text.isNotEmpty && _searchController.text.length >= 2 && !_isSearching.value)
            Padding(
              padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
              child: Row(
                children: [
                  Container(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceSmall8,
                      vertical: AppSizes.spaceSmall8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          size: AppSizes.iconSmall14,
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Expanded(
                          child: Text(
                            'Searching: "${_searchController.text}"',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: AppColors.primaryGold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Category Filter Chips
          if (shouldShowCategoryChips && categories.isNotEmpty)
            Obx(() {
              // Access observable at top level to ensure Obx works correctly
              final _ = selectedCategory;
              
              return Container(
                height: 40.h,
                margin: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: GestureDetector(
                        onTap: () => _updateCategory(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryGold : AppColors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryGold : Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

          // Results Count and Sort
          if (shouldShowFilters)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      try {
                        final filteredServices = _getFilteredServices();
                        final count = isSuperAdmin
                            ? serviceController.services.length
                            : isBranchAdmin
                            ? serviceController.roleFilteredServices.length
                            : filteredServices.length;
                            
                        return Text(
                          '$count SERVICES FOUND',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[500],
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      } catch (e) {
                        return const SizedBox();
                      }
                    }),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _showSortBottomSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 14.sp, color: AppColors.primaryGold),
                          SizedBox(width: 8.w),
                          Obx(() => Text(
                            _getSortLabel(selectedSort).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Branch admin info banner
          if (isBranchAdmin && serviceController.branchAdminBranchName != null)
            Container(
              margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16, vertical: AppSizes.spaceSmall8),
              padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.store,
                    size: AppSizes.iconSmall18,
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Text(
                      _appliedCategoryName.value.isNotEmpty
                          ? 'Viewing ${serviceController.getServicesByCategory(_appliedCategoryName.toString()).length} services for: ${serviceController.branchAdminBranchName}'
                          : 'Viewing ${serviceController.roleFilteredServices.length} services for: ${serviceController.branchAdminBranchName}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Services Grid
          Expanded(
            child: Obx(() {
              if (_isInitialLoading.value) {
                return ShimmerLoading(
                  child: GridView.builder(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceMedium16,
                      vertical: AppSizes.spaceSmall8,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) => const ShimmerCard(),
                  ),
                );
              }

              final services = serviceController.paginatedServices;

              if (services.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceMedium16,
                        vertical: AppSizes.spaceSmall8,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ServiceCard(
                          service: service,
                          showDeleteButton: isSuperAdmin || isBranchAdmin,
                          onTap: () {
                            if (service.id.isNotEmpty) {
                              if (isSuperAdmin || isBranchAdmin) {
                                Get.to(() => AdminServiceDetailScreen(serviceId: service.id));
                              } else {
                                Get.to(() => ServiceDetailScreen(serviceId: service.id));
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                  if (serviceController.isLoadMoreLoading)
                    Padding(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGold,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  if (!serviceController.hasMore && services.isNotEmpty)
                    Padding(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      child: Text(
                        'No more services to show',
                        style: TextStyle(color: Colors.grey[500], fontSize: AppSizes.textSmall12),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty && _searchController.text.length >= 2
                  ? Icons.search_off
                  : Icons.spa_outlined,
              size: AppSizes.iconLarge60,
              color: Colors.grey[300],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              _getEmptyStateTitle(),
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty && _searchController.text.length >= 2) ...[
              SizedBox(height: AppSizes.spaceMedium16),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceLarge24,
                    vertical: AppSizes.spaceSmall8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  ),
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (_searchController.text.isNotEmpty && _searchController.text.length >= 2) {
      return 'No services found';
    }

    try {
      if (isSuperAdmin) {
        return 'No services in the system';
      } else if (isBranchAdmin) {
        return 'No services available in your branch';
      }
    } catch (e) {
      // Fall through to default
    }

    return 'No services found';
  }

  String _getEmptyStateMessage() {
    if (_searchController.text.isNotEmpty && _searchController.text.length >= 2) {
      return 'Try a different search term or clear the search';
    }

    try {
      if (isSuperAdmin) {
        return 'Add services to get started';
      } else if (isBranchAdmin) {
        return 'Contact admin to add services to your branch';
      } else {
        if (selectedCategory != 'All' ||
            serviceController.selectedBranch != 'All' ||
            serviceController.selectedPriceRange != 'All') {
          return 'Try adjusting your filters';
        }
      }
    } catch (e) {
      // Fall through to default
    }

    return 'Check back later for new services';
  }
}