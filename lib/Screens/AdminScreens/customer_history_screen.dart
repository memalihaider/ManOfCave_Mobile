// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
//
// import '../../constants/app_sizes.dart';
// import '../../controlers/admin_report_controller.dart';
// import '../../models/customer_model.dart';
// import '../../widgets/loyalty_card.dart';
//
// class CustomerHistoryScreen extends StatelessWidget {
//   final Customer customer;
//   final ReportsController controller = Get.find<ReportsController>();
//
//   CustomerHistoryScreen({
//     super.key,
//     required this.customer,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//     final dateFormat = DateFormat('M/d/yyyy');
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Customer History: ${customer.name}'),
//         centerTitle: true,
//       ),
//       body: Obx(() {
//         final history = controller.selectedCustomer.value;
//
//         if (history == null) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//
//         return SingleChildScrollView(
//           padding: AppSizes.paddingAll(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Customer Info Card
//               Card(
//                 elevation: 1,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                 ),
//                 child: Padding(
//                   padding: AppSizes.paddingAll(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 60,
//                             height: 60,
//                             decoration: BoxDecoration(
//                               color: theme.primaryColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 customer.avatarInitials,
//                                 style: theme.textTheme.titleLarge?.copyWith(
//                                   color: theme.primaryColor,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   customer.name,
//                                   style: theme.textTheme.titleLarge?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: theme.primaryColorDark,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   customer.email,
//                                   style: theme.textTheme.bodyMedium?.copyWith(
//                                     color: theme.hintColor,
//                                   ),
//                                 ),
//                                 if (customer.phone != null) ...[
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     customer.phone!,
//                                     style: theme.textTheme.bodyMedium?.copyWith(
//                                       color: theme.hintColor,
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: theme.primaryColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               '${customer.points} points',
//                               style: theme.textTheme.labelMedium?.copyWith(
//                                 color: theme.primaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Complete booking history, transactions, and loyalty activity',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Loyalty Summary
//               LoyaltySummaryCard(summary: history.loyaltySummary),
//
//               const SizedBox(height: 16),
//
//               // Booking History
//               _buildSectionTitle('Booking History', theme),
//               Card(
//                 elevation: 1,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 24,
//                       horizontalMargin: 0,
//                       columns: [
//                         DataColumn(label: Text('Booking ID', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Date', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Service', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Staff', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Status', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Amount', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Points Earned', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                       ],
//                       rows: history.bookings.map((booking) {
//                         return DataRow(cells: [
//                           DataCell(Text(booking.bookingId, style: theme.textTheme.bodyMedium)),
//                           DataCell(Text(dateFormat.format(booking.date), style: theme.textTheme.bodyMedium)),
//                           DataCell(Text(booking.service, style: theme.textTheme.bodyMedium)),
//                           DataCell(Text(booking.staff, style: theme.textTheme.bodyMedium)),
//                           DataCell(
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: _getStatusColor(booking.status).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 booking.status,
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: _getStatusColor(booking.status),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           DataCell(Text('\$${booking.amount.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium)),
//                           DataCell(
//                             Text(
//                               '+${booking.pointsEarned}',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 color: Colors.green.shade700,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Feedback History
//               _buildSectionTitle('Feedback History', theme),
//               ...history.feedbacks.map((feedback) {
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                   ),
//                   child: Padding(
//                     padding: AppSizes.paddingAll(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               dateFormat.format(feedback.date),
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: feedback.status == 'responded'
//                                     ? Colors.green.withOpacity(0.1)
//                                     : Colors.orange.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 feedback.status,
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: feedback.status == 'responded'
//                                       ? Colors.green.shade700
//                                       : Colors.orange.shade700,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           feedback.comment,
//                           style: theme.textTheme.bodyMedium,
//                         ),
//                         if (feedback.response != null) ...[
//                           const SizedBox(height: 12),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.withOpacity(0.05),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Response:',
//                                   style: theme.textTheme.labelMedium?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue.shade700,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   feedback.response!,
//                                   style: theme.textTheme.bodyMedium,
//                                 ),
//                                 if (feedback.respondedOn != null) ...[
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'Responded on ${dateFormat.format(feedback.respondedOn!)}',
//                                     style: theme.textTheme.labelSmall?.copyWith(
//                                       color: theme.hintColor,
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//
//               const SizedBox(height: 16),
//
//               // Loyalty Points History
//               _buildSectionTitle('Loyalty Points History', theme),
//               Card(
//                 elevation: 1,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: DataTable(
//                       columnSpacing: 24,
//                       horizontalMargin: 0,
//                       columns: [
//                         DataColumn(label: Text('Date', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Type', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Description', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Points', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                         DataColumn(label: Text('Balance', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
//                       ],
//                       rows: history.loyaltyTransactions.map((transaction) {
//                         final isPositive = transaction.points > 0;
//                         return DataRow(cells: [
//                           DataCell(Text(dateFormat.format(transaction.date), style: theme.textTheme.bodyMedium)),
//                           DataCell(
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: _getTransactionColor(transaction.type).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 transaction.type,
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: _getTransactionColor(transaction.type),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           DataCell(Text(transaction.description, style: theme.textTheme.bodyMedium)),
//                           DataCell(
//                             Text(
//                               '${isPositive ? '+' : ''}${transaction.points}',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           DataCell(
//                             Text(
//                               transaction.balance.toString(),
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ]);
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 32),
//             ],
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildSectionTitle(String title, ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Text(
//         title,
//         style: theme.textTheme.titleMedium?.copyWith(
//           fontWeight: FontWeight.bold,
//           color: theme.primaryColorDark,
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//         return Colors.green.shade600;
//       case 'pending':
//         return Colors.orange.shade600;
//       case 'cancelled':
//         return Colors.red.shade600;
//       default:
//         return Colors.grey.shade600;
//     }
//   }
//
//   Color _getTransactionColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'earned':
//         return Colors.green.shade600;
//       case 'redeemed':
//         return Colors.orange.shade600;
//       case 'bonus':
//         return Colors.blue.shade600;
//       default:
//         return Colors.grey.shade600;
//     }
//   }
// }