// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../constants/app_sizes.dart';
// import '../../controlers/admin_report_controller.dart';
// import '../../widgets/customer_card.dart';
// import 'customer_history_screen.dart';
//
// class CustomerLoyaltyScreen extends StatelessWidget {
//   CustomerLoyaltyScreen({super.key});
//
//   final ReportsController controller = Get.put(ReportsController());
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Customer Loyalty"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: controller.refreshData,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Header Section
//           Container(
//             padding: AppSizes.paddingAll(16),
//             color: theme.cardColor,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Customer Loyalty Overview',
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.primaryColorDark,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Track customer loyalty points, booking history, and engagement metrics',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.hintColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Search customers by name or email...',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.hintColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Search Bar
//           Padding(
//             padding: AppSizes.paddingAll(16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     blurRadius: 5,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 onChanged: controller.searchCustomers,
//                 decoration: InputDecoration(
//                   hintText: 'Search customers...',
//                   prefixIcon: const Icon(Icons.search),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           // Statistics Overview
//           Obx(() => Container(
//             padding: AppSizes.paddingAll(16),
//             decoration: BoxDecoration(
//               color: theme.primaryColor.withOpacity(0.05),
//               border: Border(
//                 bottom: BorderSide(color: theme.dividerColor),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildStatItem(
//                   label: 'Total Customers',
//                   value: controller.totalCustomers.toString(),
//                   color: theme.primaryColor,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Active',
//                   value: controller.activeCustomers.toString(),
//                   color: Colors.green,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Total Revenue',
//                   value: '\$${controller.totalRevenue.toStringAsFixed(0)}',
//                   color: Colors.blue,
//                   theme: theme,
//                 ),
//                 _buildStatItem(
//                   label: 'Total Points',
//                   value: controller.totalPoints.toString(),
//                   color: Colors.orange,
//                   theme: theme,
//                 ),
//               ],
//             ),
//           )),
//
//           // Customers List
//           Expanded(
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }
//
//               if (controller.filteredCustomers.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.people,
//                         size: 60,
//                         color: theme.hintColor.withOpacity(0.5),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         controller.searchQuery.isEmpty
//                             ? 'No customers found'
//                             : 'No customers match your search',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                       ),
//                       if (controller.searchQuery.isNotEmpty)
//                         TextButton(
//                           onPressed: () => controller.searchCustomers(''),
//                           child: Text(
//                             'Clear search',
//                             style: TextStyle(color: theme.primaryColor),
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               }
//
//               return RefreshIndicator(
//                 onRefresh: () async {
//                   controller.refreshData();
//                 },
//                 child: ListView.builder(
//                   padding: AppSizes.paddingAll(16),
//                   itemCount: controller.filteredCustomers.length,
//                   itemBuilder: (context, index) {
//                     final customer = controller.filteredCustomers[index];
//                     return CustomerCard(
//                       customer: customer,
//                       onTap: () {
//                         controller.loadCustomerHistory(customer.id);
//                         Get.to(
//                               () => CustomerHistoryScreen(customer: customer),
//                           transition: Transition.rightToLeft,
//                         );
//                       },
//                     );
//                   },
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem({
//     required String label,
//     required String value,
//     required Color color,
//     required ThemeData theme,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: Text(
//               value,
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ),
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