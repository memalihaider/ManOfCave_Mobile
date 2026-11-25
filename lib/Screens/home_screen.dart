import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:man_of_cave/Screens/product_details_screen.dart';
import 'package:man_of_cave/Screens/service_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/auth_controller.dart';
import '../controlers/banner_controller.dart';
import '../controlers/branches_controller.dart';
import '../controlers/category_controller.dart';
import '../controlers/customer_controller.dart';
import '../controlers/loyalty_points_controller.dart';
import '../controlers/product_controller.dart';
import '../controlers/service_controller.dart';
import '../controlers/promo_code_controller.dart';
import '../models/branch_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import '../widgets/categories_section.dart';
import '../widgets/product_card.dart';
import '../widgets/promo_code_card.dart';
import '../widgets/promotion_banner.dart';
import '../widgets/referral_code.dart';
import '../widgets/service_card.dart';
import '../widgets/branch_card.dart';
import '../widgets/staff_card.dart';
import 'all_category_screen.dart';
import 'branch_detail_screen.dart';
import 'all_product_screen.dart';
import 'all_services_screen.dart';
import 'chats/chat_list_screen.dart';
import 'location_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  /// When true, chrome (app bar / FAB) is provided by [CustomerShell].
  final bool embedded;

  const HomeScreen({super.key, this.embedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BranchController branchController = Get.find<BranchController>();
  final BannerController bannerController = Get.find<BannerController>();
  final ServiceController serviceController = Get.find<ServiceController>();
  final ProductController productController = Get.find<ProductController>();
  final LoyaltyController loyaltyController = Get.find<LoyaltyController>();
  final AuthController authController = Get.find<AuthController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final PromoCodeController promoCodeController = Get.find<PromoCodeController>();
  final CategoryController categoryController = Get.find<CategoryController>();

  // Branch filter
  Branch? _selectedBranch;
  List<Branch> _availableBranches = [];

  // Search related controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();

  bool _hasCheckedRewards = false;
  bool _isInitialDataLoaded = false;
  bool _isCheckingRewards = false;
  bool _hasShownRewardsDialog = false;
  bool _hasShownReferralDialog = false; // Add referral dialog flag

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (mounted) {
      setState(() => _isInitialDataLoaded = false);
    }

    // Parallel catalog loads — each has its own timeout via SafeFirestore.
    final catalogLoad = Future.wait([
      branchController.loadBranches(),
      categoryController.loadCategories(),
      bannerController.loadBanners(),
      serviceController.loadServices(),
      productController.loadProducts(),
      promoCodeController.loadPromoCodes(),
    ]).catchError((e) {
      print('Error during data initialization: $e');
      return <void>[];
    });

    // Never leave the home shimmer up more than a few seconds.
    await Future.any([
      catalogLoad,
      Future.delayed(const Duration(seconds: 4)),
    ]);

    if (!mounted) return;
    _loadAvailableBranches();
    setState(() => _isInitialDataLoaded = true);

    // Finish any remaining network work, then refresh lists.
    unawaited(catalogLoad.then((_) {
      if (!mounted) return;
      _loadAvailableBranches();
      setState(() {});
      if (!_hasCheckedRewards && !_isCheckingRewards) {
        _checkForPendingRewards();
      }
    }));
  }

  // // Check and show referral dialog for logged-in customers
  // Future<void> _checkAndShowReferralDialog() async {
  //   // Only proceed if user is logged in
  //   if (!authController.isLoggedIn.value) {
  //     print('⚠️ No user logged in, skipping referral dialog');
  //     return;
  //   }
  //
  //   // Only show for customers (not admins)
  //   if (!authController.isCustomer) {
  //     print('⚠️ User is not a customer (${authController.formattedRole}), skipping referral dialog');
  //     return;
  //   }
  //
  //   // Only show once
  //   if (_hasShownReferralDialog) {
  //     print('⚠️ Referral dialog already shown, skipping');
  //     return;
  //   }
  //
  //   // Wait a bit for data to load
  //   await Future.delayed(const Duration(milliseconds: 800));
  //
  //   final user = authController.currentUser.value;
  //   if (user == null) {
  //     print('⚠️ No user data found, skipping referral dialog');
  //     return;
  //   }
  //
  //   try {
  //     // Check if user has a referral code from Firestore
  //     final customerDoc = await FirebaseFirestore.instance
  //         .collection('customers')
  //         .doc(user.uid)
  //         .get();
  //
  //     if (customerDoc.exists) {
  //       final data = customerDoc.data()!;
  //       final referralCode = data['referralCode'] as String?;
  //
  //       print('📱 Customer referral code: $referralCode');
  //
  //       // Only show if user has a referral code and hasn't seen the dialog
  //       if (referralCode != null && referralCode.isNotEmpty && !_hasShownReferralDialog) {
  //         // Check if we've already shown the dialog before (store in shared preferences)
  //         final prefs = await SharedPreferences.getInstance();
  //         final hasSeenReferral = prefs.getBool('referral_dialog_${user.uid}') ?? false;
  //
  //         if (!hasSeenReferral) {
  //           _hasShownReferralDialog = true;
  //
  //           // Show dialog after a short delay
  //           Future.delayed(const Duration(milliseconds: 500), () {
  //             if (mounted) {
  //               showDialog(
  //                 context: context,
  //                 barrierDismissible: false,
  //                 builder: (context) => ReferralDialog(
  //                   referralCode: referralCode,
  //                   userName: user.name,
  //                 ),
  //               );
  //
  //               // Mark as seen
  //               prefs.setBool('referral_dialog_${user.uid}', true);
  //               print('✅ Referral dialog shown for user: ${user.name}');
  //             }
  //           });
  //         } else {
  //           print('⚠️ Referral dialog already shown before for user: ${user.name}');
  //         }
  //       } else {
  //         print('⚠️ No referral code found for user: ${user.name}');
  //       }
  //     } else {
  //       print('⚠️ Customer document not found for user: ${user.uid}');
  //     }
  //   } catch (e) {
  //     print('❌ Error checking referral dialog: $e');
  //   }
  // }

  void _loadAvailableBranches() {
    // Get unique branches from services and products
    final branchSet = <Branch>{};

    // Add branches from services
    for (final service in serviceController.services) {
      for (final branchName in service.branchNames) {
        final branch = branchController.branches.firstWhereOrNull(
                (b) => b.name == branchName || b.id == branchName
        );
        if (branch != null) {
          branchSet.add(branch);
        }
      }
    }

    // Add branches from products
    for (final product in productController.products) {
      for (final branchName in product.branchNames) {
        final branch = branchController.branches.firstWhereOrNull(
                (b) => b.name == branchName || b.id == branchName
        );
        if (branch != null) {
          branchSet.add(branch);
        }
      }
    }

    if (mounted) {
      setState(() {
        _availableBranches = branchSet.toList()..sort((a, b) => a.name.compareTo(b.name));
      });
    }
  }

  List<ServiceModel> get _filteredServices {
    if (_selectedBranch == null) {
      return serviceController.featuredServices;
    }

    return serviceController.services.where((service) {
      return service.isActive &&
          (service.branchNames.contains(_selectedBranch!.name) ||
              service.branches.contains(_selectedBranch!.id));
    }).take(6).toList();
  }

  List<Product> get _filteredProducts {
    if (_selectedBranch == null) {
      return productController.featuredProducts;
    }

    return productController.products.where((product) {
      return product.inStock &&
          (product.branchNames.contains(_selectedBranch!.name) ||
              product.branches.contains(_selectedBranch!.id));
    }).take(6).toList();
  }

  void _resetBranchFilter() {
    setState(() {
      _selectedBranch = null;
    });
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      final lowercaseQuery = query.toLowerCase();
      final List<SearchResult> results = [];

      // Get base lists based on branch filter
      final servicesToSearch = _selectedBranch == null
          ? serviceController.services
          : serviceController.services.where((service) =>
      service.branchNames.contains(_selectedBranch!.name) ||
          service.branches.contains(_selectedBranch!.id)
      ).toList();

      final productsToSearch = _selectedBranch == null
          ? productController.products
          : productController.products.where((product) =>
      product.branchNames.contains(_selectedBranch!.name) ||
          product.branches.contains(_selectedBranch!.id)
      ).toList();

      // Search in services
      final services = servicesToSearch.where((service) {
        return service.name.toLowerCase().contains(lowercaseQuery) ||
            service.description.toLowerCase().contains(lowercaseQuery) ||
            (service.category.toLowerCase().contains(lowercaseQuery));
      }).toList();

      for (var service in services) {
        results.add(SearchResult(
          id: service.id,
          title: service.name,
          subtitle: service.description,
          imageUrl: service.imageUrl,
          type: 'service',
          originalItem: service,
          price: service.price,
        ));
      }

      // Search in products
      final products = productsToSearch.where((product) {
        return product.name.toLowerCase().contains(lowercaseQuery) ||
            product.description.toLowerCase().contains(lowercaseQuery) ||
            (product.category.toLowerCase().contains(lowercaseQuery));
      }).toList();

      for (var product in products) {
        results.add(SearchResult(
          id: product.id,
          title: product.name,
          subtitle: product.description,
          imageUrl: product.imageUrl,
          type: 'product',
          originalItem: product,
          price: product.price,
        ));
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showSearchResults = false;
    });
    _searchFocusNode.unfocus();
  }

  void _closeSearch() {
    setState(() {
      _showSearchResults = false;
    });
    _searchFocusNode.unfocus();
  }

  Future<void> _checkForPendingRewards() async {
    // Prevent multiple concurrent checks
    if (_isCheckingRewards) {
      print("⚠️ Already checking rewards, skipping");
      return;
    }

    if (_hasCheckedRewards) {
      print("⚠️ Rewards already checked, skipping");
      return;
    }

    try {
      _isCheckingRewards = true;
      final user = authController.currentUser;

      if (user != null) {
        print("🔍 Checking pending rewards for user: ${authController.currentUser.value?.name}");
        await Future.delayed(const Duration(milliseconds: 500));
        await loyaltyController.checkAndShowRewards();
        _hasCheckedRewards = true;
        print("✅ Rewards check completed");

        // After checking rewards, show dialog if there are pending rewards
        // Add a small delay to ensure UI is fully built
        if (loyaltyController.hasPendingRewards && !_hasShownRewardsDialog) {
          _hasShownRewardsDialog = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              loyaltyController.showRewardsConfirmationDialog();
            }
          });
        }
      } else {
        print("⚠️ No user logged in, skipping rewards check");
      }
    } catch (e) {
      print('❌ Error checking rewards: $e');
    } finally {
      _isCheckingRewards = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showSearchResults) {
          _closeSearch();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showSearchResults && _searchController.text.isEmpty) {
            _closeSearch();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldSoft,
          appBar: widget.embedded
              ? null
              : AppBar(
                  backgroundColor: AppColors.primaryGold,
                  title: Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.font(18),
                    ),
                  ),
                  centerTitle: false,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => Get.to(() => NotificationsScreen()),
                    ),
                  ],
                ),
          body: _buildBody(),
          floatingActionButton: widget.embedded
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    if (customerController.isAuthenticated) {
                      Get.to(() => ChatListScreen());
                    } else {
                      Get.snackbar(
                        'Sign in to chat',
                        'Create an account to message support',
                        backgroundColor: AppColors.primaryGold,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  child: const Icon(Icons.chat_bubble_rounded),
                ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Obx so sections appear as each catalog list fills (no stuck full-page shimmer).
    return Obx(() {
      final hasAnyData = branchController.branches.isNotEmpty ||
          categoryController.categories.isNotEmpty ||
          serviceController.services.isNotEmpty ||
          productController.products.isNotEmpty ||
          bannerController.banners.isNotEmpty;

      final stillBooting = !_isInitialDataLoaded && !hasAnyData;
      if (stillBooting) {
        return _buildHomeShimmer();
      }

      // Touch lengths so Obx rebuilds when lists change.
      final _ = (
        branchController.branches.length,
        bannerController.banners.length,
        categoryController.categories.length,
        serviceController.featuredServices.length,
        productController.featuredProducts.length,
        promoCodeController.activePromoCodes.length,
      );

      return Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(
                      'Studios',
                      'Find a branch near you',
                      () => Get.to(() => LocationsScreen()),
                    ),
                    SizedBox(height: 12.h),
                    _buildBranchesHorizontalList(),
                    SizedBox(height: 16.h),
                    _buildPromoCodesSection(),
                    SizedBox(height: 12.h),
                    if (bannerController.banners.isNotEmpty) ...[
                      PromotionBanner(banners: bannerController.banners.toList()),
                      SizedBox(height: 16.h),
                    ],
                    _buildCategoriesSection(),
                    SizedBox(height: 16.h),
                    _buildSectionHeader(
                      'Services',
                      'Book your next visit',
                      () => Get.to(() => AllServicesScreen()),
                    ),
                    SizedBox(height: 12.h),
                    _buildServicesHorizontalList(),
                    SizedBox(height: 16.h),
                    _buildSectionHeader(
                      'Products',
                      'Grooming essentials',
                      () => Get.to(() => AllProductsScreen()),
                    ),
                    SizedBox(height: 12.h),
                    _buildProductsHorizontalList(),
                    SizedBox(height: 24.h),
                  ]),
                ),
              ),
            ],
          ),
          if (_showSearchResults)
            Positioned.fill(
              child: Container(
                color: AppColors.white,
                child: _buildSearchResults(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildHomeShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.h,
            backgroundColor: Colors.white,
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section 1 (Branches)
                _buildShimmerSection(),
                SizedBox(height: 24.h),
                // Section 2
                _buildShimmerSection(),
                SizedBox(height: 24.h),
                // Section 3
                _buildShimmerSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 150.w,
          height: 20.h,
          color: Colors.white,
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (_, __) => Container(
              width: 150.w,
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, widget.embedded ? 12.h : 4.h, 16.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Man of Cave',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textInk,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Grooming, near you',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _roundIconBtn(
                    Icons.notifications_none_rounded,
                    () => Get.to(() => NotificationsScreen()),
                  ),
                  SizedBox(width: 8.w),
                  _roundIconBtn(
                    Icons.place_outlined,
                    () => Get.to(() => LocationsScreen()),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
            ],
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _roundIconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: Icon(icon, color: AppColors.textInk, size: 22.sp),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textInk,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGold,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          ),
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchesHorizontalList() {
    final branches = branchController.branches;
    if (branches.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: branches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: BranchCard(
              branch: branches[index],
              isCompact: true,
              onTap: () => Get.to(() => BranchDetailScreen(branch: branches[index])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesHorizontalList() {
    final services = serviceController.featuredServices;
    if (services.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SizedBox(
              width: 160.w,
              child: ServiceCard(
                service: services[index],
                onTap: () => Get.to(() => ServiceDetailScreen(serviceId: services[index].id)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsHorizontalList() {
    final products = productController.featuredProducts;
    if (products.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SizedBox(
              width: 160.w,
              child: ProductCard(
                product: products[index],
                onTap: () => Get.to(() => ProductDetailScreen(productId: products[index].id)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppColors.primaryGold.withValues(alpha: 0.45)
              : const Color(0xFFE8E4DE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w),
            child: Icon(
              Icons.search_rounded,
              size: 22.sp,
              color: _searchFocusNode.hasFocus
                  ? AppColors.primaryGold
                  : AppColors.textMuted,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search services & products',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textInk,
              ),
              onTap: () {
                setState(() {
                  _showSearchResults = true;
                });
              },
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: InkWell(
                onTap: _clearSearch,
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromoCodesSection() {
    final promos = promoCodeController.activePromoCodes;

    if (promos.isEmpty) {
      return const SizedBox();
    }

    final filteredPromos = _selectedBranch == null
        ? promos
        : promos.where((promo) {
      return promo.isApplicableToBranch(_selectedBranch!.id) ||
          promo.isApplicableToBranchName(_selectedBranch!.name);
    }).toList();

    if (filteredPromos.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.spaceSmall8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer,
                color: AppColors.primaryGold,
                size: AppSizes.iconMedium24,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Text(
                'Available Promo Codes',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.spaceSmall8),
          child: Row(
            children: filteredPromos.map((promo) {
              return Padding(
                padding: EdgeInsets.only(right: AppSizes.spaceSmall8),
                child: PromoCard(promo: promo),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    List<CategoryModel> categories;

    if (_selectedBranch == null) {
      // Use the new getter to show only categories with images on home screen
      categories = categoryController.categoriesWithImages;
    } else {
      final branchId = _selectedBranch!.id;
      final branchName = _selectedBranch!.name;

      // Filter by branch and also ensure it has an image
      categories = categoryController.categoriesWithImages
          .where((c) => 
          (c.isAvailableAtBranch(branchId) ||
              c.branchNames.contains(branchName)))
          .toList();
    }

    final displayCategories = categories.take(6).toList();

    if (displayCategories.isEmpty) return const SizedBox();

    return CategoriesSection(
      categories: displayCategories,
      onViewAll: () {
        Get.to(() => AllCategoriesScreen());
      },
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMedium16,
            vertical: AppSizes.spaceSmall8,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: AppSizes.iconMedium24,
                  color: AppColors.primaryDark,
                ),
                onPressed: _closeSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Expanded(
                child: Text(
                  _searchController.text,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  child: Text(
                    '${_searchResults.length}',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: _isSearching
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryGold,
                ),
                SizedBox(height: AppSizes.spaceMedium16),
                Text(
                  'Searching...',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
              : _searchResults.isEmpty
              ? _buildEmptySearchState()
              : _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.spaceMedium16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty ? Icons.search : Icons.search_off,
              size: AppSizes.iconLarge60,
              color: Colors.grey[300],
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              _searchController.text.isEmpty
                  ? 'Start searching'
                  : 'No results found',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              _searchController.text.isEmpty
                  ? 'Type to search services and products'
                  : 'Try searching with different keywords',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isNotEmpty) ...[
              SizedBox(height: AppSizes.spaceMedium16),
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceLarge24,
                    vertical: AppSizes.spaceMedium16,
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

  Widget _buildResultsList() {
    final services = _searchResults.where((r) => r.type == 'service').toList();
    final products = _searchResults.where((r) => r.type == 'product').toList();

    return ListView(
      padding: EdgeInsets.all(AppSizes.spaceMedium16),
      children: [
        if (services.isNotEmpty) ...[
          _buildResultSectionHeader('Services', services.length),
          SizedBox(height: AppSizes.spaceMedium16),
          ...services.map((result) => _buildSearchResultItem(result)),
        ],
        if (services.isNotEmpty && products.isNotEmpty)
          SizedBox(height: AppSizes.spaceLarge24),
        if (products.isNotEmpty) ...[
          _buildResultSectionHeader('Products', products.length),
          SizedBox(height: AppSizes.spaceMedium16),
          ...products.map((result) => _buildSearchResultItem(result)),
        ],
      ],
    );
  }

  Widget _buildResultSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(width: AppSizes.spaceSmall8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.spaceSmall8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return InkWell(
      onTap: () {
        _closeSearch();
        if (result.type == 'service') {
          Get.to(() => ServiceDetailScreen(serviceId: result.id));
        } else {
          Get.to(() => ProductDetailScreen(productId: result.id));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
        padding: EdgeInsets.all(AppSizes.spaceSmall8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              child: Container(
                width: AppSizes.width(70),
                height: AppSizes.height(70),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Image.network(
                  result.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        result.type == 'service'
                            ? Icons.spa
                            : Icons.shopping_bag,
                        size: AppSizes.iconMedium24,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: AppSizes.spaceSmall8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.spaceSmall8,
                          vertical: AppSizes.spaceSmall8,
                        ),
                        decoration: BoxDecoration(
                          color: result.type == 'service'
                              ? AppColors.primaryGold.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                        child: Text(
                          result.type == 'service' ? 'Service' : 'Product',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: result.type == 'service'
                                ? AppColors.primaryGold
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(result.price),
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} ${AppStrings.appCurreny}';
  }
}

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String type;
  final dynamic originalItem;
  final double price;
  final double? discountPrice;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.type,
    required this.originalItem,
    required this.price,
    this.discountPrice,
  });
}