// screens/admin_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/staff_controller.dart';
import '../../controlers/auth_controller.dart';
import '../../models/staff.dart';
import 'admin_staff_card.dart' show StaffCard;
import 'admin_staff_details_screen.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  final StaffController _controller = Get.find<StaffController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _selectedFilter = 'all'.obs;
  final RxString _selectedBranch = 'all'.obs;
  final RxString _searchQuery = ''.obs;

  // Get user role and branch info
  String get userRole => _authController.currentUser.value?.role ?? 'customer';
  String? get userBranchId => _authController.currentUser.value?.branchId;
  String? get userBranchName => _authController.currentUser.value?.branchName;
  bool get isBranchAdmin => userRole == 'admin' || userRole == 'branch_admin';
  bool get isSuperAdmin => userRole == 'super_admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadStaff();
      _controller.getStaffRoles();
    });
    if (isBranchAdmin && userBranchName != null) {
      _selectedBranch.value = userBranchName!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Staff> getFilteredStaff() {
    List<Staff> filtered = isSuperAdmin
        ? _controller.allStaff
        : isBranchAdmin && userBranchName != null
        ? _controller.getStaffByBranch(userBranchName!)
        : [];

    // Apply role filter
    if (_selectedFilter.value != 'all' && _selectedFilter.value != 'active') {
      filtered = filtered.where((staff) =>
      staff.role.toLowerCase() == _selectedFilter.value.toLowerCase() ||
          staff.staffType.toLowerCase().contains(_selectedFilter.value.toLowerCase())
      ).toList();
    }

    if (_selectedFilter.value == 'active') {
      filtered = filtered.where((staff) {
        final isActive = staff.status == 'active' ||
            staff.isActive == true;
        return isActive;
      }).toList();
    }

    // Apply branch filter (for super admin only)
    if (isSuperAdmin && _selectedBranch.value != 'all') {
      filtered = filtered.where((staff) =>
      staff.branch == _selectedBranch.value
      ).toList();
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((staff) =>
      staff.name.toLowerCase().contains(query) ||
          staff.role.toLowerCase().contains(query) ||
          staff.branch.toLowerCase().contains(query) ||
          staff.specialtiesText.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Obx(() {
          final filteredStaff = getFilteredStaff();
          return Text(
            isSuperAdmin ? 'All Staff (${filteredStaff.length})'
                : isBranchAdmin ? 'Branch Staff (${filteredStaff.length})'
                : 'Staff (${filteredStaff.length})',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          );
        }),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _controller.refreshStaff();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Obx(() {
            final isLoading = _controller.isLoading.value;
            final allStaff = _controller.allStaff;

            // Show loading state when initially loading and no data
            if (isLoading && allStaff.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGold),
                    SizedBox(height: AppSizes.spaceMedium16),
                    Text(
                      'Loading staff...',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredStaff = getFilteredStaff();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: _buildSearchBar(isLandscape),
                ),

                // Branch Filter (for super admin only)
                if (isSuperAdmin)
                  SliverToBoxAdapter(
                    child: _buildBranchFilter(isLandscape),
                  ),

                // Filter Chips
                SliverToBoxAdapter(
                  child: _buildFilterChips(isLandscape),
                ),

                // Statistics
                SliverToBoxAdapter(
                  child: _buildStatistics(isLandscape),
                ),

                // Content (Empty or List)
                if (filteredStaff.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final staff = filteredStaff[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < filteredStaff.length - 1 ? AppSizes.spaceSmall8 : 0),
                            child: StaffCard(
                              staff: staff,
                              onTap: () {
                                Get.to(
                                        () => AdminStaffDetailsScreen(staffId: staff.id)
                                );
                              },
                              showStatus: true,
                              showBranch: true,
                              compact: false,
                            ),
                          );
                        },
                        childCount: filteredStaff.length,
                      ),
                    ),
                  ),

                // Bottom spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSizes.spaceMedium16),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isLandscape) {
    return Container(
      padding: AppSizes.paddingAll(isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceMedium16),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: isLandscape ? AppSizes.height(40) : AppSizes.height(48),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  SizedBox(width: AppSizes.width(16)),
                  Icon(
                    Icons.search,
                    size: isLandscape ? AppSizes.iconSmall18 : AppSizes.icon(20),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: AppSizes.width(12)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchQuery.value = value;
                      },
                      decoration: InputDecoration(
                        hintText: isLandscape ? 'Search...' : 'Search staff...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textMedium14,
                          color: Colors.grey[500],
                        ),
                      ),
                      style: TextStyle(
                        fontSize: isLandscape ? AppSizes.textSmall12 : AppSizes.textMedium14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (_searchQuery.value.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: AppSizes.iconSmall18),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery.value = '';
                      },
                    ),
                  SizedBox(width: AppSizes.width(8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchFilter(bool isLandscape) {
    if (!isSuperAdmin) return const SizedBox();

    final branches = _controller.allStaff
        .map((staff) => staff.branch)
        .where((branch) => branch.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (branches.isEmpty) return const SizedBox();

    branches.insert(0, 'all');

    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: branches.map((branch) {
            final displayName = branch == 'all' ? 'All Branches' : branch;
            final isSelected = _selectedBranch.value == branch;
            return Padding(
              padding: EdgeInsets.only(right: AppSizes.width(8)),
              child: ChoiceChip(
                label: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryGold,
                backgroundColor: Colors.grey[100],
                onSelected: (_) {
                  _selectedBranch.value = branch;
                },
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isLandscape) {
    final filters = _controller.filters;

    if (filters.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter.value == filter['value'];
            return Padding(
              padding: EdgeInsets.only(right: AppSizes.width(8)),
              child: ChoiceChip(
                label: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryGold,
                backgroundColor: Colors.grey[100],
                onSelected: (_) {
                  _selectedFilter.value = filter['value']!;
                },
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatistics(bool isLandscape) {
    final filteredStaff = getFilteredStaff();
    final activeStaff = filteredStaff.where((s) => s.isActive).length;
    final avgRating = filteredStaff.isNotEmpty
        ? (filteredStaff.fold(0.0, (sum, staff) => sum + staff.rating) /
        filteredStaff.length).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: AppSizes.paddingAll(isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceMedium16),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Showing',
            filteredStaff.length.toString(),
            AppColors.primaryGold,
            isLandscape,
          ),
          _buildStatItem(
            'Active',
            activeStaff.toString(),
            Colors.green,
            isLandscape,
          ),
          _buildStatItem(
            'Avg Rating',
            avgRating,
            Colors.blue,
            isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color, bool isLandscape) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppSizes.paddingAll(isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceSmall8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isLandscape ? AppSizes.font(16) : AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          SizedBox(height: isLandscape ? AppSizes.height(2) : AppSizes.height(4)),
          Text(
            title,
            style: TextStyle(
              fontSize: isLandscape ? AppSizes.font(10) : AppSizes.textSmall12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: AppSizes.iconLarge60,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            isSuperAdmin ? 'No staff found'
                : isBranchAdmin ? 'No staff in your branch'
                : 'No staff available',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
        ],
      ),
    );
  }
}