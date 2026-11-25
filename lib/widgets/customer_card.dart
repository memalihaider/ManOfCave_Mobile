// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../constants/app_sizes.dart';
// import '../models/customer_model.dart';
//
// class CustomerCard extends StatelessWidget {
//   final Customer customer;
//   final VoidCallback onTap;
//
//   const CustomerCard({
//     super.key,
//     required this.customer,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//     final dateFormat = DateFormat('M/d/yyyy');
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//         child: Padding(
//           padding: AppSizes.paddingAll(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Avatar
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: customer.status == 'active'
//                           ? theme.primaryColor.withOpacity(0.1)
//                           : Colors.grey.shade200,
//                       borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                     ),
//                     child: Center(
//                       child: Text(
//                         customer.avatarInitials,
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: customer.status == 'active'
//                               ? theme.primaryColor
//                               : Colors.grey.shade600,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(width: 16),
//
//                   // Customer Info
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           customer.name,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: theme.primaryColorDark,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           customer.email,
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             color: theme.hintColor,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//
//                         // Status Chip
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: customer.status == 'active'
//                                 ? Colors.green.withOpacity(0.1)
//                                 : Colors.grey.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: customer.status == 'active'
//                                   ? Colors.green.withOpacity(0.3)
//                                   : Colors.grey.withOpacity(0.3),
//                             ),
//                           ),
//                           child: Text(
//                             customer.status.toUpperCase(),
//                             style: theme.textTheme.labelSmall?.copyWith(
//                               color: customer.status == 'active'
//                                   ? Colors.green.shade700
//                                   : Colors.grey.shade700,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Points
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: theme.primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '${customer.points} points',
//                       style: theme.textTheme.labelMedium?.copyWith(
//                         color: theme.primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 16),
//
//               // Stats Row
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildStatItem(
//                     label: 'Total Spent',
//                     value: '\$${customer.totalSpent.toStringAsFixed(0)}',
//                     icon: Icons.attach_money,
//                     color: Colors.green,
//                     theme: theme,
//                   ),
//                   _buildStatItem(
//                     label: 'Total Bookings',
//                     value: customer.totalBookings.toString(),
//                     icon: Icons.calendar_today,
//                     color: Colors.blue,
//                     theme: theme,
//                   ),
//                   _buildStatItem(
//                     label: 'Member Since',
//                     value: dateFormat.format(customer.memberSince),
//                     icon: Icons.person_add,
//                     color: Colors.orange,
//                     theme: theme,
//                   ),
//                 ],
//               ),
//
//               if (customer.lastVisit != null) ...[
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.access_time,
//                       size: 16,
//                       color: theme.hintColor,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Last Visit: ${dateFormat.format(customer.lastVisit!)}',
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: theme.hintColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//
//               const SizedBox(height: 12),
//
//               // View History Button
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: OutlinedButton(
//                   onPressed: onTap,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     side: BorderSide(color: theme.dividerColor),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'View Complete History',
//                     style: theme.textTheme.labelMedium?.copyWith(
//                       color: theme.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatItem({
//     required String label,
//     required String value,
//     required IconData icon,
//     required Color color,
//     required ThemeData theme,
//   }) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Icon(
//               icon,
//               size: 14,
//               color: color,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               value,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.primaryColorDark,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: theme.textTheme.labelSmall?.copyWith(
//             color: theme.hintColor,
//           ),
//         ),
//       ],
//     );
//   }
// }