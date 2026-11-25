import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/service_controller.dart';
import '../controlers/product_controller.dart';
import '../models/branch_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import '../widgets/service_card.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'service_details_screen.dart';
import 'product_details_screen.dart';

class BranchDetailScreen extends StatefulWidget {
  final Branch branch;

  const BranchDetailScreen({
    super.key,
    required this.branch,
  });

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServiceController serviceController = Get.find<ServiceController>();
  final ProductController productController = Get.find<ProductController>();

  final ScrollController _serviceScrollController = ScrollController();
  final ScrollController _productScrollController = ScrollController();

  final RxBool _isServicesLoading = true.obs;
  final RxBool _isProductsLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _serviceScrollController.addListener(() => _onScroll(_serviceScrollController, isService: true));
    _productScrollController.addListener(() => _onScroll(_productScrollController, isService: false));

    // Initialize data with branch filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Services
    _isServicesLoading.value = true;
    serviceController.updateFilters(branch: widget.branch.name);
    await serviceController.loadServicesPaginated(isRefresh: true);
    _isServicesLoading.value = false;

    // Products
    _isProductsLoading.value = true;
    productController.updateFilters(branch: widget.branch.name);
    await productController.loadProductsPaginated(isRefresh: true);
    _isProductsLoading.value = false;
  }

  void _onScroll(ScrollController controller, {required bool isService}) {
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      if (isService) {
        serviceController.loadServicesPaginated();
      } else {
        productController.loadProductsPaginated();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceScrollController.dispose();
    _productScrollController.dispose();
    // Reset filters to avoid affecting other screens
    serviceController.resetFilters();
    productController.resetFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Header with Cinematic Image
          SliverAppBar(
            expandedHeight: 320.h,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.branch.name.toUpperCase(),
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.branch.image ?? 'https://manofcave.ae/wp-content/uploads/2024/01/hero-bg.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Dark Gradient Overlay for cinematic feel
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Luxury Branch Info
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSizes.paddingAll(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: widget.branch.isOpenNow() ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      widget.branch.isOpenNow() ? 'OPEN NOW' : 'CLOSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Location and Phone in organized rows
                  _buildIconDetailRow(Icons.location_on, 'LOCATION', widget.branch.fullAddress),
                  SizedBox(height: 20.h),
                  _buildIconDetailRow(Icons.phone, 'PHONE', widget.branch.phone),
                  
                  if (widget.branch.description != null) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'THE STUDIO',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.branch.description!,
                      style: TextStyle(
                        fontSize: 13.sp, 
                        color: Colors.grey[600], 
                        height: 1.6,
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),
                  
                  // Weekly Schedule Section
                  Text(
                    'OPENING HOURS',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildWeeklySchedule(),
                  
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),

          // 3. Sticky Luxury Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryGold,
                indicatorWeight: 3,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 13.sp,
                  letterSpacing: 1,
                ),
                tabs: const [
                  Tab(text: 'SERVICES'),
                  Tab(text: 'PRODUCTS'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Services List
                _buildServiceList(),
                // Products List
                _buildProductList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return Obx(() {
      if (_isServicesLoading.value) {
        return _buildShimmerGrid();
      }

      final services = serviceController.paginatedServices;
      if (services.isEmpty) {
        return _buildEmptyState('No services available at this branch');
      }

      return Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _serviceScrollController,
              padding: AppSizes.paddingAll(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.75,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(
                  service: service,
                  onTap: () => Get.to(() => ServiceDetailScreen(serviceId: service.id)),
                );
              },
            ),
          ),
          if (serviceController.isLoadMoreLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
            ),
        ],
      );
    });
  }

  Widget _buildProductList() {
    return Obx(() {
      if (_isProductsLoading.value) {
        return _buildShimmerGrid();
      }

      final products = productController.paginatedProducts;
      if (products.isEmpty) {
        return _buildEmptyState('No products available at this branch');
      }

      return Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _productScrollController,
              padding: AppSizes.paddingAll(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Get.to(() => ProductDetailScreen(productId: product.id)),
                );
              },
            ),
          ),
          if (productController.isLoadMoreLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
            ),
        ],
      );
    });
  }

  Widget _buildShimmerGrid() {
    return ShimmerLoading(
      child: GridView.builder(
        padding: AppSizes.paddingAll(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp, 
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule() {
    final schedule = widget.branch.weeklySchedule;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final dayKey = dayKeys[index];
          final hours = schedule[dayKey] ?? 'Closed';
          final isToday = DateTime.now().weekday - 1 == (index == 6 ? 6 : index); // Adjusted for Sunday=7 in dart vs 6 index

          // Correct index for Sunday: DateTime.now().weekday is 1-7 (Mon-Sun)
          final bool isActualToday = DateTime.now().weekday == (index + 1);

          return Padding(
            padding: EdgeInsets.only(bottom: index < days.length - 1 ? 10.h : 0),
            child: Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: isActualToday ? AppColors.primaryGold : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isActualToday ? FontWeight.w900 : FontWeight.w500,
                    color: isActualToday ? AppColors.primaryDark : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  hours,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isActualToday ? FontWeight.w900 : FontWeight.w600,
                    color: isActualToday ? AppColors.primaryGold : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
