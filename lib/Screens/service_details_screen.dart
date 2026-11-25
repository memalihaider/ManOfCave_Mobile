import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/Screens/time_selection_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/auth_controller.dart';
import '../controlers/service_controller.dart';
import '../controlers/branches_controller.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../models/banner_model.dart';
import '../widgets/shimmer_loading.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final BannerItem? bannerDiscount;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.bannerDiscount,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceController serviceController = Get.find<ServiceController>();
  final AuthController authController = Get.find<AuthController>();
  final BranchController branchController = Get.find<BranchController>();

  final Rx<Branch?> _selectedBranch = Rx<Branch?>(null);
  final RxList<Branch> _availableBranches = <Branch>[].obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableBranches();
    });
  }

  Future<void> _loadAvailableBranches() async {
    final service = await serviceController.getServiceById(widget.serviceId);
    if (service != null) {
      final branches = <Branch>[];

      for (final branchName in service.branchNames) {
        Branch? foundBranch;
        for (var branch in branchController.branches) {
          if (branch.name == branchName || branch.id == branchName) {
            foundBranch = branch;
            break;
          }
        }
        if (foundBranch != null) {
          branches.add(foundBranch);
        }
      }

      _availableBranches.assignAll(branches);

      if (branches.isNotEmpty && _selectedBranch.value == null) {
        _selectedBranch.value = branches.first;
      }
    }
  }

  double _getDiscountedPrice(ServiceModel service) {
    if (widget.bannerDiscount != null && widget.bannerDiscount!.isValid) {
      if (widget.bannerDiscount!.discountType == 'percentage') {
        return service.price * (1 - widget.bannerDiscount!.discountValue / 100);
      } else {
        return (service.price - widget.bannerDiscount!.discountValue).clamp(0, service.price);
      }
    }
    return service.price;
  }

  bool _isBannerApplicable(ServiceModel service) {
    if (widget.bannerDiscount == null) return false;
    return widget.bannerDiscount!.isApplicableToService(service.id);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} ${AppStrings.appCurreny}';
  }

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
        return _buildServiceDetailScreen(service);
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
      body: ShimmerLoading(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 250.h,
                width: double.infinity,
                color: Colors.white,
              ),
              Padding(
                padding: AppSizes.paddingAll(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 250.w, height: 28.h, color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(width: 150.w, height: 16.h, color: Colors.white),
                    SizedBox(height: 24.h),
                    Container(width: double.infinity, height: 150.h, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
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
        child: Padding(
          padding: AppSizes.paddingAll(16),
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDetailScreen(ServiceModel service) {
    final discountedPrice = _getDiscountedPrice(service);
    final isBannerApplicable = _isBannerApplicable(service);
    final hasBranches = _availableBranches.isNotEmpty;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
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
                      SizedBox(width: AppSizes.spaceSmall8),
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

                  // Banner Badge
                  if (isBannerApplicable) ...[
                    SizedBox(height: AppSizes.spaceSmall8),
                    Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.spaceSmall8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: AppSizes.iconSmall14,
                            color: Colors.green,
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Text(
                            '${widget.bannerDiscount!.discountDisplay} OFF',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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

                  // Duration
                  Container(
                    padding: AppSizes.paddingAll(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: AppSizes.iconSmall18,
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: AppSizes.spaceMedium16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                service.displayDuration,
                                style: TextStyle(
                                  fontSize: AppSizes.textMedium14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLarge24),

                  // Branch Selection
                  if (hasBranches) _buildBranchSelectionSection(),
                  if (!hasBranches) _buildNoBranchesMessage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(service, discountedPrice, isBannerApplicable, hasBranches),
    );
  }

  Widget _buildBranchSelectionSection() {
    return Obx(() {
      if (_availableBranches.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Branch',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _availableBranches.map((branch) {
                final isSelected = _selectedBranch.value?.id == branch.id;
                return Padding(
                  padding: EdgeInsets.only(right: AppSizes.spaceSmall8),
                  child: FilterChip(
                    label: Text(branch.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _selectedBranch.value = branch;
                      } else {
                        _selectedBranch.value = null;
                      }
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryGold.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryGold,
                    labelStyle: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: isSelected ? AppColors.primaryGold : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    padding: AppSizes.paddingSymmetric(
                      horizontal: AppSizes.spaceMedium16,
                      vertical: AppSizes.spaceSmall8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_selectedBranch.value != null)
            Padding(
              padding: EdgeInsets.only(top: AppSizes.spaceSmall8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AppSizes.icon(16),
                    color: AppColors.success,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedBranch.value!.name}',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildNoBranchesMessage() {
    return Container(
      padding: AppSizes.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppSizes.iconMedium24,
            color: Colors.orange,
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Text(
              'This service is currently not available at any branch',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      ServiceModel service,
      double discountedPrice,
      bool isBannerApplicable,
      bool hasBranches,
      ) {
    return Obx(() {
      final selectedBranch = _selectedBranch.value;
      final canBook = service.isActive && hasBranches && selectedBranch != null;

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
          children: [
            // Price Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBannerApplicable) ...[
                    Text(
                      _formatPrice(discountedPrice),
                      style: TextStyle(
                        fontSize: AppSizes.textExtraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    Text(
                      _formatPrice(service.price),
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ] else
                    Text(
                      _formatPrice(service.price),
                      style: TextStyle(
                        fontSize: AppSizes.textExtraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  Text(
                    'Available at ${_availableBranches.length} location${_availableBranches.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!service.isActive)
                    Text(
                      'Currently unavailable',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (!hasBranches)
                    Text(
                      'No branches available',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.spaceMedium16),

            // Book Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: canBook
                    ? () {
                  Get.to(() => TimeSelectionScreen(
                    serviceId: service.id,
                    serviceName: service.name,
                    serviceDuration: service.duration,
                    servicePrice: discountedPrice,
                    branchName: selectedBranch!.name,
                    branchAddress: selectedBranch.fullAddress,
                  ));
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBook
                      ? AppColors.primaryGold
                      : Colors.grey[300],
                  foregroundColor: canBook
                      ? AppColors.white
                      : Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  elevation: 0,
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceMedium16,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppSizes.icon(18),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Text(
                        !service.isActive
                            ? 'Unavailable'
                            : !hasBranches
                            ? 'No Branches'
                            : selectedBranch == null
                            ? 'Select Branch'
                            : 'Book Now',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}