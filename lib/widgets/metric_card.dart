import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subText;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.primaryDark,
    this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAll(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius(16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.font(14),
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.font(20),
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(
              subText!,
              style: TextStyle(
                fontSize: AppSizes.font(12),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}