// // widgets/service_booking_card.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_sizes.dart';
// import '../controlers/booking_controller.dart';
// import '../models/booking_model.dart';
//
// class ServiceBookingCard extends StatelessWidget {
//   final Booking booking;
//   final VoidCallback? onCancel;
//   final VoidCallback? onReschedule;
//   final VoidCallback? onViewQR;
//   final VoidCallback? onAddCalendar;
//   final VoidCallback? onViewReceipt;
//   final bool showAdminActions; // For admin vs customer view
//
//   const ServiceBookingCard({
//     super.key,
//     required this.booking,
//     this.onCancel,
//     this.onReschedule,
//     this.onViewQR,
//     this.onAddCalendar,
//     this.onViewReceipt,
//     this.showAdminActions = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bookingController = Get.find<BookingController>();
//     final isActionable = booking.isPending || booking.isConfirmed || booking.isInProgress;
//     final showConfirmButton = booking.isPending && showAdminActions;
//     final showStartButton = booking.isConfirmed && showAdminActions;
//     final showCompleteButton = booking.isInProgress && showAdminActions;
//     final showStatusButtons = showAdminActions && (showConfirmButton || showStartButton || showCompleteButton);
//     final showCustomerActions = isActionable && !showAdminActions;
//
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
//           // Header with Status
//           Container(
//             padding: EdgeInsets.all(16.w),
//             decoration: BoxDecoration(
//               color: booking.statusColor.withOpacity(0.05),
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
//                       'Booking #${booking.id.substring(0, 8)}...',
//                       style: TextStyle(
//                         fontSize: AppSizes.textMedium14,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryDark,
//                       ),
//                     ),
//                     SizedBox(height: 4.h),
//                     Text(
//                       '${booking.formattedDate} • ${booking.timeSlot}',
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
//                     color: booking.statusColor,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     booking.statusText.toUpperCase(),
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
//           // Service Details
//           Padding(
//             padding: EdgeInsets.all(16.w),
//             child: Column(
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Service Image
//                     Container(
//                       width: 60.w,
//                       height: 60.h,
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryGold.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
//                         image: booking.serviceImageUrl.isNotEmpty
//                             ? DecorationImage(
//                           image: NetworkImage(booking.serviceImageUrl),
//                           fit: BoxFit.cover,
//                         )
//                             : null,
//                       ),
//                       child: booking.serviceImageUrl.isEmpty
//                           ? Icon(
//                         Icons.spa_outlined,
//                         size: 28.sp,
//                         color: AppColors.primaryGold,
//                       )
//                           : null,
//                     ),
//                     SizedBox(width: 12.w),
//
//                     // Service Info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             booking.serviceName,
//                             style: TextStyle(
//                               fontSize: AppSizes.textMedium14,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.primaryDark,
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             '${booking.durationFormatted} • د.إ${booking.servicePrice.toStringAsFixed(2)}',
//                             style: TextStyle(
//                               fontSize: AppSizes.textSmall12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           SizedBox(height: 8.h),
//
//                           // Staff Info
//                           if (booking.staffName.isNotEmpty)
//                             Row(
//                               children: [
//                                 Container(
//                                   width: 24.w,
//                                   height: 24.h,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: AppColors.primaryGold,
//                                       width: 1,
//                                     ),
//                                   ),
//                                   child: Icon(
//                                     Icons.person,
//                                     size: 14.sp,
//                                     color: AppColors.primaryGold,
//                                   ),
//                                 ),
//                                 SizedBox(width: 8.w),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         booking.staffName,
//                                         style: TextStyle(
//                                           fontSize: AppSizes.textSmall12,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                       if (booking.staffRole.isNotEmpty)
//                                         Text(
//                                           booking.staffRole,
//                                           style: TextStyle(
//                                             fontSize: AppSizes.font(9),
//                                             color: Colors.grey[500],
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16.h),
//
//                 // Branch Details
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.location_on_outlined,
//                       size: 16.sp,
//                       color: Colors.grey[500],
//                     ),
//                     SizedBox(width: 8.w),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             booking.branchNames.isNotEmpty ? booking.branchNames.first : 'No Branch',
//                             style: TextStyle(
//                               fontSize: AppSizes.textSmall12,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.primaryDark,
//                             ),
//                           ),
//                           SizedBox(height: 2.h),
//                           Text(
//                             booking.serviceCategory,
//                             style: TextStyle(
//                               fontSize: AppSizes.textSmall12,
//                               color: Colors.grey[600],
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12.h),
//
//                 // Customer Info
//                 Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         Icons.person_outline,
//                         size: 16.sp,
//                         color: Colors.grey[500],
//                       ),
//                       SizedBox(width: 8.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               booking.customerName,
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primaryDark,
//                               ),
//                             ),
//                             SizedBox(height: 2.h),
//                             Text(
//                               booking.customerPhone,
//                               style: TextStyle(
//                                 fontSize: AppSizes.textSmall12,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             if (booking.customerEmail.isNotEmpty)
//                               Text(
//                                 booking.customerEmail,
//                                 style: TextStyle(
//                                   fontSize: AppSizes.font(9),
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 12.h),
//
//                 // Total Price
//                 Container(
//                   padding: EdgeInsets.all(12.w),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(AppSizes.radiusSmall6),
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
//                         'د.إ${booking.totalAmount.toStringAsFixed(2)}',
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
//           // Admin Status Action Buttons
//           if (showStatusButtons)
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!, width: 1),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   if (showConfirmButton)
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () async {
//                           // Use BookingController to confirm booking
//                           await bookingController.updateBookingStatus(
//                             bookingId: booking.id,
//                             status: 'confirmed',
//                           );
//                         },
//                         icon: Icon(Icons.check_circle, size: 16.sp),
//                         label: Text(
//                           'Confirm',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                   if (showStartButton)
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () async {
//                           // Use BookingController to start service
//                           await bookingController.updateBookingStatus(
//                             bookingId: booking.id,
//                             status: 'in-progress',
//                           );
//                         },
//                         icon: Icon(Icons.play_arrow, size: 16.sp),
//                         label: Text(
//                           'Start Service',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                   if (showCompleteButton)
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () async {
//                           // Use BookingController to complete booking
//                           await bookingController.updateBookingStatus(
//                             bookingId: booking.id,
//                             status: 'completed',
//                           );
//                         },
//                         icon: Icon(Icons.check_circle_outline, size: 16.sp),
//                         label: Text(
//                           'Complete',
//                           style: TextStyle(fontSize: AppSizes.textSmall12),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 10.h),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//           // Customer Actions (Cancel/Reschedule)
//           if (showCustomerActions)
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!, width: 1),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () async {
//                         if (onCancel != null) {
//                           onCancel!();
//                         } else {
//                           // Default cancel action using BookingController
//                           await bookingController.cancelBooking(booking.id);
//                         }
//                       },
//                       icon: Icon(Icons.cancel_outlined, size: 16.sp),
//                       label: Text(
//                         'Cancel',
//                         style: TextStyle(fontSize: AppSizes.textSmall12),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: Colors.red),
//                         foregroundColor: Colors.red,
//                         padding: EdgeInsets.symmetric(vertical: 10.h),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8.w),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {
//                         if (onReschedule != null) {
//                           onReschedule!();
//                         } else {
//                           // Default reschedule action - navigate to reschedule screen
//                           Get.toNamed('/reschedule', arguments: booking);
//                         }
//                       },
//                       icon: Icon(Icons.schedule, size: 16.sp),
//                       label: Text(
//                         'Reschedule',
//                         style: TextStyle(fontSize: AppSizes.textSmall12),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: AppColors.primaryGold),
//                         foregroundColor: AppColors.primaryGold,
//                         padding: EdgeInsets.symmetric(vertical: 10.h),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Additional Actions for Confirmed Bookings
//           if (booking.isConfirmed && !showAdminActions)
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
//               child: Wrap(
//                 spacing: 8.w,
//                 runSpacing: 8.h,
//                 children: [
//                   if (onAddCalendar != null)
//                     OutlinedButton.icon(
//                       onPressed: onAddCalendar,
//                       icon: Icon(Icons.calendar_today, size: 14.sp),
//                       label: const Text('Add to Calendar'),
//                       style: OutlinedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12.w,
//                           vertical: 8.h,
//                         ),
//                       ),
//                     ),
//                   OutlinedButton.icon(
//                     onPressed: () {
//                       if (onViewQR != null) {
//                         onViewQR!();
//                       } else {
//                         // Show booking details QR code
//                         Get.dialog(
//                           Dialog(
//                             child: Padding(
//                               padding: EdgeInsets.all(16.w),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     'Booking ID',
//                                     style: TextStyle(
//                                       fontSize: AppSizes.textLarge18,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   SizedBox(height: 16.h),
//                                   Container(
//                                     padding: EdgeInsets.all(16.w),
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Colors.grey[300]!),
//                                     ),
//                                     child: Text(
//                                       booking.id,
//                                       style: TextStyle(
//                                         fontSize: AppSizes.textSmall12,
//                                         fontFamily: 'Monospace',
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: 16.h),
//                                   ElevatedButton(
//                                     onPressed: () => Get.back(),
//                                     child: const Text('Close'),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     icon: Icon(Icons.qr_code, size: 14.sp),
//                     label: const Text('View Booking ID'),
//                     style: OutlinedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 12.w,
//                         vertical: 8.h,
//                       ),
//                     ),
//                   ),
//                   if (onViewReceipt != null)
//                     OutlinedButton.icon(
//                       onPressed: onViewReceipt,
//                       icon: Icon(Icons.receipt, size: 14.sp),
//                       label: const Text('View Receipt'),
//                       style: OutlinedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12.w,
//                           vertical: 8.h,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//           // Notes Section (if any)
//           if (booking.notes.isNotEmpty)
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!, width: 1),
//                 ),
//                 color: Colors.grey[50],
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     Icons.note_outlined,
//                     size: 16.sp,
//                     color: Colors.grey[500],
//                   ),
//                   SizedBox(width: 8.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Notes',
//                           style: TextStyle(
//                             fontSize: AppSizes.textSmall12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                         SizedBox(height: 4.h),
//                         Text(
//                           booking.notes,
//                           style: TextStyle(
//                             fontSize: AppSizes.textSmall12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Points Awarded (if completed)
//           if (booking.isCompleted && booking.pointsAwarded)
//             Container(
//               padding: EdgeInsets.all(16.w),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[200]!, width: 1),
//                 ),
//                 color: Colors.green.withOpacity(0.05),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.star,
//                     size: 16.sp,
//                     color: Colors.green,
//                   ),
//                   SizedBox(width: 8.w),
//                   Expanded(
//                     child: Text(
//                       'Loyalty points awarded for this booking',
//                       style: TextStyle(
//                         fontSize: AppSizes.textSmall12,
//                         color: Colors.green,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// // Helper extension for status text
// extension BookingStatusExtension on Booking {
//   String get statusText {
//     switch (status) {
//       case 'pending':
//         return 'Pending';
//       case 'confirmed':
//         return 'Confirmed';
//       case 'in-progress':
//         return 'In Progress';
//       case 'completed':
//         return 'Completed';
//       case 'cancelled':
//         return 'Cancelled';
//       default:
//         return status;
//     }
//   }
// }