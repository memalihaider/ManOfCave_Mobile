// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../constants/app_colors.dart';
// import '../constants/app_sizes.dart';
//
// class CustomDrawer extends StatelessWidget {
//   final Function(int) onItemSelected;
//
//   const CustomDrawer({super.key, required this.onItemSelected});
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       width: MediaQuery.of(context).size.width * 0.75,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           // Header
//           Container(
//             height: 200,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   AppColors.primaryGold,
//                   AppColors.primaryDark,
//                 ],
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: AppColors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 50,
//                     color: AppColors.primaryGold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "Admin User",
//                   style: TextStyle(
//                     color: AppColors.white,
//                     fontSize: AppSizes.font(20),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   "admin@example.com",
//                   style: TextStyle(
//                     color: AppColors.white.withOpacity(0.8),
//                     fontSize: AppSizes.font(14),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Menu Items
//           _buildMenuItem(
//             icon: Icons.dashboard,
//             title: "Dashboard",
//             onTap: () => onItemSelected(0),
//           ),
//           _buildMenuItem(
//             icon: Icons.view_list,
//             title: "All Bookings",
//             onTap: () => onItemSelected(3),
//           ),
//           _buildMenuItem(
//             icon: Icons.add_circle,
//             title: "Add New Booking",
//             onTap: () => onItemSelected(5),
//           ),
//           _buildMenuItem(
//             icon: Icons.inventory,
//             title: "Add Product/Service",
//             onTap: () => onItemSelected(6),
//           ),
//           _buildMenuItem(
//             icon: Icons.assessment,
//             title: "Generate Reports",
//             onTap: () => onItemSelected(7),
//           ),
//           _buildMenuItem(
//             icon: Icons.money_off,
//             title: "Add Expenses",
//             onTap: () => onItemSelected(8),
//           ),
//           _buildMenuItem(
//             icon: Icons.account_balance,
//             title: "Portal Assignment",
//             onTap: () => onItemSelected(9),
//           ),
//           _buildMenuItem(
//             icon: Icons.chat,
//             title: "Chat App",
//             onTap: () => onItemSelected(10),
//           ),
//           _buildMenuItem(
//             icon: Icons.person,
//             title: "Account/Profile",
//             onTap: () => onItemSelected(11),
//           ),
//
//           const Divider(),
//
//           _buildMenuItem(
//             icon: Icons.logout,
//             title: "Logout",
//             onTap: () => Get.offAllNamed('/login'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: AppColors.primaryDark),
//       title: Text(
//         title,
//         style: TextStyle(
//           fontSize: AppSizes.font(16),
//           color: AppColors.primaryDark,
//         ),
//       ),
//       onTap: onTap,
//     );
//   }
// }