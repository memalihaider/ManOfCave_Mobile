import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/customer_controller.dart';
import '../../models/CustomerModel.dart';
import '../../widgets/shimmer_loading.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final CustomerController _customerController = Get.find<CustomerController>();
  final AuthController _authController = Get.find<AuthController>();

  // Filter states
  final RxString _selectedFilter = 'all'.obs; // all, active, inactive
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  // Role-based getters
  bool get isSuperAdmin => _authController.isSuperAdmin;
  bool get isBranchAdmin => _authController.isBranchAdmin;
  String? get branchName => _authController.getUserBranchName();
  String? get branchId => _authController.getUserBranchId();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    if (isBranchAdmin) {
      await _customerController.loadBranchCustomers();
    } else {
      await _customerController.loadAllCustomers();
    }
  }

  void _onSearchChanged() {
    _searchQuery.value = _searchController.text;
  }

  Future<void> _refreshCustomers() async {
    await _customerController.refreshCustomerData();
  }

  List<CustomerModel> _getFilteredCustomers() {
    List<CustomerModel> customers = _customerController.customers;

    // Apply status filter
    if (_selectedFilter.value == 'active') {
      customers = customers.where((c) => c.isActive).toList();
    } else if (_selectedFilter.value == 'inactive') {
      customers = customers.where((c) => !c.isActive).toList();
    }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      customers = customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query) ||
            customer.phone.contains(query);
      }).toList();
    }

    return customers;
  }

  void _toggleCustomerStatus(CustomerModel customer) async {
    final newStatus = !customer.isActive;
    final success = await _customerController.updateCustomerStatus(
      customer.uid,
      newStatus,
    );

    if (success && mounted) {
      Get.snackbar(
        'Success',
        'Customer ${customer.name} has been ${newStatus ? 'activated' : 'deactivated'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: newStatus ? Colors.green : Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showCustomerDetails(CustomerModel customer) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSizes.paddingAll(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: AppSizes.textExtraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: AppSizes.iconMedium24),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceMedium16),

                // Avatar and Name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryGold,
                        radius: AppSizes.radius(40),
                        child: Text(
                          customer.avatarInitials,
                          style: TextStyle(
                            fontSize: AppSizes.textExtraLarge22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.spaceLarge24),

                // Details Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.spaceSmall8,
                  mainAxisSpacing: AppSizes.spaceSmall8,
                  childAspectRatio: 2.5,
                  children: [
                    _buildDetailCard(
                      icon: Icons.phone,
                      title: 'Phone',
                      value: customer.phone,
                      color: Colors.blue,
                    ),
                    _buildDetailCard(
                      icon: Icons.person,
                      title: 'Role',
                      value: customer.role.toUpperCase(),
                      color: Colors.purple,
                    ),
                    _buildDetailCard(
                      icon: Icons.calendar_today,
                      title: 'Joined',
                      value: '${customer.accountAgeInDays} days ago',
                      color: Colors.green,
                    ),
                    _buildDetailCard(
                      icon: Icons.login,
                      title: 'Last Login',
                      value: customer.lastLoginDisplay,
                      color: Colors.orange,
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceMedium16),

                // Status and Verification
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: AppSizes.paddingAll(12),
                        decoration: BoxDecoration(
                          color: customer.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: customer.isActive ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: customer.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            Text(
                              customer.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.bold,
                                color: customer.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Container(
                        padding: AppSizes.paddingAll(12),
                        decoration: BoxDecoration(
                          color: customer.emailVerified
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: customer.emailVerified ? Colors.blue : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'EMAIL',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: customer.emailVerified ? Colors.blue : Colors.grey,
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceSmall8),
                            Text(
                              customer.emailVerified ? 'VERIFIED' : 'NOT VERIFIED',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.bold,
                                color: customer.emailVerified ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceMedium16),

                // Customer ID
                Container(
                  width: double.infinity,
                  padding: AppSizes.paddingAll(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer ID',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Text(
                        customer.uid,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.spaceLarge24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleCustomerStatus(customer),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: customer.isActive ? Colors.red : Colors.green,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          ),
                          padding: AppSizes.paddingSymmetric(vertical: 14),
                        ),
                        icon: Icon(
                          customer.isActive ? Icons.person_off : Icons.person_add,
                          size: AppSizes.iconSmall18,
                          color: customer.isActive ? Colors.red : Colors.green,
                        ),
                        label: Text(
                          customer.isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: customer.isActive ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.snackbar(
                            'Coming Soon',
                            'Customer activity view coming soon',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primaryGold,
                            colorText: Colors.white,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          ),
                          padding: AppSizes.paddingSymmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.visibility, size: AppSizes.iconSmall18),
                        label: Text(
                          'View Activity',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceMedium16),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppSizes.paddingAll(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.icon(20), color: color),
          SizedBox(width: AppSizes.width(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSizes.font(9),
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.height(2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final totalCustomers = _customerController.customers.length;
    final activeCustomers = _customerController.activeCustomers.length;
    final inactiveCustomers = totalCustomers - activeCustomers;

    return Container(
      padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Total', totalCustomers.toString(), AppColors.primaryGold),
          _buildStatItem('Active', activeCustomers.toString(), Colors.green),
          _buildStatItem('Inactive', inactiveCustomers.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: AppSizes.height(4)),
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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
          final count = _customerController.customers.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSuperAdmin ? 'All Customers' : 'Branch Customers',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              if (isBranchAdmin && branchName != null)
                Text(
                  branchName!,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: AppColors.white,
                  ),
                ),
            ],
          );
        }),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (_customerController.isLoading && _customerController.customers.isEmpty) {
          return _buildLoadingScreen();
        }

        final filteredCustomers = _getFilteredCustomers();

        return RefreshIndicator(
          onRefresh: _refreshCustomers,
          color: AppColors.primaryGold,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),

              // Statistics Bar
              SliverToBoxAdapter(
                child: _buildStatisticsBar(),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),

              // Customers List or Empty State
              if (filteredCustomers.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(_searchQuery.value.isNotEmpty),
                )
              else
                SliverPadding(
                  padding: AppSizes.paddingSymmetric(
                    vertical: AppSizes.spaceSmall8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final customer = filteredCustomers[index];
                        return _buildCustomerTile(customer);
                      },
                      childCount: filteredCustomers.length,
                    ),
                  ),
                ),

              // Bottom Spacing
              SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.spaceMedium16),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(width: AppSizes.width(12)),
            Icon(
              Icons.search,
              size: AppSizes.icon(20),
              color: Colors.grey[500],
            ),
            SizedBox(width: AppSizes.width(8)),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[500],
                  ),
                ),
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
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
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceSmall8,
      ),
      color: AppColors.white,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          SizedBox(width: AppSizes.width(8)),
          _buildFilterChip('Active', 'active'),
          SizedBox(width: AppSizes.width(8)),
          _buildFilterChip('Inactive', 'inactive'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter.value == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectedFilter.value = value,
        child: Container(
          padding: AppSizes.paddingSymmetric(
            vertical: AppSizes.spaceSmall8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.grey[100],
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerTile(CustomerModel customer) {
    return Padding(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceSmall8,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          side: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: ListTile(
          onTap: () => _showCustomerDetails(customer),
          contentPadding: AppSizes.paddingAll(12),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGold,
            radius: AppSizes.radius(22),
            child: Text(
              customer.avatarInitials,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          title: Text(
            customer.name,
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSizes.height(2)),
              Text(
                customer.email,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSizes.height(2)),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: AppSizes.icon(12),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: AppSizes.width(4)),
                  Text(
                    customer.phone,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.height(2),
                ),
                decoration: BoxDecoration(
                  color: customer.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  customer.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: AppSizes.font(8),
                    fontWeight: FontWeight.bold,
                    color: customer.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              Text(
                customer.lastLoginDisplay,
                style: TextStyle(
                  fontSize: AppSizes.font(8),
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceMedium16,
            vertical: AppSizes.spaceSmall8,
          ),
          child: Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.group_outlined,
            size: AppSizes.icon(80),
            color: Colors.grey[300],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            isSearching ? 'No matching customers' : 'No customers found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            isSearching
                ? 'Try adjusting your search or filters'
                : isBranchAdmin
                ? 'Customers will appear here once they book or order'
                : 'Customers will appear here once they register',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching)
            SizedBox(height: AppSizes.spaceMedium16),
          if (!isSearching)
            ElevatedButton.icon(
              onPressed: _refreshCustomers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
              icon: Icon(Icons.refresh, size: AppSizes.iconSmall18),
              label: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}