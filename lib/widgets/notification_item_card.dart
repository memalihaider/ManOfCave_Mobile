import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../models/notification_model.dart';

class NotificationItemCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: AppSizes.paddingOnly(right: AppSizes.spaceMedium16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: AppSizes.iconMedium24,
        ),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        child: Container(
          padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.white : AppColors.primaryGold.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
            border: Border.all(
              color: notification.isRead ? Colors.grey[200]! : AppColors.primaryGold.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: AppSizes.width(48),
                height: AppSizes.height(48),
                decoration: BoxDecoration(
                  color: notification.typeData.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
                ),
                child: Icon(
                  notification.typeData.icon,
                  size: AppSizes.iconMedium24,
                  color: notification.typeData.color,
                ),
              ),
              SizedBox(width: AppSizes.spaceSmall8,),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: AppSizes.textMedium14,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.spaceSmall8,),
                        Text(
                          notification.formattedTime,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall8,),

                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Type badge
                    SizedBox(height: AppSizes.spaceSmall8,),
                    Row(
                      children: [
                        Container(
                          padding: AppSizes.paddingSymmetric(
                            horizontal: AppSizes.spaceSmall8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: notification.typeData.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                          ),
                          child: Text(
                            notification.typeData.name,
                            style: TextStyle(
                              fontSize: AppSizes.textSmall12,
                              color: notification.typeData.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (notification.priority != NotificationPriority.normal) ...[

                          Container(
                            padding: AppSizes.paddingSymmetric(
                              horizontal: AppSizes.spaceSmall8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.priorityData.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                            ),
                            child: Text(
                              notification.priorityData.name,
                              style: TextStyle(
                                fontSize: AppSizes.textSmall12,
                                color: notification.priorityData.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: AppSizes.width(8),
                  height: AppSizes.height(8),
                  margin: EdgeInsets.only(left: AppSizes.spaceSmall8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}