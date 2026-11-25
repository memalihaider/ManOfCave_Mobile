import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../Screens/banner_details_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'dart:async';
import '../models/banner_model.dart';

class PromotionBanner extends StatefulWidget {
  final List<BannerItem> banners;
  final Function(BannerItem)? onBannerTap;

  const PromotionBanner({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(PromotionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          int nextPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(BannerItem banner) {
    if (!banner.isValid) return Colors.grey;
    if (banner.isServiceOffer) return Colors.blue;
    if (banner.isProductOffer) return Colors.green;
    return AppColors.primaryGold;
  }

  String _getBadgeText(BannerItem banner) {
    if (!banner.isValid) return 'Expired';
    if (banner.isServiceOffer) return 'Service Offer';
    if (banner.isProductOffer) return 'Product Offer';
    return 'Special Offer';
  }

  IconData _getOfferIcon(BannerItem banner) {
    if (banner.isServiceOffer) return Icons.spa;
    if (banner.isProductOffer) return Icons.shopping_bag;
    return Icons.local_offer;
  }

  List<Color> _getGradientColors(BannerItem banner) {
    if (!banner.isValid) {
      return [
        Colors.grey.withOpacity(0.7),
        Colors.grey.withOpacity(0.5),
      ];
    }

    if (banner.isServiceOffer) {
      return [
        Colors.blue.withOpacity(0.9),
        Colors.blue.withOpacity(0.7),
      ];
    }

    if (banner.isProductOffer) {
      return [
        Colors.green.withOpacity(0.9),
        Colors.green.withOpacity(0.7),
      ];
    }

    return [
      AppColors.primaryGold.withOpacity(0.9),
      AppColors.primaryGold.withOpacity(0.7),
    ];
  }

  void _onBannerTap(BannerItem banner, BuildContext context) {
    if (!banner.isValid) {
      Get.snackbar(
        'Offer Expired',
        'This offer is no longer valid',
        backgroundColor: AppColors.grey,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (widget.onBannerTap != null) {
      widget.onBannerTap!(banner);
    } else {
      Get.to(() => BannerDetailScreen(banner: banner));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > MediaQuery.of(context).size.height;

    // Responsive banner height based on orientation
    double bannerHeight = isLandscape
        ? AppSizes.height(180)
        : AppSizes.height(200);

    if (widget.banners.isEmpty) {
      return Container(
        height: bannerHeight,
        margin: EdgeInsets.symmetric(horizontal: AppSizes.width(4)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: AppSizes.icon(40),
                  color: Colors.grey[300],
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                Text(
                  'No offers available',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.spaceSmall8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: AppColors.primaryGold,
                size: AppSizes.iconMedium24,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Text(
                'Our Offers',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final isValid = banner.isValid;

              return GestureDetector(
                onTap: () => _onBannerTap(banner, context),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSizes.width(4)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                    gradient: banner.imageUrl.isEmpty
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getGradientColors(banner),
                    )
                        : null,
                    image: banner.imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(banner.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: banner.imageUrl.isNotEmpty
                        ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    )
                        : null,
                    child: Padding(
                      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: isLandscape ? 3 : 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Badge with offer type
                                Container(
                                  padding: AppSizes.paddingSymmetric(
                                    horizontal: AppSizes.spaceSmall8,
                                    vertical: AppSizes.height(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getOfferIcon(banner),
                                        size: AppSizes.icon(14),
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: AppSizes.width(4)),
                                      Text(
                                        _getBadgeText(banner),
                                        style: TextStyle(
                                          fontSize: AppSizes.font(10),
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppSizes.spaceSmall8),

                                // Discount Value
                                Container(
                                  padding: AppSizes.paddingSymmetric(
                                    horizontal: AppSizes.spaceSmall8,
                                    vertical: AppSizes.height(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                                  ),
                                  child: Text(
                                    banner.discountDisplay,
                                    style: TextStyle(
                                      fontSize: AppSizes.font(14),
                                      fontWeight: FontWeight.bold,
                                      color: _getBadgeColor(banner),
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSizes.spaceSmall8),

                                // Title
                                Text(
                                  banner.title,
                                  style: TextStyle(
                                    fontSize: isLandscape ? AppSizes.textMedium14 : AppSizes.textLarge18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: AppSizes.height(4)),

                                // Description (if exists)
                                if (banner.description.isNotEmpty) ...[
                                  Text(
                                    banner.description,
                                    style: TextStyle(
                                      fontSize: AppSizes.font(12),
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: AppSizes.height(4)),
                                ],

                                // Validity period
                                if (isValid)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: AppSizes.icon(12),
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      SizedBox(width: AppSizes.width(4)),
                                      Expanded(
                                        child: Text(
                                          banner.validityPeriod,
                                          style: TextStyle(
                                            fontSize: AppSizes.font(9),
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Offer Icon
                                Icon(
                                  _getOfferIcon(banner),
                                  size: isLandscape ? AppSizes.icon(40) : AppSizes.icon(50),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                SizedBox(height: AppSizes.height(4)),

                                // Applicable items count
                                Container(
                                  padding: AppSizes.paddingSymmetric(
                                    horizontal: AppSizes.spaceSmall8,
                                    vertical: AppSizes.height(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                                  ),
                                  child: Text(
                                    '${banner.applicableItemsCount} item${banner.applicableItemsCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: AppSizes.font(9),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
        SizedBox(height: AppSizes.spaceSmall8),

        // Page indicators
        if (widget.banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
                  (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: AppSizes.width(4)),
                  width: AppSizes.width(8),
                  height: AppSizes.height(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? _getBadgeColor(widget.banners[index])
                        : Colors.grey[300],
                    border: Border.all(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}