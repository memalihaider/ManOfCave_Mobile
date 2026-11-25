// screens/admin_product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/auth_controller.dart';
import '../../controlers/category_controller.dart';
import '../../controlers/product_controller.dart';
import '../../models/product_model.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final String productId;

  const AdminProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final AuthController _authController = Get.find<AuthController>();
  final CategoryController _categoryController = Get.find<CategoryController>();

  // Admin editing states
  bool _isEditing = false;
  TextEditingController? _priceController;
  TextEditingController? _stockController;
  TextEditingController? _costController;
  TextEditingController? _nameController;
  TextEditingController? _descriptionController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _priceController?.dispose();
    _stockController?.dispose();
    _costController?.dispose();
    _nameController?.dispose();
    _descriptionController?.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} ${AppStrings.appCurreny}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // void _startEditing(Product product) {
  //   setState(() {
  //     _isEditing = true;
  //     _nameController = TextEditingController(text: product.name);
  //     _descriptionController = TextEditingController(text: product.description);
  //     _priceController = TextEditingController(text: product.price.toString());
  //     _stockController = TextEditingController(text: product.totalStock.toString());
  //     _costController = TextEditingController(text: product.cost.toString());
  //   });
  // }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController?.dispose();
      _descriptionController?.dispose();
      _priceController?.dispose();
      _stockController?.dispose();
      _costController?.dispose();
      _nameController = null;
      _descriptionController = null;
      _priceController = null;
      _stockController = null;
      _costController = null;
    });
  }

  Future<void> _saveChanges(Product product) async {
    try {
      final updatedProduct = product.copyWith(
        name: _nameController?.text ?? product.name,
        description: _descriptionController?.text ?? product.description,
        price: double.tryParse(_priceController?.text ?? '') ?? product.price,
        totalStock: int.tryParse(_stockController?.text ?? '') ?? product.totalStock,
        cost: double.tryParse(_costController?.text ?? '') ?? product.cost,
        updatedAt: DateTime.now(),
      );

      final success = await _productController.updateProduct(product.id, updatedProduct);

      if (success) {
        Get.snackbar(
          'Success',
          'Product updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _cancelEditing();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Delete Product',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this product?',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _productController.deleteProduct(product.id);
      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Product deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _productController.getProductById(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildNotFoundScreen();
        }

        final product = snapshot.data!;
        return _buildAdminProductDetailScreen(product);
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
          'Product Details',
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
          'Product Not Found',
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
              'Product not found',
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

  Widget _buildAdminProductDetailScreen(Product product) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          product.name,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(product),
            color: Colors.red,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: AppSizes.height(80)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: AppSizes.height(250),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge20),
                  bottomRight: Radius.circular(AppSizes.radiusLarge20),
                ),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: product.imageUrl.isEmpty
                  ? Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
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
                  // Product Name and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _isEditing
                            ? TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                            ),
                          ),
                        )
                            : Text(
                          product.name,
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
                          color: _getStatusColor(product).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(
                            color: _getStatusColor(product),
                          ),
                        ),
                        child: Text(
                          product.stockStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(product),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.spaceSmall8),

                  // Category
                  Text(
                    product.category,
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
                      color: product.categoryId.isNotEmpty
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                    ),
                    child: Text(
                      product.categoryId.isNotEmpty
                          ? 'CATEGORY ID: ${product.categoryId}'
                          : 'NO CATEGORY',
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: product.categoryId.isNotEmpty ? Colors.blue : Colors.grey,
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
                  _isEditing
                      ? TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                    ),
                  )
                      : Text(
                    product.description,
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
                                'Price',
                                _formatPrice(product.price),
                                Icons.attach_money,
                                AppColors.primaryGold,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Cost',
                                _formatPrice(product.cost),
                                Icons.sell_outlined,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Total Sold',
                                '${product.totalSold}',
                                Icons.sell,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'In Stock',
                                '${product.totalStock}',
                                Icons.inventory,
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
                                'Total Revenue',
                                _formatPrice(product.revenue),
                                Icons.receipt,
                                Colors.purple,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Total Profit',
                                _formatPrice(product.totalProfit),
                                Icons.trending_up,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        _buildStatItem(
                          'Profit Margin',
                          '${product.profitMargin.toStringAsFixed(1)}%',
                          Icons.percent,
                          Colors.teal,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLarge24),

                  // Branch Information
                  if (product.branches.isNotEmpty)
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
                          children: product.branchNames.map((branchName) {
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
                              'Product Information',
                              style: TextStyle(
                                fontSize: AppSizes.textMedium14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.spaceMedium16),
                        _buildInfoRow('Product ID', product.id),
                        _buildInfoRow('SKU', product.sku),
                        _buildInfoRow('Category ID', product.categoryId),
                        _buildInfoRow('Created', _formatDateTime(product.createdAt)),
                        _buildInfoRow('Last Updated', _formatDateTime(product.updatedAt)),
                        if (product.branches.isNotEmpty)
                          _buildInfoRow('Branch IDs', product.branches.join(', ')),
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
      bottomNavigationBar: _buildAdminBottomBar(product),
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

  Widget _buildAdminBottomBar(Product product) {
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBottomStat('Price', _formatPrice(product.price)),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Cost', _formatPrice(product.cost)),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Stock', '${product.totalStock}'),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Sold', '${product.totalSold}'),
                  SizedBox(width: AppSizes.spaceMedium16),
                  _buildBottomStat('Profit', _formatPrice(product.totalProfit)),
                ],
              ),
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),

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

  Color _getStatusColor(Product product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }
}