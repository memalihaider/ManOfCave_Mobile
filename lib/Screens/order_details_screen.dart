// screens/order_detail_screen.dart (UPDATED WITH PICKUP BRANCH)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../controlers/order_controller.dart';
import '../controlers/feedback_controller.dart';
import '../models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderController _orderController = Get.find<OrderController>();
  final FeedbackController _feedbackController = Get.find<FeedbackController>();
  final Rx<Order?> _order = Rx<Order?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _hasGivenFeedback = false.obs;
  final RxBool _isSubmittingFeedback = false.obs;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      _isLoading.value = true;
      final order = await _orderController.getOrderById(widget.orderId);
      _order.value = order;

      if (order != null && order.isCompleted) {
        await _checkFeedbackStatus();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load order details');
      print('Error loading order: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _checkFeedbackStatus() async {
    if (_order.value == null) return;

    try {
      bool hasFeedback = false;
      for (final product in _order.value!.products) {
        final exists = await _feedbackController.hasGivenFeedback(
          product.productId,
          'product',
          _order.value!.customerId,
        );
        if (exists) {
          hasFeedback = true;
          break;
        }
      }
      _hasGivenFeedback.value = hasFeedback;
    } catch (e) {
      print('Error checking feedback status: $e');
    }
  }

  void _showCancelDialog() {
    if (_order.value == null) return;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Cancel Order',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel order ${_order.value!.transactionId}?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _orderController.updateOrderStatus(widget.orderId, 'cancelled');
              await _loadOrderDetails();
              Get.snackbar(
                'Order Cancelled',
                'Order has been cancelled successfully',
                backgroundColor: AppColors.primaryGold,
                colorText: AppColors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Yes, Cancel',
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

  void _showReceipt() {
    if (_order.value == null) return;

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.width(40),
              height: AppSizes.height(4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Order Receipt',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            _buildReceiptContent(),
            SizedBox(height: AppSizes.spaceMedium16),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.snackbar(
                  'Receipt Downloaded',
                  'Receipt saved to your device',
                  backgroundColor: Colors.green,
                  colorText: AppColors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                minimumSize: Size(double.infinity, AppSizes.height(48)),
              ),
              child: Text(
                'Download Receipt',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final order = _order.value;
    if (order == null) return const SizedBox();

    return Column(
      children: [
        Text(
          'ORDER RECEIPT',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Text(
          'Transaction ID: ${order.transactionId}',
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSizes.spaceSmall8),
        Text(
          'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
          style: TextStyle(
            fontSize: AppSizes.textSmall12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        // Customer Info
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
                'Customer',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              Text(order.customerName),
              Text(order.customerPhone),
              Text(order.customerEmail),
            ],
          ),
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        // Pickup Information
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
                  Icon(Icons.store_outlined, size: AppSizes.iconSmall14, color: Colors.blue),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Text(
                    'Pickup Information',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Text('Branch: ${order.pickupBranch}', style: TextStyle(fontSize: AppSizes.textSmall12, color: AppColors.primaryDark)),
              Text('Address: ${order.pickupBranchAddress}', style: TextStyle(fontSize: AppSizes.textSmall12, color: Colors.grey[600])),
              Text('Phone: ${order.pickupBranchPhone}', style: TextStyle(fontSize: AppSizes.textSmall12, color: Colors.grey[600])),
              Text('Hours: ${order.pickupBranchTiming}', style: TextStyle(fontSize: AppSizes.textSmall12, color: Colors.grey[600])),
            ],
          ),
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        // Amount Summary
        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Items (${order.totalItems})'),
                  Text('${AppStrings.appCurreny}${order.totalAmount.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: AppSizes.height(4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Status'),
                  Text(
                    order.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: order.isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (order.pointsAwarded) ...[
                SizedBox(height: AppSizes.spaceSmall8),
                Divider(color: Colors.grey[300]),
                SizedBox(height: AppSizes.spaceSmall8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Points Awarded'),
                    Row(
                      children: [
                        Icon(Icons.stars, size: AppSizes.iconSmall14, color: Colors.amber),
                        SizedBox(width: AppSizes.width(4)),
                        Text(
                          'Yes',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              SizedBox(height: AppSizes.spaceSmall8),
              Divider(color: Colors.grey[300]),
              SizedBox(height: AppSizes.spaceSmall8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.textMedium14,
                    ),
                  ),
                  Text(
                    '${AppStrings.appCurreny}${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.textMedium14,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackPrompt() {
    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(50),
            height: AppSizes.width(50),
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars,
              size: AppSizes.icon(24),
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Experience!',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: AppSizes.height(4)),
                Text(
                  'Rate your order products and earn loyalty points!',
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showFeedbackDialog,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: AppSizes.iconSmall18,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FEEDBACK DIALOG METHODS ====================
  void _showFeedbackDialog() {
    if (_order.value == null || _order.value!.products.isEmpty) return;

    final products = _order.value!.products;
    final isSingleProduct = products.length == 1;

    if (isSingleProduct) {
      _showSingleProductFeedbackDialog(products.first);
    } else {
      _showMultipleProductsFeedbackDialog(products);
    }
  }

  void _showSingleProductFeedbackDialog(OrderProduct product) {
    final _rating = 5.obs;
    final _commentController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.width(40),
                height: AppSizes.height(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              Text(
                'Rate Your Product',
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                'How was your experience with ${product.productName}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),

              // Product Preview
              Container(
                padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.width(60),
                      height: AppSizes.height(60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        image: product.productImage.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(product.productImage),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: product.productImage.isEmpty
                          ? Icon(
                        Icons.shopping_bag_outlined,
                        size: AppSizes.icon(24),
                        color: Colors.grey[400],
                      )
                          : null,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppSizes.height(4)),
                          Text(
                            'SKU: ${product.productSku}',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${AppStrings.appCurreny}${product.totalPrice.toStringAsFixed(2)} × ${product.quantity}',
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
              SizedBox(height: AppSizes.spaceLarge24),

              // Star Rating
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _rating.value = index + 1,
                    child: Icon(
                      index < _rating.value ? Icons.star : Icons.star_border,
                      size: AppSizes.icon(40),
                      color: AppColors.primaryGold,
                    ),
                  );
                }),
              )),
              SizedBox(height: AppSizes.spaceMedium16),
              Obx(() => Text(
                '${_rating.value} ${_rating.value == 1 ? 'Star' : 'Stars'}',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGold,
                ),
              )),
              SizedBox(height: AppSizes.spaceLarge24),

              // Comment Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Share your experience (Optional)',
                        hintText: 'What did you like about this product?\nAny suggestions for improvement?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (value.trim().length < 3) {
                          return 'Comment must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.spaceMedium16),

                    // Points Information
                    Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: AppSizes.icon(20),
                            color: AppColors.primaryGold,
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earn Loyalty Points',
                                  style: TextStyle(
                                    fontSize: AppSizes.textSmall12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                SizedBox(height: AppSizes.height(4)),
                                Text(
                                  'Get ${_calculateFeedbackPoints(_rating.value)} points when your feedback is approved',
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
                    SizedBox(height: AppSizes.spaceLarge24),

                    // Submit Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: AppSizes.height(52),
                      child: ElevatedButton(
                        onPressed: _isSubmittingFeedback.value ? null : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await _submitSingleProductFeedback(
                              product: product,
                              rating: _rating.value.toInt(),
                              comment: _commentController.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isSubmittingFeedback.value
                            ? SizedBox(
                          width: AppSizes.width(20),
                          height: AppSizes.height(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                            : Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultipleProductsFeedbackDialog(List<OrderProduct> products) {
    final selectedProducts = <String, bool>{}.obs;
    final productRatings = <String, int>{}.obs;
    final productComments = <String, TextEditingController>{};

    for (final product in products) {
      selectedProducts[product.productId] = true;
      productRatings[product.productId] = 5;
      productComments[product.productId] = TextEditingController();
    }

    Get.bottomSheet(
      Container(
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusLarge20),
            topRight: Radius.circular(AppSizes.radiusLarge20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.width(40),
              height: AppSizes.height(4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Rate Your Order',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              'Please rate each product in your order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductFeedbackItem(
                    product: product,
                    isSelected: selectedProducts[product.productId] ?? true,
                    onSelected: (value) => selectedProducts[product.productId] = value,
                    rating: productRatings[product.productId] ?? 5,
                    onRatingChanged: (rating) => productRatings[product.productId] = rating,
                    commentController: productComments[product.productId]!,
                  );
                },
              ),
            ),

            SizedBox(height: AppSizes.spaceMedium16),

            // Points Information
            Container(
              padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: AppSizes.icon(20),
                    color: AppColors.primaryGold,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earn Loyalty Points',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: AppSizes.height(4)),
                        Text(
                          'Earn up to ${_calculateTotalPossiblePoints(products.length)} points for all products',
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

            // Submit Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: AppSizes.height(52),
              child: ElevatedButton(
                onPressed: _isSubmittingFeedback.value ? null : () async {
                  await _submitMultipleProductsFeedback(
                    products: products,
                    selectedProducts: selectedProducts,
                    productRatings: productRatings,
                    productComments: productComments,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isSubmittingFeedback.value
                    ? SizedBox(
                  width: AppSizes.width(20),
                  height: AppSizes.height(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
                    : Text(
                  'Submit All Feedback',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
            SizedBox(height: AppSizes.spaceMedium16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFeedbackItem({
    required OrderProduct product,
    required bool isSelected,
    required Function(bool) onSelected,
    required int rating,
    required Function(int) onRatingChanged,
    required TextEditingController commentController,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(
          color: isSelected ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelected(value ?? false),
                activeColor: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Expanded(
                child: Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryDark : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),

          if (isSelected) ...[
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              'Rating:',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRatingChanged(index + 1),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: AppSizes.icon(28),
                    color: AppColors.primaryGold,
                  ),
                );
              }),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Text(
              '$rating ${rating == 1 ? 'Star' : 'Stars'}',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            TextFormField(
              controller: commentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Comments (Optional)',
                hintText: 'Share your thoughts about this product',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _calculateFeedbackPoints(int rating) {
    switch (rating) {
      case 5: return 100;
      case 4: return 50;
      case 3: return 25;
      default: return 0;
    }
  }

  int _calculateTotalPossiblePoints(int productCount) {
    return productCount * 100;
  }

  Future<void> _submitSingleProductFeedback({
    required OrderProduct product,
    required int rating,
    required String comment,
  }) async {
    if (_order.value == null) return;

    _isSubmittingFeedback.value = true;

    try {
      final feedbackId = await _feedbackController.submitOrderFeedback(
        orderId: widget.orderId,
        productId: product.productId,
        productName: product.productName,
        rating: rating,
        comment: comment,
        productBranches: product.productBranches,
        productBranchNames: product.productBranchNames,
        productCategory: product.productCategory,
        productCategoryId: product.productCategoryId,
        productPrice: product.price,
        productImageUrl: product.productImage,
        productDescription: '',
      );

      if (feedbackId != null) {
        Get.back();
        _hasGivenFeedback.value = true;
        Get.snackbar(
          'Feedback Submitted!',
          'Thank you for your valuable feedback!',
          backgroundColor: Colors.green,
          colorText: AppColors.white,
          duration: Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit feedback: $e',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
    } finally {
      _isSubmittingFeedback.value = false;
    }
  }

  Future<void> _submitMultipleProductsFeedback({
    required List<OrderProduct> products,
    required RxMap<String, bool> selectedProducts,
    required RxMap<String, int> productRatings,
    required Map<String, TextEditingController> productComments,
  }) async {
    if (_order.value == null) return;

    _isSubmittingFeedback.value = true;
    int submittedCount = 0;
    List<String> feedbackIds = [];

    try {
      for (final product in products) {
        if (selectedProducts[product.productId] == true) {
          final rating = productRatings[product.productId] ?? 5;
          final comment = productComments[product.productId]?.text.trim() ?? '';

          final feedbackId = await _feedbackController.submitOrderFeedback(
            orderId: widget.orderId,
            productId: product.productId,
            productName: product.productName,
            rating: rating,
            comment: comment,
            productBranches: product.productBranches,
            productBranchNames: product.productBranchNames,
            productCategory: product.productCategory,
            productCategoryId: product.productCategoryId,
            productPrice: product.price,
            productImageUrl: product.productImage,
            productDescription: '',
          );

          if (feedbackId != null) {
            feedbackIds.add(feedbackId);
            submittedCount++;
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }

      if (submittedCount > 0) {
        Get.back();
        _hasGivenFeedback.value = true;

        if (submittedCount == 1) {
          Get.snackbar(
            'Feedback Submitted!',
            'Thank you for your feedback!',
            backgroundColor: Colors.green,
            colorText: AppColors.white,
            duration: Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            'Feedbacks Submitted!',
            'Thank you for providing feedback on $submittedCount products!',
            backgroundColor: Colors.green,
            colorText: AppColors.white,
            duration: Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit some feedbacks: $e',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
      );
    } finally {
      _isSubmittingFeedback.value = false;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 'Your order is pending confirmation';
      case 'approved':
        return 'Order confirmed, preparing for pickup';
      case 'in-progress':
        return 'Your order is being prepared';
      case 'completed':
        return 'Order completed successfully';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Order status unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle_outline;
      case 'in-progress':
        return Icons.refresh;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  double _getOrderProgress(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 0.25;
      case 'approved':
        return 0.5;
      case 'in-progress':
        return 0.75;
      case 'completed':
        return 1.0;
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
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
          _order.value?.transactionId ?? 'Order Details',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGold),
                SizedBox(height: AppSizes.spaceMedium16),
                Text(
                  'Loading order details...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (_order.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: AppSizes.iconLarge60, color: Colors.grey[400]),
                SizedBox(height: AppSizes.spaceMedium16),
                Text(
                  'Order not found',
                  style: TextStyle(
                    fontSize: AppSizes.textLarge18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceMedium16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        final order = _order.value!;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Order Status Banner
              Container(
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                color: _getOrderStatusColor(order.status).withOpacity(0.1),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.width(60),
                      height: AppSizes.height(60),
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(order.status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(order.status),
                        size: AppSizes.icon(30),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceMedium16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(order.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: AppSizes.textLarge18,
                              fontWeight: FontWeight.w700,
                              color: _getOrderStatusColor(order.status),
                            ),
                          ),
                          SizedBox(height: AppSizes.height(4)),
                          Text(
                            _getStatusMessage(order.status),
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (order.isPending || order.isCompleted)
                            SizedBox(height: AppSizes.spaceSmall8),
                          if (order.isPending || order.isCompleted)
                            LinearProgressIndicator(
                              value: _getOrderProgress(order.status),
                              backgroundColor: Colors.grey[300],
                              color: _getOrderStatusColor(order.status),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Feedback Prompt for Completed Orders
              if (order.isCompleted && !_hasGivenFeedback.value && order.products.isNotEmpty)
                _buildFeedbackPrompt(),

              // Order Summary
              Container(
                margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: AppSizes.textMedium14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceSmall8),
                    _buildDetailRow('Order ID', order.transactionId),
                    _buildDetailRow('Order Date', order.orderDate),
                    _buildDetailRow('Expected Pickup', order.expectedDeliveryDate),
                    _buildDetailRow('Total Items', '${order.totalItems} items'),
                    if (order.orderNotes != null && order.orderNotes!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppSizes.spaceSmall8),
                          Text(
                            'Notes:',
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: AppSizes.height(4)),
                          Text(
                            order.orderNotes!,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Pickup Information
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSizes.spaceMedium16),
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: AppSizes.icon(20),
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          'Pickup Information',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall8),
                    _buildDetailRow('Pickup Branch', order.pickupBranch),
                    _buildDetailRow('Address', order.pickupBranchAddress),
                    _buildDetailRow('Phone', order.pickupBranchPhone),
                    _buildDetailRow('Pickup Hours', order.pickupBranchTiming),
                    SizedBox(height: AppSizes.spaceSmall8),
                    Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: AppSizes.iconSmall14,
                            color: Colors.blue,
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Expanded(
                            child: Text(
                              'Please collect your order from the selected branch during pickup hours',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Products List
              Container(
                margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: AppSizes.icon(20),
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          'Products (${order.totalItems})',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall8),
                    ...order.products.map((product) {
                      return Container(
                        margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
                        padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: AppSizes.width(60),
                              height: AppSizes.height(60),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                                image: product.productImage.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(product.productImage),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: product.productImage.isEmpty
                                  ? Icon(
                                Icons.shopping_bag_outlined,
                                size: AppSizes.icon(24),
                                color: Colors.grey[400],
                              )
                                  : null,
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: TextStyle(
                                      fontSize: AppSizes.textMedium14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.height(4)),
                                  Text(
                                    'SKU: ${product.productSku}',
                                    style: TextStyle(
                                      fontSize: AppSizes.textSmall12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.height(4)),
                                  Row(
                                    children: [
                                      Text(
                                        'Qty: ${product.quantity}',
                                        style: TextStyle(
                                          fontSize: AppSizes.textSmall12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: AppSizes.spaceMedium16),
                                      Text(
                                        '${AppStrings.appCurreny}${product.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: AppSizes.textSmall12,
                                          fontWeight: FontWeight.w600,
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
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Payment Information
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSizes.spaceMedium16),
                padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: AppSizes.icon(20),
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: AppSizes.spaceSmall8),
                        Text(
                          'Payment Information',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall8),
                    _buildDetailRow('Payment Method', order.paymentMethod),
                    _buildDetailRow('Payment Status', order.paymentStatus),
                    if (order.transactionId.isNotEmpty)
                      _buildDetailRow('Transaction ID', order.transactionId),
                    SizedBox(height: AppSizes.spaceMedium16),
                    Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal'),
                              Text('${AppStrings.appCurreny}${order.totalAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (order.isPaid)
                            Column(
                              children: [
                                SizedBox(height: AppSizes.spaceSmall8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Paid',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppSizes.textMedium14,
                                      ),
                                    ),
                                    Text(
                                      '${AppStrings.appCurreny}${order.totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppSizes.textMedium14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Order Timeline
              _buildOrderTimeline(order),

              SizedBox(height: AppSizes.height(100)),
            ],
          ),
        );
      }),
      bottomSheet: Obx(() {
        if (_order.value == null) return const SizedBox();

        final order = _order.value!;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMedium16,
            vertical: AppSizes.spaceMedium16,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cancel Button for Upcoming/Approved Orders
              if (order.isPending || order.isCompleted)
                Expanded(
                  child: SizedBox(
                    height: AppSizes.height(48),
                    child: OutlinedButton.icon(
                      onPressed: _showCancelDialog,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Order'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                        ),
                      ),
                    ),
                  ),
                ),

              // Receipt Button
              Expanded(
                child: SizedBox(
                  height: AppSizes.height(48),
                  child: ElevatedButton.icon(
                    onPressed: _showReceipt,
                    icon: const Icon(Icons.receipt_outlined),
                    label: const Text('Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 'Upcoming';
      case 'approved':
        return 'Approved';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _buildOrderTimeline(Order order) {
    final statuses = [
      {'status': 'upcoming', 'label': 'Order Placed', 'date': order.createdAt},
      {'status': 'approved', 'label': 'Order Approved', 'date': null},
      {'status': 'in-progress', 'label': 'Preparing', 'date': null},
      {'status': 'completed', 'label': 'Ready for Pickup', 'date': null},
    ];

    if (order.isCancelled) {
      return Container(
        margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
        padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: AppSizes.spaceSmall8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'This order was cancelled on ${DateFormat('dd MMM yyyy').format(order.updatedAt)}',
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
      );
    }

    return Container(
      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_outlined,
                size: AppSizes.icon(20),
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSizes.spaceSmall8),
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isActive = _getStatusIndex(order.status) >= index;
            final isLast = index == statuses.length - 1;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSizes.width(24),
                      height: AppSizes.height(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.primaryGold : Colors.grey[300],
                        border: Border.all(
                          color: isActive ? AppColors.primaryGold : AppColors.grey,
                          width: 2,
                        ),
                      ),
                      child: isActive
                          ? Icon(
                        Icons.check,
                        size: AppSizes.iconSmall14,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status['label'].toString(),
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.primaryDark : Colors.grey[500],
                            ),
                          ),
                          if (status['date'] != null && isActive)
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(status['date'] as DateTime),
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
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.only(left: AppSizes.width(11), top: AppSizes.spaceSmall8, bottom: AppSizes.spaceSmall8),
                    child: Container(
                      width: 2,
                      height: AppSizes.height(24),
                      color: isActive ? AppColors.primaryGold : Colors.grey[300],
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  int _getStatusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 0;
      case 'approved':
        return 1;
      case 'in-progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.width(120),
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
}