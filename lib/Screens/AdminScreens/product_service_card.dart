// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:man_of_cave/Screens/AdminScreens/product_service_model.dart';
//
// import '../../constants/app_sizes.dart';
//
//
// class ProductCard extends StatelessWidget {
//   final Product product;
//   final VoidCallback onEdit;
//   final VoidCallback onToggleStatus;
//   final VoidCallback onDelete;
//
//   const ProductCard({
//     super.key,
//     required this.product,
//     required this.onEdit,
//     required this.onToggleStatus,
//     required this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//       ),
//       child: Padding(
//         padding: AppSizes.paddingAll(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Product Image/Icon
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: product.isActive
//                         ? theme.primaryColor.withOpacity(0.1)
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                     image: product.images.isNotEmpty
//                         ? DecorationImage(
//                       image: NetworkImage(product.images.first),
//                       fit: BoxFit.cover,
//                     )
//                         : null,
//                   ),
//                   child: product.images.isEmpty
//                       ? Center(
//                     child: Icon(
//                       Icons.shopping_bag,
//                       color: product.isActive
//                           ? theme.primaryColor
//                           : Colors.grey.shade600,
//                       size: 30,
//                     ),
//                   )
//                       : null,
//                 ),
//
//                 const SizedBox(width: 16),
//
//                 // Product Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               product.name,
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: theme.primaryColorDark,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: product.isActive
//                                   ? Colors.green.withOpacity(0.1)
//                                   : Colors.grey.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: product.isActive
//                                     ? Colors.green.withOpacity(0.3)
//                                     : Colors.grey.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Text(
//                               product.isActive ? 'Active' : 'Inactive',
//                               style: theme.textTheme.labelSmall?.copyWith(
//                                 color: product.isActive
//                                     ? Colors.green.shade700
//                                     : Colors.grey.shade700,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 4),
//
//                       Text(
//                         product.description,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       // Stats Row
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _buildStatItem(
//                             label: 'Price',
//                             value: '\$${product.price.toStringAsFixed(2)}',
//                             color: Colors.green,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'Cost',
//                             value: '\$${product.cost.toStringAsFixed(2)}',
//                             color: Colors.orange,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'Stock',
//                             value: product.stock.toString(),
//                             color: product.stock < 10 ? Colors.red : Colors.blue,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'SKU',
//                             value: product.sku,
//                             color: Colors.purple,
//                             theme: theme,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 // Delete Button
//                 IconButton(
//                   onPressed: onDelete,
//                   icon: const Icon(Icons.delete_outline),
//                   color: Colors.red.shade400,
//                   tooltip: 'Delete',
//                 ),
//
//                 // Toggle Status Button
//                 IconButton(
//                   onPressed: onToggleStatus,
//                   icon: Icon(
//                     product.isActive ? Icons.toggle_on : Icons.toggle_off,
//                     color: product.isActive ? Colors.green : Colors.grey,
//                   ),
//                   tooltip: product.isActive ? 'Deactivate' : 'Activate',
//                 ),
//
//                 // Edit Button
//                 ElevatedButton(
//                   onPressed: onEdit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: theme.primaryColor,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Edit',
//                     style: theme.textTheme.labelMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
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
//         Text(
//           value,
//           style: theme.textTheme.bodyMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
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
//
// class ServiceCard extends StatelessWidget {
//   final Service service;
//   final VoidCallback onEdit;
//   final VoidCallback onToggleStatus;
//   final VoidCallback onDelete;
//
//   const ServiceCard({
//     super.key,
//     required this.service,
//     required this.onEdit,
//     required this.onToggleStatus,
//     required this.onDelete,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//       ),
//       child: Padding(
//         padding: AppSizes.paddingAll(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Service Image/Icon
//                 Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: service.isActive
//                         ? theme.primaryColor.withOpacity(0.1)
//                         : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//                     image: service.images.isNotEmpty
//                         ? DecorationImage(
//                       image: NetworkImage(service.images.first),
//                       fit: BoxFit.cover,
//                     )
//                         : null,
//                   ),
//                   child: service.images.isEmpty
//                       ? Center(
//                     child: Icon(
//                       Icons.spa,
//                       color: service.isActive
//                           ? theme.primaryColor
//                           : Colors.grey.shade600,
//                       size: 30,
//                     ),
//                   )
//                       : null,
//                 ),
//
//                 const SizedBox(width: 16),
//
//                 // Service Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               service.name,
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: theme.primaryColorDark,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: service.isActive
//                                   ? Colors.green.withOpacity(0.1)
//                                   : Colors.grey.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: service.isActive
//                                     ? Colors.green.withOpacity(0.3)
//                                     : Colors.grey.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Text(
//                               service.isActive ? 'Active' : 'Inactive',
//                               style: theme.textTheme.labelSmall?.copyWith(
//                                 color: service.isActive
//                                     ? Colors.green.shade700
//                                     : Colors.grey.shade700,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 4),
//
//                       Text(
//                         service.description,
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       // Stats Row
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _buildStatItem(
//                             label: 'Price',
//                             value: '\$${service.price.toStringAsFixed(2)}',
//                             color: Colors.green,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'Duration',
//                             value: '${service.duration} min',
//                             color: Colors.blue,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'Room',
//                             value: service.roomId ?? 'Any',
//                             color: Colors.purple,
//                             theme: theme,
//                           ),
//                           _buildStatItem(
//                             label: 'Type',
//                             value: service.requiresRoom ? 'Room' : 'Anywhere',
//                             color: Colors.orange,
//                             theme: theme,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 16),
//
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 // Delete Button
//                 IconButton(
//                   onPressed: onDelete,
//                   icon: const Icon(Icons.delete_outline),
//                   color: Colors.red.shade400,
//                   tooltip: 'Delete',
//                 ),
//
//                 // Toggle Status Button
//                 IconButton(
//                   onPressed: onToggleStatus,
//                   icon: Icon(
//                     service.isActive ? Icons.toggle_on : Icons.toggle_off,
//                     color: service.isActive ? Colors.green : Colors.grey,
//                   ),
//                   tooltip: service.isActive ? 'Deactivate' : 'Activate',
//                 ),
//
//                 // Edit Button
//                 ElevatedButton(
//                   onPressed: onEdit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: theme.primaryColor,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Edit',
//                     style: theme.textTheme.labelMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
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
//         Text(
//           value,
//           style: theme.textTheme.bodyMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 2),
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