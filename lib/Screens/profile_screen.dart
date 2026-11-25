import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controlers/auth_controller.dart';
import '../controlers/loyalty_points_controller.dart';
import '../controlers/referral_controller.dart';
import '../widgets/profile_header.dart';
import 'my_booking_screen.dart';
import 'cart_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();
  final LoyaltyController _loyaltyController = Get.find<LoyaltyController>();
  // final ReferralController _referralController = Get.find<ReferralController>();

  ProfileScreen({super.key});

  void _showEditProfileDialog() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    TextEditingController nameController = TextEditingController(text: user.name);
    TextEditingController phoneController = TextEditingController(text: user.phone ?? '');
    TextEditingController dobController = TextEditingController(text: user.dateOfBirth ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              GestureDetector(
                onTap: () => _selectDateOfBirth(dobController),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.cake_outlined, size: AppSizes.icon(20)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                      suffixIcon: Icon(Icons.calendar_today, size: AppSizes.icon(20)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                'Adding your date of birth earns you 200 bonus points on your birthday!',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: AppColors.primaryGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final bool success = await _authController.updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                dateOfBirth: dobController.text.trim(),
              );

              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceSmall8,
              ),
            ),
            child: Text(
              'Save',
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

  void _showChangePasswordDialog() {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline, size: AppSizes.icon(20)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                Get.snackbar(
                  'Error',
                  'Passwords do not match',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                Get.snackbar(
                  'Error',
                  'Password must be at least 6 characters',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final success = await _authController.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceSmall8,
              ),
            ),
            child: Text(
              'Update',
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

  Future<void> _selectDateOfBirth(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formattedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceSmall8,
              ),
            ),
            child: Text(
              'Log Out',
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

  void _performLogout() async {
    Get.dialog(
      Center(
        child: Container(
          padding: AppSizes.paddingAll(AppSizes.spaceLarge24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              Text(
                'Logging out...',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await _authController.logout();
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

//   void _shareReferralCode(String code) {
//     final message = '''
// 🎉 Join me at Jam Beauty Lounge! 🎉
//
// Use my referral code to get amazing discounts on your first booking or order!
//
// ✨ My Referral Code: $code ✨
//
// ${_referralController.getDiscountMessage()}
//
// ${_referralController.getReferrerDiscountMessage()}
//
// Download the app and enter this code during signup to claim your discount!
//
// #JamBeautyLounge #ReferralCode #BeautyDeals
// ''';
//
//     Share.share(message);
//   }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldSoft,
        foregroundColor: AppColors.textInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: canPop,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textInk,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
                child: Column(
                  children: [
                    // Profile Header
                    Obx(() {
                      final user = _authController.currentUser.value;
                      if (user == null) return const SizedBox();

                      return ProfileHeaderWidget(
                        name: user.name,
                        email: user.email,
                        phoneNumber: user.phone ?? 'Not provided',
                        onEditPressed: _showEditProfileDialog,
                        onImageTap: () {},
                      );
                    }),

                    // Email Verification Section
                    Obx(() {
                      if (_authController.isEmailVerified.value) return const SizedBox();

                      return Container(
                        margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
                        padding: AppSizes.paddingAll(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                                SizedBox(width: 12.w),
                                Text(
                                  'Verify Your Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Your email is not verified. Please verify to ensure full account security.',
                              style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade800),
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _authController.isLoading.value 
                                    ? null 
                                    : () => _authController.sendEmailVerification(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGold,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: _authController.isLoading.value
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Send Verification Email'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Loyalty Points Card
                    Container(
                      margin: AppSizes.paddingAll(AppSizes.spaceMedium16),
                      child: Obx(() {
                        final wallet = _loyaltyController.customerWallet;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'E-WALLET',
                                          style: TextStyle(
                                            fontSize: AppSizes.textSmall12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(height: AppSizes.spaceSmall8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'AED ${(wallet?.balance ?? 0).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: isLandscape ? AppSizes.font(24) : AppSizes.font(28),
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                            SizedBox(width: AppSizes.spaceSmall8),
                                            Text(
                                              'balance',
                                              style: TextStyle(
                                                fontSize: AppSizes.textSmall12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: AppSizes.spaceSmall8),
                                          child: Text(
                                            'Managed at salon / portal',
                                            style: TextStyle(
                                              fontSize: AppSizes.textSmall12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGold.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: isLandscape ? AppSizes.icon(24) : AppSizes.icon(28),
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Legacy earned/redeemed points UI removed
                                if (false)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                                  ),
                                  padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'EARNED',
                                              style: TextStyle(
                                                fontSize: AppSizes.textSmall12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: AppSizes.spaceSmall8),
                                            Text(
                                              '${wallet?.totalPointsEarned ?? 0}',
                                              style: TextStyle(
                                                fontSize: isLandscape ? AppSizes.font(16) : AppSizes.font(18),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: AppSizes.width(1),
                                        height: AppSizes.height(30),
                                        color: Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'REDEEMED',
                                              style: TextStyle(
                                                fontSize: AppSizes.textSmall12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: AppSizes.spaceSmall8),
                                            Text(
                                              '${wallet?.totalPointsRedeemed ?? 0}',
                                              style: TextStyle(
                                                fontSize: isLandscape ? AppSizes.font(16) : AppSizes.font(18),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // // Referral Section
                    // _buildReferralSection(isLandscape),

                    // Actions Section
                    Padding(
                      padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.dashboard_outlined,
                                size: AppSizes.icon(20),
                                color: AppColors.primaryGold,
                              ),
                              SizedBox(width: AppSizes.spaceSmall8),
                              Text(
                                'My Activities',
                                style: TextStyle(
                                  fontSize: AppSizes.textMedium14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.spaceMedium16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isLandscape ? 4 : 3,
                            crossAxisSpacing: AppSizes.spaceSmall8,
                            mainAxisSpacing: AppSizes.spaceSmall8,
                            childAspectRatio: 1.0,
                            children: [
                              _buildActivityCard(
                                icon: Icons.calendar_today_outlined,
                                title: 'Bookings',
                                iconColor: Colors.blue,
                                onTap: () => Get.to(() => MyBookingsScreen()),
                              ),
                              _buildActivityCard(
                                icon: Icons.shopping_cart_outlined,
                                title: 'Cart',
                                iconColor: Colors.green,
                                onTap: () => Get.to(() => CartScreen()),
                              ),
                              _buildActivityCard(
                                icon: Icons.edit,
                                title: 'Edit Profile',
                                iconColor: AppColors.primaryGold,
                                onTap: _showEditProfileDialog,
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.spaceLarge24),
                          _buildSectionTitle('Account Information'),
                          SizedBox(height: AppSizes.spaceMedium16),
                          Obx(() {
                            final user = _authController.currentUser.value;
                            if (user == null) return const SizedBox();

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.person_outline,
                                    title: 'Account Type',
                                    value: _authController.formattedRole,
                                  ),
                                  Divider(height: 1, color: Colors.grey[200]),
                                  if (user.branchName != null && user.branchName!.isNotEmpty)
                                    Column(
                                      children: [
                                        _buildInfoItem(
                                          icon: Icons.store_outlined,
                                          title: 'Branch',
                                          value: user.branchName!,
                                        ),
                                        Divider(height: 1, color: Colors.grey[200]),
                                      ],
                                    ),
                                  if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty)
                                    Column(
                                      children: [
                                        _buildInfoItem(
                                          icon: Icons.cake_outlined,
                                          title: 'Date of Birth',
                                          value: _authController.formattedDateOfBirth,
                                        ),
                                        Divider(height: 1, color: Colors.grey[200]),
                                      ],
                                    ),
                                  _buildInfoItem(
                                    icon: Icons.calendar_today_outlined,
                                    title: 'Member Since',
                                    value: user.createdAt != null
                                        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                                        : 'N/A',
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: AppSizes.spaceMedium16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  onTap: _showChangePasswordDialog,
                                  leading: Container(
                                    width: AppSizes.width(40),
                                    height: AppSizes.height(40),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: AppSizes.icon(20),
                                      color: Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: AppSizes.textMedium14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    size: AppSizes.icon(20),
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                ListTile(
                                  onTap: _showLogoutDialog,
                                  leading: Container(
                                    width: AppSizes.width(40),
                                    height: AppSizes.height(40),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      size: AppSizes.icon(20),
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: AppSizes.textMedium14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    size: AppSizes.icon(20),
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSizes.spaceLarge24),
                          Padding(
                            padding: EdgeInsets.only(bottom: AppSizes.spaceMedium16),
                            child: Text(
                              'App Version 1.0.0',
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[500],
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
          );
        },
      ),
    );
  }

  // Widget _buildReferralSection(bool isLandscape) {
  //   return StreamBuilder<DocumentSnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('customers')
  //         .doc(_authController.currentUser.value?.uid)
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (snapshot.hasError) {
  //         print('Error loading referral data: ${snapshot.error}');
  //         return const SizedBox();
  //       }
  //
  //       if (!snapshot.hasData) {
  //         return Padding(
  //           padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
  //           child: Container(
  //             height: AppSizes.height(120),
  //             child: Center(
  //               child: CircularProgressIndicator(
  //                 color: AppColors.primaryGold,
  //                 strokeWidth: AppSizes.width(2),
  //               ),
  //             ),
  //           ),
  //         );
  //       }
  //
  //       final data = snapshot.data!.data() as Map<String, dynamic>?;
  //       final referralCode = data?['referralCode'] as String?;
  //       final referralCount = (data?['referralCount'] as num?)?.toInt() ?? 0;
  //       final referralEarnings = (data?['referralEarnings'] as num?)?.toDouble() ?? 0.0;
  //
  //       if (referralCode == null || referralCode.isEmpty) {
  //         return const SizedBox();
  //       }
  //
  //       return Container(
  //         margin: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             _buildSectionTitle('Refer & Earn'),
  //             SizedBox(height: AppSizes.spaceMedium16),
  //             Container(
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.grey.withOpacity(0.1),
  //                     blurRadius: 10,
  //                     spreadRadius: 2,
  //                     offset: const Offset(0, 3),
  //                   ),
  //                 ],
  //                 border: Border.all(
  //                   color: AppColors.primaryGold.withOpacity(0.3),
  //                   width: 1,
  //                 ),
  //               ),
  //               child: Padding(
  //                 padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
  //                 child: Column(
  //                   children: [
  //                     // Header with Icon
  //                     Row(
  //                       children: [
  //                         Container(
  //                           padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
  //                           decoration: BoxDecoration(
  //                             color: AppColors.primaryGold.withOpacity(0.1),
  //                             borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                           ),
  //                           child: Icon(
  //                             Icons.card_giftcard,
  //                             size: isLandscape ? AppSizes.icon(20) : AppSizes.icon(24),
  //                             color: AppColors.primaryGold,
  //                           ),
  //                         ),
  //                         SizedBox(width: AppSizes.spaceSmall8),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 'Your Referral Code',
  //                                 style: TextStyle(
  //                                   fontSize: AppSizes.textSmall12,
  //                                   color: Colors.grey[600],
  //                                   letterSpacing: 1,
  //                                 ),
  //                               ),
  //                               SizedBox(height: AppSizes.spaceSmall8),
  //                               SelectableText(
  //                                 referralCode,
  //                                 style: TextStyle(
  //                                   fontSize: isLandscape ? AppSizes.font(18) : AppSizes.font(16),
  //                                   fontWeight: FontWeight.bold,
  //                                   color: AppColors.primaryGold,
  //                                   letterSpacing: 1,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         IconButton(
  //                           onPressed: () => _shareReferralCode(referralCode),
  //                           icon: Icon(
  //                             Icons.share,
  //                             size: isLandscape ? AppSizes.icon(20) : AppSizes.icon(24),
  //                             color: AppColors.primaryGold,
  //                           ),
  //                           tooltip: 'Share referral code',
  //                         ),
  //                       ],
  //                     ),
  //                     SizedBox(height: AppSizes.spaceMedium16),
  //
  //                     // Stats Row
  //                     Container(
  //                       padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey[50],
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                       ),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                         children: [
  //                           Expanded(
  //                             child: Column(
  //                               children: [
  //                                 Text(
  //                                   'Friends Referred',
  //                                   style: TextStyle(
  //                                     fontSize: AppSizes.textSmall12,
  //                                     color: Colors.grey[600],
  //                                   ),
  //                                 ),
  //                                 SizedBox(height: AppSizes.spaceSmall8),
  //                                 Text(
  //                                   '$referralCount',
  //                                   style: TextStyle(
  //                                     fontSize: isLandscape ? AppSizes.font(16) : AppSizes.font(18),
  //                                     fontWeight: FontWeight.bold,
  //                                     color: Colors.blue[700],
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           Container(
  //                             width: AppSizes.width(1),
  //                             height: AppSizes.height(30),
  //                             color: Colors.grey[300],
  //                           ),
  //                           Expanded(
  //                             child: Column(
  //                               children: [
  //                                 Text(
  //                                   'Earnings',
  //                                   style: TextStyle(
  //                                     fontSize: AppSizes.textSmall12,
  //                                     color: Colors.grey[600],
  //                                   ),
  //                                 ),
  //                                 SizedBox(height: AppSizes.spaceSmall8),
  //                                 Text(
  //                                   '${referralEarnings.toStringAsFixed(2)} AED',
  //                                   style: TextStyle(
  //                                     fontSize: isLandscape ? AppSizes.font(16) : AppSizes.font(18),
  //                                     fontWeight: FontWeight.bold,
  //                                     color: Colors.green[700],
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     SizedBox(height: AppSizes.spaceMedium16),
  //
  //                     // Info Message
  //                     Container(
  //                       padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
  //                       decoration: BoxDecoration(
  //                         color: AppColors.primaryGold.withOpacity(0.05),
  //                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
  //                       ),
  //                       child: Row(
  //                         children: [
  //                           Icon(
  //                             Icons.info_outline,
  //                             size: AppSizes.iconSmall14,
  //                             color: AppColors.primaryGold,
  //                           ),
  //                           SizedBox(width: AppSizes.spaceSmall8),
  //                           Expanded(
  //                             child: Text(
  //                               _referralController.getDiscountMessage(),
  //                               style: TextStyle(
  //                                 fontSize: AppSizes.textSmall12,
  //                                 color: AppColors.primaryGold,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             SizedBox(height: AppSizes.spaceMedium16),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: AppSizes.height(16),
          width: AppSizes.width(4),
          decoration: BoxDecoration(
            color: AppColors.primaryGold,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
          ),
        ),
        SizedBox(width: AppSizes.spaceSmall8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppSizes.icon(18),
                  color: iconColor,
                ),
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: AppSizes.paddingSymmetric(
        vertical: AppSizes.spaceSmall8,
        horizontal: AppSizes.spaceMedium16,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.width(36),
            height: AppSizes.height(36),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSizes.icon(18),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                Text(
                  value,
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
    );
  }
}