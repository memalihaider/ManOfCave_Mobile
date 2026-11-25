import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/branches_controller.dart';
import '../../models/branch_model.dart';
import '../../widgets/shimmer_loading.dart';

class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  final BranchController _branchController = Get.find<BranchController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranches();
    });
  }

  Future<void> _loadBranches() async {
    await _branchController.loadBranches();
  }

  Future<void> _refreshBranches() async {
    await _branchController.refreshBranches();
  }

  void _toggleBranchStatus(Branch branch) async {
    final newStatus = branch.isActive ? 'inactive' : 'active';
    final updatedBranch = branch.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    final success = await _branchController.updateBranch(
      branch.id,
      updatedBranch,
    );

    if (success && mounted) {
      setState(() {});
    }
  }

  void _showBranchDetails(Branch branch) {
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
                      'Branch Details',
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

                // Branch Icon and Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                        ),
                        child: Icon(
                          Icons.business,
                          size: AppSizes.icon(40),
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceMedium16),
                      Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: AppSizes.spaceSmall8),
                      Text(
                        '${branch.city}, ${branch.country}',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.spaceLarge24),

                // Location and Hours in Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: branch.city,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: _buildDetailCard(
                        icon: Icons.access_time,
                        title: 'Business Hours',
                        value: branch.businessHours,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSizes.spaceMedium16),

                // Phone and Email in Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: branch.phone,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: _buildDetailCard(
                        icon: Icons.email,
                        title: 'Email',
                        value: branch.email,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSizes.spaceMedium16),

                // Address Section
                Container(
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_city,
                        size: AppSizes.icon(20),
                        color: AppColors.primaryGold,
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSizes.height(4)),
                            Text(
                              branch.address,
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '${branch.city}, ${branch.country}',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.spaceMedium16),

                // Status and Hours Status
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                        decoration: BoxDecoration(
                          color: branch.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: branch.isActive ? Colors.green : Colors.red,
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
                                color: branch.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            SizedBox(height: AppSizes.height(4)),
                            Text(
                              branch.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.bold,
                                color: branch.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Container(
                        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                        decoration: BoxDecoration(
                          color: branch.isOpenNow()
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: branch.isOpenNow() ? Colors.blue : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'HOURS',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                fontWeight: FontWeight.w600,
                                color: branch.isOpenNow() ? Colors.blue : Colors.orange,
                              ),
                            ),
                            SizedBox(height: AppSizes.height(4)),
                            Text(
                              branch.isOpenNow() ? 'OPEN NOW' : 'CLOSED',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.bold,
                                color: branch.isOpenNow() ? Colors.blue : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceMedium16),

                // Manager Information
                if (branch.managerName != null || branch.managerEmail != null || branch.managerPhone != null)
                  Container(
                    padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: AppSizes.icon(16),
                              color: Colors.blue,
                            ),
                            SizedBox(width: AppSizes.width(8)),
                            Text(
                              'Manager Information',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceSmall8),
                        if (branch.managerName != null)
                          _buildManagerDetail('Name', branch.managerName!),
                        if (branch.managerEmail != null)
                          _buildManagerDetail('Email', branch.managerEmail!),
                        if (branch.managerPhone != null)
                          _buildManagerDetail('Phone', branch.managerPhone!),
                      ],
                    ),
                  ),
                if (branch.managerName != null || branch.managerEmail != null || branch.managerPhone != null)
                  SizedBox(height: AppSizes.spaceMedium16),

                // Description
                if (branch.description != null && branch.description!.isNotEmpty)
                  Container(
                    padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.height(4)),
                        Text(
                          branch.description!,
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (branch.description != null && branch.description!.isNotEmpty)
                  SizedBox(height: AppSizes.spaceMedium16),

                // Branch ID
                Container(
                  width: double.infinity,
                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Branch ID',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSizes.height(4)),
                      Text(
                        branch.id,
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
                        onPressed: () => _toggleBranchStatus(branch),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: branch.isActive ? Colors.red : Colors.green,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          ),
                          padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                        ),
                        icon: Icon(
                          branch.isActive ? Icons.close : Icons.check,
                          size: AppSizes.iconSmall18,
                          color: branch.isActive ? Colors.red : Colors.green,
                        ),
                        label: Text(
                          branch.isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: branch.isActive ? Colors.red : Colors.green,
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
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
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
                    fontSize: AppSizes.textSmall12,
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

  Widget _buildManagerDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.height(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
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
        title: Text(
          'Branches',
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBranches,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Obx(() {
            if (_branchController.isLoading.value && _branchController.branches.isEmpty) {
              return _buildLoadingScreen();
            }

            final branches = _branchController.branches;

            if (branches.isEmpty) {
              return _buildEmptyScreen();
            }

            return RefreshIndicator(
              onRefresh: _refreshBranches,
              color: AppColors.primaryGold,
              child: ListView.builder(
                padding: EdgeInsets.only(
                  top: AppSizes.spaceMedium16,
                  bottom: AppSizes.spaceLarge24,
                ),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return _buildBranchTile(branch, isLandscape);
                },
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildBranchTile(Branch branch, bool isLandscape) {
    return Padding(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceMedium16,
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
          onTap: () => _showBranchDetails(branch),
          contentPadding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          leading: Container(
            padding: AppSizes.paddingAll(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: Icon(
              Icons.business,
              size: AppSizes.iconMedium24,
              color: AppColors.white,
            ),
          ),
          title: Text(
            branch.name,
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
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: AppSizes.icon(12),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: AppSizes.width(4)),
                  Expanded(
                    child: Text(
                      '${branch.city}, ${branch.country}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.height(2)),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppSizes.icon(12),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: AppSizes.width(4)),
                  Text(
                    branch.businessHours,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
                  Expanded(
                    child: Text(
                      branch.phone,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (branch.managerName != null) ...[
                SizedBox(height: AppSizes.height(2)),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: AppSizes.icon(12),
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: AppSizes.width(4)),
                    Text(
                      branch.managerName!,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
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
                  color: branch.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  branch.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: AppSizes.font(8),
                    fontWeight: FontWeight.bold,
                    color: branch.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.height(2),
                ),
                decoration: BoxDecoration(
                  color: branch.isOpenNow()
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  branch.isOpenNow() ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    fontSize: AppSizes.font(8),
                    fontWeight: FontWeight.bold,
                    color: branch.isOpenNow() ? Colors.blue : Colors.orange,
                  ),
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
        padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceMedium16,
            vertical: AppSizes.spaceMedium16,
          ),
          child: Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: AppSizes.icon(80),
            color: Colors.grey[300],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'No branches found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            'Add branches to manage your locations',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          ElevatedButton.icon(
            onPressed: () {
              Get.snackbar(
                'Add Branch',
                'Add branch feature coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
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
            icon: Icon(Icons.add_business, size: AppSizes.iconSmall18),
            label: Text(
              'Add First Branch',
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