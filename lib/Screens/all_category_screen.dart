// screens/all_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/category_controller.dart';
import '../controlers/auth_controller.dart';
import '../models/branch_model.dart';
import '../models/category_model.dart';
import '../widgets/category_card.dart';
import '../widgets/shimmer_loading.dart';
import 'all_product_screen.dart';
import 'all_services_screen.dart';

class AllCategoriesScreen extends StatefulWidget {
  final Branch? selectedBranch;

  const AllCategoriesScreen({
    super.key,
    this.selectedBranch,
  });

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  late final CategoryController _categoryController;
  late final AuthController _authController;

  // Filter states
  String _selectedType = 'all'; // 'all', 'service', 'product'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryController = Get.find<CategoryController>();
    _authController = Get.find<AuthController>();
    _searchController.addListener(_onSearchChanged);
    if (_categoryController.categories.isEmpty) {
      _categoryController.loadCategories();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  List<CategoryModel> _getFilteredCategories() {
    // Use the sorted getter to show images first
    List<CategoryModel> categories = _categoryController.sortedCategories;

    // Filter by branch if selected
    if (widget.selectedBranch != null) {
      final branchId = widget.selectedBranch!.id;
      final branchName = widget.selectedBranch!.name;
      categories = categories.where((category) {
        return category.isAvailableAtBranch(branchId) ||
            category.branchNames.contains(branchName);
      }).toList();
    }

    // Filter by type
    if (_selectedType == 'service') {
      categories = categories.where((c) => c.isServiceCategory).toList();
    } else if (_selectedType == 'product') {
      categories = categories.where((c) => c.isProductCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      categories = categories.where((c) =>
      c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.type.toLowerCase().contains(query)).toList();
    }

    return categories;
  }

  void _onCategoryTap(CategoryModel category) {
    if (category.isServiceCategory) {
      Get.to(() => AllServicesScreen(
        categoryId: category.id,
        categoryName: category.name,
      ));
    } else {
      Get.to(() => AllProductsScreen(
        categoryId: category.id,
        categoryName: category.name,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.selectedBranch != null
              ? 'Categories - ${widget.selectedBranch!.name}'
              : 'All Categories',
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
          IconButton(
            onPressed: () => _categoryController.refreshCategories(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(isLandscape),
              SizedBox(height: AppSizes.spaceSmall8),

              // Type Filter Chips
              _buildTypeFilterChips(isLandscape),
              SizedBox(height: AppSizes.spaceSmall8),

              // Branch Info Banner (if branch selected)
              if (widget.selectedBranch != null)
                _buildBranchInfoBanner(isLandscape),

              // Categories Count and Results
              _buildResultsHeader(isLandscape),

              // Categories Grid
              Expanded(
                child: _buildCategoriesGrid(isLandscape),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
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
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),
            Icon(
              Icons.search,
              size: 20.sp,
              color: Colors.grey[400],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[400],
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
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
    );
  }

  Widget _buildTypeFilterChips(bool isLandscape) {
    final filters = [
      {'value': 'all', 'label': 'ALL', 'icon': Icons.category},
      {'value': 'service', 'label': 'SERVICES', 'icon': Icons.spa},
      {'value': 'product', 'label': 'PRODUCTS', 'icon': Icons.shopping_bag},
    ];

    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedType == filter['value'];
          
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = filter['value']!.toString();
                });
              },
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 14.sp,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        filter['label']!.toString(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchInfoBanner(bool isLandscape) {
    return Container(
      margin: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceSmall8,
      ),
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
              'Showing categories available at: ${widget.selectedBranch!.name}',
              style: TextStyle(
                fontSize: isLandscape ? AppSizes.font(10) : AppSizes.textSmall12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.back();
            },
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
    );
  }

  Widget _buildResultsHeader(bool isLandscape) {
    final categories = _getFilteredCategories();
    final totalCount = categories.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$totalCount CATEGORIES FOUND',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          if (_selectedType != 'all')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                _selectedType.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(bool isLandscape) {
    final categories = _getFilteredCategories();

    if (_categoryController.isLoading) {
      return _buildLoadingState();
    }

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 3 : 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () => _onCategoryTap(category),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: GridView.builder(
        padding: AppSizes.paddingSymmetric(
          horizontal: AppSizes.spaceMedium16,
          vertical: AppSizes.spaceSmall8,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSizes.width(12),
          mainAxisSpacing: AppSizes.height(12),
          childAspectRatio: 1.0,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: AppSizes.paddingAll(AppSizes.spaceExtraLarge32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.category_outlined,
              size: AppSizes.icon(80),
              color: Colors.grey[300],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              _getEmptyStateTitle(),
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              SizedBox(height: AppSizes.spaceLarge24),
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
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
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
    if (_searchQuery.isNotEmpty) {
      return 'No categories found';
    }
    if (widget.selectedBranch != null) {
      return 'No categories available at this branch';
    }
    if (_selectedType == 'service') {
      return 'No service categories found';
    }
    if (_selectedType == 'product') {
      return 'No product categories found';
    }
    return 'No categories available';
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'Try a different search term or clear the search';
    }
    if (widget.selectedBranch != null) {
      return 'This branch doesn\'t have any categories available at the moment';
    }
    if (_selectedType == 'service') {
      return 'No service categories have been added yet';
    }
    if (_selectedType == 'product') {
      return 'No product categories have been added yet';
    }
    return 'Categories will appear here once added';
  }
}