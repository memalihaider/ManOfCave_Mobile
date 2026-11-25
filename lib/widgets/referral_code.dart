// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:share_plus/share_plus.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_sizes.dart';
// import '../controlers/referral_controller.dart';
//
// class ReferralDialog extends StatelessWidget {
//   final String referralCode;
//   final String userName;
//   final String? discountMessage;
//
//   const ReferralDialog({
//     super.key,
//     required this.referralCode,
//     required this.userName,
//     this.discountMessage,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final referralController = Get.find<ReferralController>();
//     final message = discountMessage ?? referralController.getDiscountMessage();
//     final referrerMessage = referralController.getReferrerDiscountMessage();
//
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//       ),
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.85,
//         ),
//         padding: AppSizes.paddingAll(AppSizes.spaceLarge24),
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Icon
//               Container(
//                 padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryGold.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.card_giftcard,
//                   size: AppSizes.iconLarge32,
//                   color: AppColors.primaryGold,
//                 ),
//               ),
//               SizedBox(height: AppSizes.spaceMedium16),
//
//               // Title
//               Text(
//                 '🎉 Welcome to Jam Beauty Lounge! 🎉',
//                 style: TextStyle(
//                   fontSize: AppSizes.textLarge18,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primaryDark,
//                   letterSpacing: 0.5,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: AppSizes.spaceMedium16),
//
//               // Welcome Message
//               Text(
//                 'Hello $userName!',
//                 style: TextStyle(
//                   fontSize: AppSizes.textMedium14,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primaryGold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: AppSizes.spaceSmall8),
//
//               Text(
//                 'Share your unique referral code with friends and family!',
//                 style: TextStyle(
//                   fontSize: AppSizes.textMedium14,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: AppSizes.spaceMedium16),
//
//               // Friend Discount Info
//               Container(
//                 padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                   border: Border.all(
//                     color: Colors.blue.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.people_alt,
//                           size: AppSizes.iconSmall18,
//                           color: Colors.blue[700],
//                         ),
//                         SizedBox(width: AppSizes.spaceSmall8),
//                         Text(
//                           'For Your Friends:',
//                           style: TextStyle(
//                             fontSize: AppSizes.textMedium14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: AppSizes.spaceSmall8),
//                     Text(
//                       message,
//                       style: TextStyle(
//                         fontSize: AppSizes.textMedium14,
//                         color: Colors.blue[700],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: AppSizes.spaceMedium16),
//
//               // Referrer Discount Info
//               Container(
//                 padding: AppSizes.paddingAll(AppSizes.spaceMedium16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                   border: Border.all(
//                     color: Colors.green.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.emoji_events,
//                           size: AppSizes.iconSmall18,
//                           color: Colors.green[700],
//                         ),
//                         SizedBox(width: AppSizes.spaceSmall8),
//                         Text(
//                           'For You:',
//                           style: TextStyle(
//                             fontSize: AppSizes.textMedium14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: AppSizes.spaceSmall8),
//                     Text(
//                       referrerMessage,
//                       style: TextStyle(
//                         fontSize: AppSizes.textMedium14,
//                         color: Colors.green[700],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: AppSizes.spaceSmall8),
//                     Text(
//                       'Earn rewards every time your friends book or order!',
//                       style: TextStyle(
//                         fontSize: AppSizes.textSmall12,
//                         color: Colors.green[600],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: AppSizes.spaceLarge24),
//
//               // Referral Code Display
//               Container(
//                 width: double.infinity,
//                 padding: AppSizes.paddingSymmetric(
//                   vertical: AppSizes.spaceMedium16,
//                   horizontal: AppSizes.spaceSmall8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                   border: Border.all(
//                     color: AppColors.primaryGold.withOpacity(0.5),
//                     width: 2,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'YOUR REFERRAL CODE',
//                       style: TextStyle(
//                         fontSize: AppSizes.textSmall12,
//                         color: Colors.grey[600],
//                         letterSpacing: 1,
//                       ),
//                     ),
//                     SizedBox(height: AppSizes.spaceSmall8),
//                     SelectableText(
//                       referralCode,
//                       style: TextStyle(
//                         fontSize: AppSizes.font(18),
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primaryGold,
//                         letterSpacing: 2,
//                       ),
//                     ),
//                     SizedBox(height: AppSizes.spaceSmall8),
//                     Text(
//                       'Share this code with friends',
//                       style: TextStyle(
//                         fontSize: AppSizes.textSmall12,
//                         color: Colors.grey[500],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: AppSizes.spaceLarge24),
//
//               // Info Text
//               Container(
//                 padding: AppSizes.paddingAll(AppSizes.spaceSmall8),
//                 child: Text(
//                   'You can also find your referral code in the Profile screen',
//                   style: TextStyle(
//                     fontSize: AppSizes.textSmall12,
//                     color: Colors.grey[500],
//                     fontStyle: FontStyle.italic,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               SizedBox(height: AppSizes.spaceMedium16),
//
//               // Action Buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Get.back(),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.grey[600],
//                         side: BorderSide(color: Colors.grey[300]!),
//                         padding: AppSizes.paddingSymmetric(
//                           vertical: AppSizes.spaceMedium16,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                         ),
//                       ),
//                       child: Text(
//                         'Later',
//                         style: TextStyle(
//                           fontSize: AppSizes.textMedium14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: AppSizes.spaceMedium16),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _shareReferralCode(referralCode, userName);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryGold,
//                         foregroundColor: AppColors.white,
//                         padding: AppSizes.paddingSymmetric(
//                           vertical: AppSizes.spaceMedium16,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.share,
//                             size: AppSizes.iconSmall18,
//                           ),
//                           SizedBox(width: AppSizes.spaceSmall8),
//                           Text(
//                             'Share Now',
//                             style: TextStyle(
//                               fontSize: AppSizes.textMedium14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _shareReferralCode(String code, String userName) {
//     final referralController = Get.find<ReferralController>();
//     final discountMessage = referralController.getDiscountMessage();
//
//     final shareMessage = '''
// 🎉 Join me at Jam Beauty Lounge! 🎉
//
// Hello! I'm $userName and I'm loving Jam Beauty Lounge. Use my referral code to get amazing discounts!
//
// ✨ My Referral Code: $code ✨
//
// What you'll get:
// $discountMessage
//
// Download the app and enter this code during booking/order to get your discount!
//
// ''';
//
//     Share.share(shareMessage);
//     Get.back();
//   }
// }