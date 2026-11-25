// screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/cart_controller.dart';
import '../controlers/product_controller.dart';
import '../controlers/auth_controller.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import '../widgets/shimmer_loading.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final BannerItem? bannerDiscount;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.bannerDiscount,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final CartController _cartController = Get.find<CartController>();
  final AuthController _authController = Get.find<AuthController>();

  int _quantity = 1;
  bool _isLoading = true;
  bool _isAddingToCart = false;

  final Rx<Product?> _product = Rx<Product?>(null);

  bool get isCustomer => _authController.isCustomer;

  double get _displayPrice {
    if (_product.value == null) return 0;

    if (widget.bannerDiscount != null && widget.bannerDiscount!.isValid) {
      if (widget.bannerDiscount!.discountType == 'percentage') {
        return _product.value!.price * (1 - widget.bannerDiscount!.discountValue / 100);
      } else {
        return (_product.value!.price - widget.bannerDiscount!.discountValue).clamp(0, _product.value!.price);
      }
    }
    return _product.value!.price;
  }

  bool get _isBannerApplicable {
    if (_product.value == null || widget.bannerDiscount == null) return false;
    return widget.bannerDiscount!.isApplicableToProduct(_product.value!.id);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} ${AppStrings.appCurreny}';
  }

  @override
  void initState() {
    super.initState();
    _initializeProduct();
  }

  @override
  void dispose() {
    _product.close();
    super.dispose();
  }

  void _initializeProduct() {
    final cachedProduct = _productController.products
        .firstWhereOrNull((p) => p.id == widget.productId);

    if (cachedProduct != null) {
      _product.value = cachedProduct;
      _isLoading = false;
    } else {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final loadedProduct = await _productController.getProductById(widget.productId);

      if (loadedProduct != null) {
        _product.value = loadedProduct;
      } else {
        _showErrorSnackbar('Product not found');
        Future.delayed(const Duration(milliseconds: 500), () => Get.back());
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load product: $e');
    } finally {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _addToCart() async {
    if (_product.value == null) {
      _showErrorSnackbar('Product not available');
      return;
    }

    if (!_product.value!.inStock) {
      _showErrorSnackbar('Product is out of stock');
      return;
    }

    if (_quantity < 1) {
      _showErrorSnackbar('Please select at least 1 item');
      return;
    }

    if (_quantity > _product.value!.totalStock) {
      _showErrorSnackbar(
        'Only ${_product.value!.totalStock} items available',
      );
      return;
    }

    _isAddingToCart = true;
    if (mounted) setState(() {});

    try {
      await _cartController.addToCart(
        _product.value!.id,
        _quantity,
      );

      setState(() {
        _quantity = 1;
      });

      Get.snackbar(
        'Added to Cart',
        '${_product.value!.name} added to cart',
        backgroundColor: AppColors.primaryGold,
        colorText: AppColors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () {
            Get.to(() => CartScreen());
          },
          child: Text(
            'View Cart',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );

    } catch (e) {
      _showErrorSnackbar('Failed to add to cart');
    } finally {
      _isAddingToCart = false;
      if (mounted) setState(() {});
    }
  }

  void _incrementQuantity() {
    if (_product.value != null && _product.value!.inStock) {
      if (_quantity < _product.value!.totalStock) {
        setState(() {
          _quantity++;
        });
      } else {
        _showErrorSnackbar(
          'Maximum available quantity is ${_product.value!.totalStock}',
        );
      }
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
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
        title: Obx(() => Text(
          _product.value?.name ?? 'Product Details',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ShimmerLoading(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: double.infinity,
                color: Colors.white,
              ),
              Padding(
                padding: AppSizes.paddingAll(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 200.w, height: 24.h, color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(width: 100.w, height: 16.h, color: Colors.white),
                    SizedBox(height: 24.h),
                    Container(width: double.infinity, height: 100.h, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      if (_product.value == null) {
        return _buildNotFoundScreen();
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            Padding(
              padding: AppSizes.paddingAll(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(),
                  SizedBox(height: AppSizes.spaceMedium16),
                  _buildPriceSection(),
                  SizedBox(height: AppSizes.spaceLarge24),
                  _buildDescriptionSection(),
                  SizedBox(height: AppSizes.spaceLarge24),
                  if (_product.value!.branchNames.isNotEmpty)
                    _buildBranchesSection(),
                  SizedBox(height: AppSizes.spaceLarge24),
                  _buildQuantitySelector(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductImage() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      width: double.infinity,
      color: AppColors.primaryGold.withOpacity(0.1),
      child: _product.value!.imageUrl.isNotEmpty
          ? Image.network(
        _product.value!.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: AppSizes.icon(50),
        color: AppColors.primaryGold,
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _product.value!.name,
                style: TextStyle(
                  fontSize: AppSizes.textExtraLarge22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              Text(
                _product.value!.category,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: AppSizes.paddingSymmetric(
            horizontal: AppSizes.spaceSmall8,
            vertical: AppSizes.height(4),
          ),
          decoration: BoxDecoration(
            color: _getStockStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
            border: Border.all(color: _getStockStatusColor()),
          ),
          child: Text(
            _product.value!.stockStatus,
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: _getStockStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: AppSizes.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
      ),
      child: _isBannerApplicable
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatPrice(_displayPrice),
                style: TextStyle(
                  fontSize: AppSizes.textExtraLarge22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.height(2),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  '${widget.bannerDiscount!.discountDisplay} OFF',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _formatPrice(_product.value!.price),
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),

        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatPrice(_product.value!.price),
            style: TextStyle(
              fontSize: AppSizes.textExtraLarge22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            '${_product.value!.totalStock} in stock',
            style: TextStyle(
              fontSize: AppSizes.textSmall12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          _product.value!.description,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available at',
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
          children: _product.value!.branchNames
              .map((branch) => Chip(
            label: Text(
              branch,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.primaryGold,
              ),
            ),
            backgroundColor: AppColors.primaryGold.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _decrementQuantity,
                icon: const Icon(Icons.remove),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: AppSizes.width(20),
                  minHeight: AppSizes.height(20),
                ),
              ),
              SizedBox(
                width: AppSizes.width(40),
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _incrementQuantity,
                icon: const Icon(Icons.add),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: AppSizes.width(20),
                  minHeight: AppSizes.height(20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: AppSizes.paddingAll(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(_displayPrice),
                  style: TextStyle(
                    fontSize: AppSizes.textExtraLarge22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                if (_isBannerApplicable)
                  Text(
                    _formatPrice(_product.value!.price),
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '${_product.value!.totalStock} in stock',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSizes.spaceMedium16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _product.value!.inStock && !_isAddingToCart ? _addToCart : null,
              icon: _isAddingToCart
                  ? SizedBox(
                width: AppSizes.width(20),
                height: AppSizes.height(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
                  : Icon(Icons.shopping_cart, size: AppSizes.icon(20)),
              label: Text(
                _isAddingToCart ? 'Adding...' : 'Add to Cart',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _product.value!.inStock ? AppColors.primaryGold : Colors.grey[400],
                foregroundColor: AppColors.white,
                padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Center(
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
            'Product not found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceMedium16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Go Back',
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

  Color _getStockStatusColor() {
    if (_product.value == null) return Colors.grey;
    if (_product.value!.isOutOfStock) return Colors.red;
    if (_product.value!.isLowStock) return Colors.orange;
    return Colors.green;
  }
}