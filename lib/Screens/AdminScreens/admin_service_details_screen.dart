import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/service_controller.dart';
import '../../controlers/branches_controller.dart';
import '../../models/branch_model.dart';
import '../../models/service_model.dart';

class AdminServiceDetailScreen extends StatefulWidget {
  final String serviceId;

  const AdminServiceDetailScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<AdminServiceDetailScreen> createState() => _AdminServiceDetailScreenState();
}

class _AdminServiceDetailScreenState extends State<AdminServiceDetailScreen> {
  final ServiceController serviceController = Get.find<ServiceController>();
  final AuthController authController = Get.find<AuthController>();
  final BranchController branchController = Get.find<BranchController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceModel?>(
      future: serviceController.getServiceById(widget.serviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildNotFoundScreen();
        }

        final service = snapshot.data!;
        return _buildAdminServiceDetailScreen(service);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        centerTitle: true,
        title: Text(
          'Service Details',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        centerTitle: true,
        foregroundColor: AppColors.white,
        title: Text(
          'Service Not Found',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSizes.iconLarge60,
              color: Colors.grey[400],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Service not found',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminServiceDetailScreen(ServiceModel service) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          service.name,
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: AppSizes.height(80)), // Space for bottom bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Container(
              height: AppSizes.height(250),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge20),
                  bottomRight: Radius.circular(AppSizes.radiusLarge20),
                ),
                image: service.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(service.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: service.imageUrl.isEmpty
                  ? Center(
                child: Icon(
                  Icons.spa_outlined,
                  size: AppSizes.iconLarge60,
                  color: AppColors.primaryGold,
                ),
              )
                  : null,
            ),

            Padding(
              padding: AppSizes.paddingAll(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: TextStyle(
                            fontSize: AppSizes.textExtraLarge22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: AppSizes.paddingSymmetric(
                          horizontal: AppSizes.spaceSmall8,
                          vertical: AppSizes.spaceSmall8,
                        ),
                        decoration: BoxDecoration(
                          color: service.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: service.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          service.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.bold,
                            color: service.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),

                  // Category
                  Text(
                    service.category,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),

                  // Category ID Badge
                  Container(
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceSmall8,
                      vertical: AppSizes.spaceSmall8,
                    ),
                    decoration: BoxDecoration(
                      color: service.categoryId.isNotEmpty
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Text(
                      service.categoryId.isNotEmpty
                          ? 'CATEGORY ID: ${service.categoryId}'
                          : 'NO CATEGORY',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: service.categoryId.isNotEmpty ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSizes.spaceLarge24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: AppSizes.textLarge18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLarge24),

                  // Stats Card
                  Container(
                    padding: AppSizes.paddingAll(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Duration',
                                service.displayDuration,
                                Icons.access_time,
                                AppColors.primaryGold,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Price',
                                _formatPrice(service.price),
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Total Bookings',
                                '${service.totalBookings}',
                                Icons.calendar_today,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Total Revenue',
                                _formatPrice(service.revenue),
                                Icons.receipt,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        _buildStatItem(
                          'Avg. Revenue/Booking',
                          _formatPrice(service.averageRevenuePerBooking),
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLarge24),

                  // Branch Information
                  if (service.branches.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available at Branches',
                          style: TextStyle(
                            fontSize: AppSizes.textLarge18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceSmall8),
                        Wrap(
                          spacing: AppSizes.spaceSmall8,
                          runSpacing: AppSizes.spaceSmall8,
                          children: service.branchNames.map((branchName) {
                            return Container(
                              padding: AppSizes.paddingSymmetric(
                                horizontal: AppSizes.spaceMedium16,
                                vertical: AppSizes.spaceSmall8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                                border: Border.all(
                                  color: AppColors.primaryGold.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                branchName,
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  SizedBox(height: AppSizes.spaceLarge24),

                  // Admin Info
                  Container(
                    padding: AppSizes.paddingAll(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: AppSizes.iconMedium24,
                              color: Colors.blue,
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Text(
                              'Admin Information',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        _buildInfoRow('Service ID', service.id),
                        _buildInfoRow('Category ID', service.categoryId),
                        _buildInfoRow('Created', _formatDateTime(service.createdAt)),
                        _buildInfoRow('Last Updated', _formatDateTime(service.updatedAt)),
                        if (service.branches.isNotEmpty)
                          _buildInfoRow('Branch IDs', service.branches.join(', ')),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLarge24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAdminBottomBar(service),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: AppSizes.paddingAll(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconMedium24, color: color),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.width(100),
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBottomBar(ServiceModel service) {
    return Container(
      padding: AppSizes.paddingSymmetric(
        horizontal: AppSizes.spaceMedium16,
        vertical: AppSizes.spaceMedium16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Stats
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomStat('Price', _formatPrice(service.price)),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Bookings', '${service.totalBookings}'),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Revenue', _formatPrice(service.revenue)),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildBottomStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} ${AppStrings.appCurreny}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}