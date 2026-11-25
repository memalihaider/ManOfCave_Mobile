// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_sizes.dart';
// import '../models/customer_model.dart';
//
// class LoyaltySummaryCard extends StatelessWidget {
//   final LoyaltySummary summary;
//
//   const LoyaltySummaryCard({
//     super.key,
//     required this.summary,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//       ),
//       child: Padding(
//         padding: AppSizes.paddingAll(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Loyalty Points Summary',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.primaryColorDark,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 1.8,
//               children: [
//                 _buildSummaryItem(
//                   label: 'Current Balance',
//                   value: summary.currentBalance.toString(),
//                   color: theme.primaryColor,
//                   theme: theme,
//                 ),
//                 _buildSummaryItem(
//                   label: 'Earned This Month',
//                   value: summary.earnedThisMonth.toString(),
//                   color: Colors.green,
//                   theme: theme,
//                 ),
//                 _buildSummaryItem(
//                   label: 'Total Redeemed',
//                   value: summary.totalRedeemed.toString(),
//                   color: Colors.orange,
//                   theme: theme,
//                 ),
//                 _buildSummaryItem(
//                   label: 'Total Earned',
//                   value: summary.totalEarned.toString(),
//                   color: Colors.blue,
//                   theme: theme,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem({
//     required String label,
//     required String value,
//     required Color color,
//     required ThemeData theme,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             value,
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: theme.textTheme.labelSmall?.copyWith(
//               color: theme.hintColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }