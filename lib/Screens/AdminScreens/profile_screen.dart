import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controlers/auth_controller.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';

class ProfileScreenAdmin extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  ProfileScreenAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Obx(() {
            final user = authController.currentUser.value;
            if (user == null) {
              return _buildNoUserFound();
            }

            return SingleChildScrollView(
              padding: AppSizes.paddingAll(isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceMedium16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  SizedBox(height: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceLarge24),

                  // Account Information
                  _buildAccountInfo(user, isLandscape),
                  SizedBox(height: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceLarge24),

                  // Settings Section
                  _buildSettingsSection(isLandscape),
                  SizedBox(height: isLandscape ? AppSizes.spaceSmall8 : AppSizes.spaceLarge24),

                  // Logout Button
                  _buildLogoutButton(isLandscape),
                  SizedBox(height: AppSizes.spaceLarge24),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          // Avatar
          Container(
            width: AppSizes.width(100),
            height: AppSizes.height(100),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getUserInitials(user.name),
                style: TextStyle(
                  fontSize: AppSizes.textExtraLarge22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceMedium16),

          // Name and Role
          Text(
            user.name,
            style: TextStyle(
              fontSize: AppSizes.textExtraLarge22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),

          // Role Badge
          Container(
            padding: AppSizes.paddingSymmetric(
              horizontal: AppSizes.spaceMedium16,
              vertical: AppSizes.spaceMedium16,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
              border: Border.all(
                color: _getRoleColor(user.role).withOpacity(0.3),
              ),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(user.role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(UserModel user, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Email
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              SizedBox(height: AppSizes.spaceMedium16),

              // Phone
              if (user.phone != null && user.phone!.isNotEmpty)
                Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone!,
                    ),
                    SizedBox(height: AppSizes.spaceMedium16),
                  ],
                ),

              // Account Age
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Member Since',
                value: '${_calculateDaysSince(user.createdAt)} days ago',
              ),
              SizedBox(height: AppSizes.spaceMedium16),

              // Status
              _buildInfoRow(
                icon: Icons.verified_outlined,
                label: 'Status',
                valueWidget: Container(
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.height(4),
                  ),
                  decoration: BoxDecoration(
                    color: user.status == 'active'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                  ),
                  child: Text(
                    user.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: user.status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSizes.spaceMedium16),

        Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Change Password
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  size: AppSizes.iconMedium24,
                  color: AppColors.primaryGold,
                ),
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: AppSizes.icon(16),
                  color: Colors.grey[400],
                ),
                onTap: _showChangePasswordDialog,
                contentPadding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),

              // Edit Profile
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  size: AppSizes.iconMedium24,
                  color: AppColors.primaryGold,
                ),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: AppSizes.icon(16),
                  color: Colors.grey[400],
                ),
                onTap: _showEditProfileDialog,
                contentPadding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceMedium16,
                  vertical: AppSizes.spaceSmall8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isLandscape) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
          elevation: 0,
        ),
        icon: Icon(Icons.logout, size: AppSizes.icon(20)),
        label: Text(
          'Logout',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: AppSizes.icon(80),
            color: Colors.grey[300],
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'No User Found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            'Please login to view your profile',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          ElevatedButton(
            onPressed: () {
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceMedium16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Go to Login',
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppSizes.icon(20),
          color: Colors.grey[600],
        ),
        SizedBox(width: AppSizes.spaceMedium16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              valueWidget ?? Text(
                value ?? 'Not provided',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'Change Password',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  contentPadding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  contentPadding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  contentPadding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
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
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                Get.snackbar(
                  'Error',
                  'Password must be at least 6 characters',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();

             authController.changePassword(
                 currentPassword: currentPasswordController.text.trim(),
                 newPassword: newPasswordController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceSmall8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Change Password',
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

  void _showEditProfileDialog() {
    final user = authController.currentUser.value;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  contentPadding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  contentPadding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.spaceSmall8,
                  ),
                ),
                keyboardType: TextInputType.phone,
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
              if (nameController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Name is required',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();

              final success = await authController.updateProfile(
                name: nameController.text,
                phone: phoneController.text,
              );

              if (success) {
                Get.snackbar(
                  'Success',
                  'Profile updated successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.white,
              padding: AppSizes.paddingSymmetric(
                horizontal: AppSizes.spaceLarge24,
                vertical: AppSizes.spaceSmall8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              'Save Changes',
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

  void _confirmLogout() {
    Get.defaultDialog(
      title: 'Confirm Logout',
      titleStyle: TextStyle(
        fontSize: AppSizes.textLarge18,
        fontWeight: FontWeight.bold,
      ),
      middleText: 'Are you sure you want to logout?',
      middleTextStyle: TextStyle(
        fontSize: AppSizes.textMedium14,
        color: Colors.grey[600],
      ),
      textConfirm: 'Logout',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        // Close the dialog first
        Get.back();

        // Show loading dialog
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
          await authController.logout();
          // Close loading dialog
          Get.back();
          // Navigate to login screen
          Get.offAll(() => LoginScreen());
        } catch (e) {
          // Close loading dialog
          Get.back();
          // Show error message
          Get.snackbar(
            'Error',
            'Failed to logout: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      buttonColor: Colors.red,
    );
  }

  String _getUserInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
      case 'branch_admin':
        return Colors.blue;
      case 'staff':
        return Colors.green;
      case 'customer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  int _calculateDaysSince(DateTime? date) {
    if (date == null) return 0;
    final now = DateTime.now();
    return now.difference(date).inDays;
  }
}