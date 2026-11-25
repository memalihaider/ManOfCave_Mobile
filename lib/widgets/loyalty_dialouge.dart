// utils/loyalty_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controlers/loyalty_points_controller.dart';

class LoyaltyDialog {
  static Future<void> showOrderPointsDialog({
    required String orderId,
    required String orderNumber,
    required String customerId,
    required String customerName,
    required double totalAmount,
    required List<String> branchNames,
    required List<dynamic> products,
  }) async {
    final loyaltyController = Get.find<LoyaltyController>();

    // Calculate points
    await loyaltyController.loadLoyaltyConfig();
    final config = loyaltyController.loyaltyConfig;
    int points = 0;

    if (config != null) {
      points = config.calculatePoints(totalAmount);
    }

    // Show dialog
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.celebration,
              size: 50,
              color: Colors.amber,
            ),
            SizedBox(height: 10),
            Text(
              '🎉 Order Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! ${customerName.split(' ').first} earned:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            _buildPointsCard(points, totalAmount),
            SizedBox(height: 15),
            Text(
              'Order Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Order #: $orderNumber',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Amount: ${totalAmount.toStringAsFixed(2)} AED',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (branchNames.isNotEmpty)
              Text(
                'Branch: ${branchNames.first}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Later',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _awardOrderPoints(
                loyaltyController: loyaltyController,
                orderId: orderId,
                customerId: customerId,
                orderNumber: orderNumber,
                totalAmount: totalAmount,
                branchNames: branchNames,
                products: products,
                customerName: customerName,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Award Points Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> showBookingPointsDialog({
    required String bookingId,
    required String bookingNumber,
    required String customerId,
    required String customerName,
    required double totalAmount,
    required String serviceName,
    required String branchName,
  }) async {
    final loyaltyController = Get.find<LoyaltyController>();

    // Calculate points
    await loyaltyController.loadLoyaltyConfig();
    final config = loyaltyController.loyaltyConfig;
    int points = 0;

    if (config != null) {
      points = config.calculatePoints(totalAmount);
    }

    // Show dialog
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.spa,
              size: 50,
              color: Colors.blue,
            ),
            SizedBox(height: 10),
            Text(
              '✨ Booking Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great! ${customerName.split(' ').first} will receive:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            _buildPointsCard(points, totalAmount),
            SizedBox(height: 15),
            Text(
              'Service Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Booking #: $bookingNumber',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Service: $serviceName',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Amount: ${totalAmount.toStringAsFixed(2)} AED',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Branch: $branchName',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _awardBookingPoints(
                loyaltyController: loyaltyController,
                bookingId: bookingId,
                customerId: customerId,
                bookingNumber: bookingNumber,
                serviceName: serviceName,
                amount: totalAmount,
                branchName: branchName,
                customerName: customerName,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Add to Loyalty',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildPointsCard(int points, double amount) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade300, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber.shade800, size: 30),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$points Points',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '≈ ${(points * 0.03).toStringAsFixed(2)} AED Value',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _awardOrderPoints({
    required LoyaltyController loyaltyController,
    required String orderId,
    required String customerId,
    required String orderNumber,
    required double totalAmount,
    required List<String> branchNames,
    required List<dynamic> products,
    required String customerName,
  }) async {
    try {
      final branchName = branchNames.isNotEmpty ? branchNames.first : 'Main Branch';
      final productName = products.isNotEmpty
          ? products.first['productName'] ?? 'Products'
          : 'Products';

      await loyaltyController.awardProductPurchasePoints(
        customerId: customerId,
        purchaseId: orderId,
        amount: totalAmount,
        productName: productName,
        branchId: '',
        branchName: branchName,
      );

      // Show success notification
      Get.snackbar(
        'Points Awarded Successfully! 🎉',
        'points points added to ${customerName.split(' ').first}\'s wallet',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to award points: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  static Future<void> _awardBookingPoints({
    required LoyaltyController loyaltyController,
    required String bookingId,
    required String customerId,
    required String bookingNumber,
    required String serviceName,
    required double amount,
    required String branchName,
    required String customerName,
  }) async {
    try {
      await loyaltyController.awardServiceBookingPoints(
        customerId: customerId,
        bookingId: bookingId,
        amount: amount,
        serviceName: serviceName,
        branchId: '',
        branchName: branchName,
      );

      // Show success notification
      Get.snackbar(
        'Booking Points Added! ✨',
        'Loyalty points awarded for booking #$bookingNumber',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to award booking points: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Optional: Show summary of points earned
  static void showPointsSummary(String customerName, int points, double monetaryValue) {
    Get.snackbar(
      '🎉 Points Summary',
      '$customerName earned $points points (${monetaryValue.toStringAsFixed(2)} AED)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.purple,
      colorText: Colors.white,
      duration: Duration(seconds: 4),
      icon: Icon(Icons.workspace_premium, color: Colors.white),
    );
  }
}