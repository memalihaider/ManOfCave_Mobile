// // widgets/product_booking_card.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_sizes.dart';
// import '../models/booking_model.dart';
//
// class ProductBookingCard extends StatelessWidget {
//   final Booking booking;
//   final VoidCallback? onTrack;
//   final VoidCallback? onCancel;
//   final VoidCallback? onReorder;
//   final VoidCallback? onViewReceipt;
//
//   const ProductBookingCard({
//     super.key,
//     required this.booking,
//     this.onTrack,
//     this.onCancel,
//     this.onReorder,
//     this.onViewReceipt,
//   });
//
//   Color _getStatusColor(ProductStatus status) {
//     switch (status) {
//       case ProductStatus.ordered:
//         return Colors.blue;
//       case ProductStatus.processing:
//         return Colors.orange;
//       case ProductStatus.shipped:
//         return Colors.purple;
//       case ProductStatus.delivered:
//         return Colors.green;
//       case ProductStatus.cancelled:
//         return Colors.red;
//     }
//   }
//
//   String _getStatusText(ProductStatus status) {
//     switch (status) {
//       case ProductStatus.ordered:
//         return 'Ordered';
//       case ProductStatus.processing:
//         return 'Processing';
//       case ProductStatus.shipped:
//         return 'Shipped';
//       case ProductStatus.delivered:
//         return 'Delivered';
//       case ProductStatus.cancelled:
//         return 'Cancelled';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16.h),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//         border: Border.all(color: Colors.grey[200]!, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: EdgeInsets.all(16.w),
//             decoration: BoxDecoration(
//               color: _getStatusColor(booking.productStatus!).withOpacity(0.05),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(AppSizes.radiusMedium12),
//                 topRight: Radius.circular(AppSizes.radiusMedium12),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Order #${booking.id}',
//                       style: TextStyle(
//                         fontSize: AppSizes.textMedium14,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryDark,
//                       ),
//                     ),
//                     SizedBox(height: 4.h),
//                     Text(
//                       'Ordered on ${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}',
//                       style: TextStyle(
//                         fontSize: AppSizes.textSmall12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 8.w,
//                     vertical: 4.h,
//                   ),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(booking.productStatus!),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _getStatusText(booking.productStatus!),
//                     style: TextStyle(
//                       fontSize: 10.sp,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Products List
//           Padding(
//             padding: EdgeInsets.all(16.w),
//             child: Column(
//               children: [
//                 if (booking.products != null)
//                   ...booking.products!.map((product) {
//                     return Container(
//                       margin: EdgeInsets.only(bottom: 12.h),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 50.w,
//                             height: 50.h,
//                             decoration: BoxDecoration(
//                               color: AppColors.primaryGold.withOpacity(0.1),
//                               borderRadius:
//                               BorderRadius.circular(AppSizes.radius(8)),
//                               image: product.imageUrl != null
//                                   ? DecorationImage(
//                                 image: NetworkImage(product.imageUrl!),
//                                 fit: BoxFit.cover,
//                               )
//                                   : null,
//                             ),
//                             child: product.imageUrl == null
//                                 ? Icon(
//                               Icons.shopping_bag_outlined,
//                               size: 24.sp,
//                               color: AppColors.primaryGold,
//                             )
//                                 : null,
//                           ),
//                           SizedBox(width: 12.w),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   product.name,
//                                   style: TextStyle(
//                                     fontSize: AppSizes.textMedium14,
//                                     fontWeight: FontWeight.w600,
//                                     color: AppColors.primaryDark,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4.h),
//                                 Text(
//                                   'Qty: ${product.quantity} × د.إ${product.price}',
//                                   style: TextStyle(
//                                     fontSize: AppSizes.textSmall12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Text(
//                             'د.إ${(product.price * product.quantity).toStringAsFixed(2)}',
//                             style: TextStyle(
//                               fontSize: AppSizes.textMedium14,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.primaryDark,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//
//                 SizedBox(height: 12.h),
//
//                 // Shipping Address
//                 if (booking.shippingAddress != null)
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.location_on_outlined,
//                         size: 16.sp,
//                         color: Colors.grey[500],
//                       ),
//                       SizedBox(width: 8.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Shipping Address',
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primaryDark,
//                               ),
//                             ),
//                             SizedBox(height: 2.h),
//                             Text(
//                               booking.shippingAddress!,
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 SizedBox(height: 12.h),
//
//                 // Tracking & Delivery
//                 if (booking.trackingNumber != null)
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.local_shipping_outlined,
//                         size: 16.sp,
//                         color: Colors.grey[500],
//                       ),
//                       SizedBox(width: 8.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Tracking Number',
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primaryDark,
//                               ),
//                             ),
//                             SizedBox(height: 2.h),
//                             Text(
//                               booking.trackingNumber!,
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 color: AppColors.primaryGold,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 if (booking.trackingNumber != null) SizedBox(height: 12.h),
//
//                 if (booking.estimatedDelivery != null)
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.delivery_dining,
//                         size: 16.sp,
//                         color: Colors.grey[500],
//                       ),
//                       SizedBox(width: 8.w),
//                       Expanded(
//                         child: Text(
//                           'Estimated Delivery: ${booking.estimatedDelivery!.day}/${booking.estimatedDelivery!.month}/${booking.estimatedDelivery!.year}',
//                           style: TextStyle(
//                             fontSize: AppSizes.textSmall12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 if (booking.estimatedDelivery != null) SizedBox(height: 12.h),
//
//                 // Total Price
//                 Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(AppSizes.radius(8)),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Total Amount',
//                         style: TextStyle(
//                           fontSize: AppSizes.textMedium14,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.primaryDark,
//                         ),
//                       ),
//                       Text(
//                         'د.إ${booking.totalPrice.toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontSize: AppSizes.textMedium14,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.primaryGold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Actions
//           if (booking.productStatus != ProductStatus.delivered &&
//               booking.productStatus != ProductStatus.cancelled)
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!, width: 1),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   if (booking.productStatus == ProductStatus.shipped)
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: onTrack,
//                         icon: Icon(Icons.track_changes, size: 16.sp),
//                         label: Text(
//                           'Track Order',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primaryGold,
//                           foregroundColor: AppColors.white,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                   if (booking.productStatus == ProductStatus.ordered ||
//                       booking.productStatus == ProductStatus.processing)
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: onCancel,
//                         icon: Icon(Icons.cancel_outlined, size: 16.sp),
//                         label: Text(
//                           'Cancel Order',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(color: Colors.red),
//                           foregroundColor: Colors.red,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                   if (booking.productStatus == ProductStatus.delivered)
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: onReorder,
//                         icon: Icon(Icons.replay, size: 16.sp),
//                         label: Text(
//                           'Reorder',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(color: AppColors.primaryGold),
//                           foregroundColor: AppColors.primaryGold,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }