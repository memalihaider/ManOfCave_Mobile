// screens/banner_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/banner_model.dart';
import '../models/service_model.dart';
import '../models/product_model.dart';
import '../controlers/service_controller.dart';
import '../controlers/product_controller.dart';
import '../widgets/service_card.dart';
import '../widgets/product_card.dart';
import 'service_details_screen.dart';
import 'product_details_screen.dart';

class BannerDetailScreen extends StatefulWidget {
  final BannerItem banner;

  const BannerDetailScreen({super.key, required this.banner});

  @override
  State<BannerDetailScreen> createState() => _BannerDetailScreenState();
}

class _BannerDetailScreenState extends State<BannerDetailScreen> {
  final ServiceController serviceController = Get.find<ServiceController>();
  final ProductController productController = Get.find<ProductController>();

  late RxList<ServiceModel> applicableServices = <ServiceModel>[].obs;
  late RxList<Product> applicableProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadApplicableItems();
  }

  Future<void> _loadApplicableItems() async {
    isLoading.value = true;

    try {
      // Load applicable services
      if (widget.banner.isServiceOffer) {
        final services = serviceController.services
            .where((service) => widget.banner.isApplicableToService(service.id))
            .toList();
        applicableServices.assignAll(services);
      }

      // Load applicable products
      if (widget.banner.isProductOffer) {
        final products = productController.products
            .where((product) => widget.banner.isApplicableToProduct(product.id))
            .toList();
        applicableProducts.assignAll(products);
      }
    } catch (e) {
      print('Error loading applicable items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        title: Text(
          'Special Offer',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGold,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.spaceMedium16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              Container(
                width: double.infinity,
                height: AppSizes.height(200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  image: DecorationImage(
                    image: NetworkImage(widget.banner.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: AppSizes.spaceMedium16),

              // Offer Details Card
              Container(
                padding: EdgeInsets.all(AppSizes.spaceMedium16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withOpacity(0.1),
                      AppColors.primaryGold.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceSmall8,
                            vertical: AppSizes.spaceSmall8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSmall6,
                            ),
                          ),
                          child: Text(
                            widget.banner.discountDisplay,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          widget.banner.offerType.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppSizes.spaceMedium16),

                    Text(
                      widget.banner.title,
                      style: TextStyle(
                        fontSize: AppSizes.textExtraLarge22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    SizedBox(height: AppSizes.spaceSmall8),

                    Text(
                      widget.banner.description,
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: AppSizes.spaceMedium16),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppSizes.iconSmall14,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          'Valid: ${widget.banner.validityPeriod}',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                    if (widget.banner.usageLimit != null) ...[
                      SizedBox(height: AppSizes.spaceSmall8),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: AppSizes.iconSmall14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Text(
                            '${widget.banner.usedCount}/${widget.banner.usageLimit} used',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: AppSizes.spaceLarge24),

              // Applicable Services Section
              if (applicableServices.isNotEmpty) ...[
                _buildSectionHeader(
                  'Applicable Services',
                  applicableServices.length,
                ),
                SizedBox(height: AppSizes.spaceMedium16),
                ...applicableServices.map((service) => Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
                  child: _buildDiscountedServiceCard(service),
                )),
                SizedBox(height: AppSizes.spaceLarge24),
              ],

              // Applicable Products Section
              if (applicableProducts.isNotEmpty) ...[
                _buildSectionHeader(
                  'Applicable Products',
                  applicableProducts.length,
                ),
                SizedBox(height: AppSizes.spaceMedium16),
                ...applicableProducts.map((product) => Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
                  child: _buildDiscountedProductCard(product),
                )),
              ],

              if (applicableServices.isEmpty && applicableProducts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppSizes.iconLarge60,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: AppSizes.spaceMedium16),
                      Text(
                        'No applicable items found',
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'This offer may not be available at the moment',
                        style: TextStyle(
                          fontSize: AppSizes.textMedium14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
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

  Widget _buildDiscountedServiceCard(ServiceModel service) {
    final discountedPrice = _calculateDiscountedPrice(service.price);
    final savings = service.price - discountedPrice;

    return InkWell(
      onTap: () {
        Get.to(() => ServiceDetailScreen(
          serviceId: service.id,
          bannerDiscount: widget.banner,
        ));
      },
      child: Container(
        padding: EdgeInsets.all(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              child: Container(
                width: AppSizes.width(70),
                height: AppSizes.height(70),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Image.network(
                  service.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.spa,
                        size: AppSizes.iconMedium24,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(width: AppSizes.spaceMedium16),

            // Service Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSizes.spaceSmall8),

                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSizes.spaceSmall8),

                  // Price with discount
                  Row(
                    children: [
                      Text(
                        '\$${discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),

                  // Savings badge
                  if (savings > 0) ...[
                    SizedBox(height: AppSizes.spaceSmall8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall6,
                        ),
                      ),
                      child: Text(
                        'Save \$${savings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountedProductCard(Product product) {
    final discountedPrice = _calculateDiscountedPrice(product.price);
    final savings = product.price - discountedPrice;

    return InkWell(
      onTap: () {
        Get.to(() => ProductDetailScreen(
          productId: product.id,
          bannerDiscount: widget.banner,
        ));
      },
      child: Container(
        padding: EdgeInsets.all(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              child: Container(
                width: AppSizes.width(70),
                height: AppSizes.height(70),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.shopping_bag,
                        size: AppSizes.iconMedium24,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(width: AppSizes.spaceMedium16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSizes.spaceSmall8),

                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSizes.spaceSmall8),

                  // Price with discount
                  Row(
                    children: [
                      Text(
                        '\$${discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      SizedBox(width: AppSizes.spaceSmall8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),

                  // Savings badge
                  if (savings > 0) ...[
                    SizedBox(height: AppSizes.spaceSmall8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall6,
                        ),
                      ),
                      child: Text(
                        'Save \$${savings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDiscountedPrice(double originalPrice) {
    if (widget.banner.discountType == 'percentage') {
      return originalPrice * (1 - widget.banner.discountValue / 100);
    } else {
      return (originalPrice - widget.banner.discountValue).clamp(0, originalPrice);
    }
  }
}