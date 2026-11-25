// lib/widgets/staff_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/staff.dart';

class StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showBranch;
  final bool compact;

  const StaffCard({
    super.key,
    required this.staff,
    this.onTap,
    this.showStatus = true,
    this.showBranch = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildFullCard() {
    return Container(
      margin: AppSizes.paddingOnly(bottom: AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
            offset: Offset(0, AppSizes.height(2)),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: AppSizes.paddingAll(AppSizes.spaceSmall8),
        leading: Container(
          width: AppSizes.width(55),
          height: AppSizes.height(55),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          ),
          child: staff.hasAvatar
              ? ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            child: Image.network(
              staff.avatar!,
              fit: BoxFit.cover,
            ),
          )
              : Center(
            child: Text(
              staff.initials,
              style: TextStyle(
                fontSize: AppSizes.textMedium14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        title: Text(
          staff.name,
          style: TextStyle(
            fontSize: AppSizes.textMedium14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staff.role,
              style: TextStyle(
                fontSize: AppSizes.textSmall12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.spaceSmall8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: AppSizes.iconSmall14,
                  color: Colors.amber,
                ),
                SizedBox(width: AppSizes.spaceSmall8),
                Text(
                  staff.formattedRating,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showStatus)
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.width(2),
                  vertical: AppSizes.height(2),
                ),
                decoration: BoxDecoration(
                  color: staff.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                child: Text(
                  staff.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.font(8),
                    fontWeight: FontWeight.w600,
                    color: staff.statusColor,
                  ),
                ),
              ),
            if (showStatus) SizedBox(height: AppSizes.spaceSmall8),
            if (showBranch && staff.branch.isNotEmpty)
              Text(
                staff.branch,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      margin: AppSizes.paddingOnly(bottom: AppSizes.spaceSmall8),
      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: AppSizes.width(40),
            height: AppSizes.height(40),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            ),
            child: staff.hasAvatar
                ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              child: Image.network(
                staff.avatar!,
                fit: BoxFit.cover,
              ),
            )
                : Center(
              child: Text(
                staff.initials,
                style: TextStyle(
                  fontSize: AppSizes.textSmall12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.spaceSmall8),

          // Middle section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: TextStyle(
                    fontSize: AppSizes.textMedium14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSizes.spaceSmall8),
                Wrap(
                  spacing: AppSizes.spaceSmall8,
                  runSpacing: AppSizes.spaceSmall8,
                  children: [
                    Container(
                      padding: AppSizes.paddingSymmetric(
                        horizontal: AppSizes.spaceSmall8,
                        vertical: AppSizes.spaceSmall8,
                      ),
                      decoration: BoxDecoration(
                        color: staff.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                      ),
                      child: Text(
                        staff.role,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall12,
                          color: staff.statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showBranch && staff.branch.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: AppSizes.iconSmall14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: AppSizes.spaceSmall8),
                          Flexible(
                            child: Text(
                              staff.branch,
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Right section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: AppSizes.iconSmall14,
                    color: Colors.amber,
                  ),
                  SizedBox(width: AppSizes.spaceSmall8),
                  Text(
                    staff.formattedRating,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceSmall8),
              Container(
                padding: AppSizes.paddingSymmetric(
                  horizontal: AppSizes.spaceSmall8,
                  vertical: AppSizes.spaceSmall8,
                ),
                decoration: BoxDecoration(
                  color: staff.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                ),
                child: Text(
                  staff.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    fontWeight: FontWeight.w600,
                    color: staff.statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Static method to create a list of staff cards
  static List<Widget> createStaffCards({
    required List<Staff> staffList,
    VoidCallback? onTap,
    bool showStatus = true,
    bool showBranch = true,
    bool compact = false,
    int? limit,
  }) {
    final limitedList = limit != null && staffList.length > limit
        ? staffList.sublist(0, limit)
        : staffList;

    return limitedList
        .map((staff) => StaffCard(
      staff: staff,
      onTap: onTap,
      showStatus: showStatus,
      showBranch: showBranch,
      compact: compact,
    ))
        .toList();
  }
}