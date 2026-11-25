// widgets/promo_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/promo_code_model.dart';

class PromoCard extends StatelessWidget {
  final PromoCodeModel promo;

  const PromoCard({super.key, required this.promo});

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: promo.code));
    Get.snackbar(
      'Copied!',
      'Promo code copied to clipboard',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Color _getPromoColor() {
    if (promo.discountType == 'percentage') return Colors.blue;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final promoColor = _getPromoColor();
    final hasImage = promo.hasImage;

    return Container(
      width: AppSizes.width(280), // Fixed width for consistency
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
        image: hasImage
            ? DecorationImage(
          image: NetworkImage(promo.imageUrl!),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        )
            : null,
        gradient: !hasImage
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            promoColor.withOpacity(0.9),
            promoColor.withOpacity(0.7),
          ],
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: AppSizes.radius(AppSizes.spaceSmall8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyToClipboard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
          child: Container(
            padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
              gradient: hasImage
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ],
              )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and branches
                Row(
                  children: [
                    Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: AppSizes.icon(20),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceSmall8),
                    Expanded(
                      child: Text(
                        promo.branchNames.take(2).join(', ') +
                            (promo.branchNames.length > 2 ? ' +${promo.branchNames.length - 2}' : ''),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: AppSizes.textSmall12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                // Discount display
                Container(
                  padding: AppSizes.paddingSymmetric(
                    horizontal: AppSizes.spaceSmall8,
                    vertical: AppSizes.height(4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge20),
                  ),
                  child: Text(
                    promo.discountDisplay,
                    style: TextStyle(
                      fontSize: AppSizes.textMedium14,
                      fontWeight: FontWeight.bold,
                      color: promoColor,
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                // Description
                Text(
                  promo.description,
                  style: TextStyle(
                    fontSize: AppSizes.textSmall12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                // Promo code with copy button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        promo.code,
                        style: TextStyle(
                          fontSize: AppSizes.textLarge18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Container(
                      padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
                      ),
                      child: Icon(
                        Icons.copy,
                        color: AppColors.white,
                        size: AppSizes.icon(16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceSmall8),

                // Validity period
                Text(
                  promo.validityPeriod,
                  style: TextStyle(
                    fontSize: AppSizes.font(10),
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}