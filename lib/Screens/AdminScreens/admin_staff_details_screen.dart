// screens/admin_staff_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controlers/staff_controller.dart';
import '../../controlers/auth_controller.dart';
import '../../models/staff.dart';

class AdminStaffDetailsScreen extends StatefulWidget {
  final String staffId;

  const AdminStaffDetailsScreen({super.key, required this.staffId});

  @override
  State<AdminStaffDetailsScreen> createState() => _AdminStaffDetailsScreenState();
}

class _AdminStaffDetailsScreenState extends State<AdminStaffDetailsScreen> {
  final StaffController _controller = Get.find<StaffController>();
  final AuthController _authController = Get.find<AuthController>();
  final RxBool _isLoading = false.obs;
  final Rx<Staff?> _staff = Rx<Staff?>(null);

  String get userRole => _authController.currentUser.value?.role ?? 'customer';
  bool get isSuperAdmin => userRole == 'super_admin';
  bool get canEditStaff => isSuperAdmin || userRole == 'admin';

  @override
  void initState() {
    super.initState();
    _loadStaffDetails();
  }

  Future<void> _loadStaffDetails() async {
    _isLoading.value = true;
    final staff = await _controller.getStaffById(widget.staffId);
    _staff.value = staff;
    _isLoading.value = false;
  }

  Future<void> _updateStatus(bool isActive) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          isActive ? 'Activate Staff' : 'Deactivate Staff',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          isActive
              ? 'Are you sure you want to activate this staff member?'
              : 'Are you sure you want to deactivate this staff member?',
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            color: Colors.grey[700],
          ),
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
              backgroundColor: isActive ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
            ),
            child: Text(
              isActive ? 'Activate' : 'Deactivate',
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
      _isLoading.value = true;
      final success = await _controller.updateStaffStatus(widget.staffId, isActive);
      _isLoading.value = false;

      if (success) {
        await _loadStaffDetails();
        Get.snackbar(
          'Success',
          'Staff status updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _deleteStaff() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Delete Staff',
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
              'Are you sure you want to delete this staff member?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
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
      _isLoading.value = true;
      final success = await _controller.deleteStaff(widget.staffId);
      _isLoading.value = false;

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Staff deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.white,
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(isLandscape),
                  SizedBox(width: AppSizes.spaceMedium16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _staff.value?.name ?? 'Loading...',
                          style: TextStyle(
                            fontSize: AppSizes.textLarge18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSizes.height(4)),
                        Text(
                          _staff.value?.staffType ?? '',
                          style: TextStyle(
                            fontSize: AppSizes.textMedium14,
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppSizes.height(8)),
                        Row(
                          children: [
                            Container(
                              padding: AppSizes.paddingSymmetric(
                                horizontal: AppSizes.spaceSmall8,
                                vertical: AppSizes.height(4),
                              ),
                              decoration: BoxDecoration(
                                color: _staff.value?.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                                border: Border.all(
                                  color: _staff.value?.statusColor ?? Colors.grey,
                                ),
                              ),
                              child: Text(
                                _staff.value?.status.toUpperCase() ?? '',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  fontWeight: FontWeight.w500,
                                  color: _staff.value?.statusColor ?? Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: AppSizes.spaceSmall8),
                            Container(
                              padding: AppSizes.paddingSymmetric(
                                horizontal: AppSizes.spaceSmall8,
                                vertical: AppSizes.height(4),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Text(
                                _staff.value?.branch ?? '',
                                style: TextStyle(
                                  fontSize: AppSizes.textSmall12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceMedium16),
              _buildRatingRow(isLandscape),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(bool isLandscape) {
    final staff = _staff.value;
    final avatarSize = isLandscape ? AppSizes.width(60) : AppSizes.width(70);

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGold.withOpacity(0.1),
        border: Border.all(
          color: AppColors.primaryGold,
          width: 2,
        ),
      ),
      child: staff?.hasAvatar == true
          ? ClipOval(
        child: Image.network(
          staff!.avatar!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                staff.initials,
                style: TextStyle(
                  fontSize: AppSizes.textLarge18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGold,
                ),
              ),
            );
          },
        ),
      )
          : Center(
        child: Text(
          staff?.initials ?? '?',
          style: TextStyle(
            fontSize: AppSizes.textLarge18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(bool isLandscape) {
    final staff = _staff.value;
    return Row(
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: isLandscape ? AppSizes.iconSmall18 : AppSizes.icon(20),
            ),
            SizedBox(width: AppSizes.width(4)),
            Text(
              staff?.formattedRating ?? '0.0',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(width: AppSizes.width(4)),
            Text(
              staff?.formattedReviews ?? '(0 reviews)',
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.work_history,
              color: Colors.green,
              size: isLandscape ? AppSizes.iconSmall18 : AppSizes.iconSmall18,
            ),
            SizedBox(width: AppSizes.width(6)),
            Text(
              staff?.formattedExperience ?? '0 years',
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final staff = _staff.value;
    return Container(
      color: AppColors.white,
      padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showWeeklySchedule(staff!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGold.withOpacity(0.2),
                foregroundColor: AppColors.darkGold,
                elevation: 0,
                padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  side: BorderSide(
                    color: AppColors.darkGold,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Weekly Timings',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),
          Expanded(
            child: ElevatedButton(
              onPressed: _staff.value?.isActive == true
                  ? () => _updateStatus(false)
                  : () => _updateStatus(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _staff.value?.isActive == true
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                foregroundColor: _staff.value?.isActive == true
                    ? Colors.red
                    : Colors.green,
                elevation: 0,
                padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  side: BorderSide(
                    color: _staff.value?.isActive == true
                        ? Colors.red
                        : Colors.green,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                _staff.value?.isActive == true ? 'Deactivate' : 'Activate',
                style: TextStyle(
                  fontSize: AppSizes.textMedium14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.icon(20),
                  color: iconColor ?? AppColors.primaryGold,
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
            ),
          ),
          Divider(height: 0, thickness: 1, color: Colors.grey[200]),
          Padding(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: AppSizes.icon(16),
                color: Colors.grey[500],
              ),
            if (icon != null) SizedBox(width: AppSizes.spaceSmall8),
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
                  SizedBox(height: AppSizes.height(2)),
                  Text(
                    value.isNotEmpty ? value : 'N/A',
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceSmall8),
            child: Divider(
              height: 0,
              thickness: 1,
              color: Colors.grey[100],
            ),
          ),
      ],
    );
  }

  Widget _buildContactSection() {
    final staff = _staff.value;
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_page,
      child: Column(
        children: [
          _buildInfoItem(
            label: 'Email Address',
            value: staff?.email ?? '',
            icon: Icons.email,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Phone Number',
            value: staff?.formattedPhone ?? '',
            icon: Icons.phone,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Emergency Contact',
            value: staff?.emergencyContact ?? '',
            icon: Icons.emergency,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Address',
            value: staff?.formattedAddress ?? '',
            icon: Icons.location_on,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    final staff = _staff.value;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return _buildSection(
      title: 'Personal Details',
      icon: Icons.person,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Date of Birth',
                  value: staff?.dateOfBirth.isNotEmpty == true
                      ? '${staff!.dateOfBirth} (${staff.age} years)'
                      : '',
                  icon: Icons.cake,
                  showDivider: false,
                ),
              ),
              SizedBox(width: AppSizes.spaceMedium16),
              Expanded(
                child: _buildInfoItem(
                  label: 'Gender',
                  value: staff?.gender ?? '',
                  icon: Icons.transgender,
                  showDivider: false,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Marital Status',
                  value: staff?.maritalStatus ?? '',
                  icon: Icons.people,
                  showDivider: false,
                ),
              ),
              SizedBox(width: AppSizes.spaceMedium16),
              Expanded(
                child: _buildInfoItem(
                  label: 'Nationality',
                  value: staff?.nationality ?? '',
                  icon: Icons.flag,
                  showDivider: false,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Blood Group',
                  value: staff?.bloodGroupDisplay ?? '',
                  icon: Icons.bloodtype,
                  showDivider: false,
                ),
              ),
              SizedBox(width: AppSizes.spaceMedium16),
              Expanded(
                child: _buildInfoItem(
                  label: 'Hire Date',
                  value: staff?.formattedHireDate ?? '',
                  icon: Icons.date_range,
                  showDivider: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWeeklySchedule(Staff staff) {
    final schedule = staff.weeklySchedule;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

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
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Text(
              'Weekly Hours - ${staff.name}',
              style: TextStyle(
                fontSize: AppSizes.textLarge18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            Container(
              padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              ),
              child: Column(
                children: List.generate(days.length, (index) {
                  final day = days[index];
                  final dayKey = dayKeys[index];
                  final hours = schedule[dayKey] ?? 'Closed';
                  final isToday = DateTime.now().weekday - 1 == index;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index < days.length - 1 ? AppSizes.spaceSmall8 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: AppSizes.width(8),
                          height: AppSizes.height(8),
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primaryGold : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: AppSizes.width(8)),
                        SizedBox(
                          width: AppSizes.width(80),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              color: isToday ? AppColors.primaryDark : Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            hours,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              color: isToday ? AppColors.primaryGold : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: AppSizes.spaceMedium16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                  ),
                  padding: AppSizes.paddingSymmetric(vertical: AppSizes.spaceMedium16),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalSection() {
    final staff = _staff.value;

    return _buildSection(
      title: 'Professional Details',
      icon: Icons.work,
      child: Column(
        children: [
          _buildInfoItem(
            label: 'Role',
            value: staff?.staffType ?? '',
            icon: Icons.badge,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Branch',
            value: staff?.branch ?? '',
            icon: Icons.store,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Experience',
            value: '${staff?.experienceYears ?? 0} years (${staff?.experience ?? '0'} yrs)',
            icon: Icons.timeline,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Monthly Salary',
            value: staff?.formattedSalary ?? '0 ${AppStrings.appCurreny}',
            icon: Icons.attach_money,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Lunch Break',
            value: staff?.formattedLunchBreak ?? '',
            icon: Icons.free_breakfast,
            showDivider: true,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specializations',
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: AppSizes.height(4)),
              if (staff?.specialization.isNotEmpty == true)
                Wrap(
                  spacing: AppSizes.width(8),
                  runSpacing: AppSizes.height(8),
                  children: staff!.specialization.map((spec) {
                    return Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.height(6),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                      ),
                      child: Text(
                        spec,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  'No specializations',
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisaSection() {
    final staff = _staff.value;
    if (staff == null || !staff.hasVisaExpiry) return const SizedBox();

    return _buildSection(
      title: 'Visa Information',
      icon: Icons.credit_card,
      iconColor: staff.visaStatusColor,
      child: Column(
        children: [
          _buildInfoItem(
            label: 'Visa Expiry Date',
            value: staff.visaExpiry ?? '',
            icon: Icons.calendar_today,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Visa Status',
            value: staff.visaStatus,
            icon: Icons.info,
            valueColor: staff.visaStatusColor,
            showDivider: true,
          ),
          if (staff.daysUntilVisaExpiry != null)
            _buildInfoItem(
              label: 'Days Remaining',
              value: '${staff.daysUntilVisaExpiry!} days',
              icon: Icons.timer,
              valueColor: staff.isVisaExpired ? Colors.red : Colors.green,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _buildSystemSection() {
    final staff = _staff.value;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return _buildSection(
      title: 'System Information',
      icon: Icons.settings,
      child: Column(
        children: [
          _buildInfoItem(
            label: 'Staff ID',
            value: staff?.displayDocumentId ?? '',
            icon: Icons.fingerprint,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Created At',
            value: staff?.createdAt != null
                ? dateFormat.format(staff!.createdAt)
                : '',
            icon: Icons.add_circle,
            showDivider: true,
          ),
          _buildInfoItem(
            label: 'Last Updated',
            value: staff?.updatedAt != null
                ? dateFormat.format(staff!.updatedAt)
                : '',
            icon: Icons.update,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final staff = _staff.value;
    if (staff?.description == null || staff!.description!.isEmpty) {
      return const SizedBox();
    }

    return _buildSection(
      title: 'Description',
      icon: Icons.description,
      child: Text(
        staff.description!,
        style: TextStyle(
          fontSize: AppSizes.textMedium14,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
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
        title: Text(
          'Staff Details',
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
      body: Obx(() {
        if (_isLoading.value && _staff.value == null) {
          return _buildLoadingState();
        }

        if (_staff.value == null) {
          return _buildErrorState();
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: AppSizes.spaceSmall8),
              _buildActionButtons(),
              SizedBox(height: AppSizes.spaceSmall8),
              Padding(
                padding: AppSizes.paddingSymmetric(horizontal: AppSizes.spaceMedium16),
                child: Column(
                  children: [
                    _buildContactSection(),
                    _buildPersonalSection(),
                    _buildProfessionalSection(),
                    _buildVisaSection(),
                    _buildDescriptionSection(),
                    _buildSystemSection(),
                    SizedBox(height: AppSizes.spaceLarge24),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGold),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'Loading staff details...',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconLarge60,
            color: Colors.red,
          ),
          SizedBox(height: AppSizes.spaceMedium16),
          Text(
            'Staff not found',
            style: TextStyle(
              fontSize: AppSizes.textLarge18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSizes.spaceSmall8),
          Text(
            'The staff member you\'re looking for doesn\'t exist',
            style: TextStyle(
              fontSize: AppSizes.textMedium14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: AppSizes.spaceLarge24),
          ElevatedButton(
            onPressed: () => Get.back(),
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
}