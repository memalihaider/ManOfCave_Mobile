// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class UserProfile {
//   final String id;
//   final String name;
//   final String email;
//   final String? phone;
//   final String? avatarUrl;
//   final String role;
//   final DateTime joinDate;
//   final Map<String, dynamic>? additionalInfo;
//
//   UserProfile({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.phone,
//     this.avatarUrl,
//     required this.role,
//     required this.joinDate,
//     this.additionalInfo,
//   });
// }
//
// class ProfileController extends GetxController {
//   var userProfile = UserProfile(
//     id: 'user_1',
//     name: 'Admin User',
//     email: 'admin@mancave.com',
//     phone: '+1 (555) 123-4567',
//     avatarUrl: 'https://example.com/admin-avatar.jpg',
//     role: 'Administrator',
//     joinDate: DateTime(2024, 1, 1),
//     additionalInfo: {
//       'address': '123 Main Street, New York, NY 10001',
//       'bio': 'Experienced salon manager with 5+ years of experience',
//       'notifications': true,
//       'darkMode': false,
//     },
//   ).obs;
//
//   var isLoading = false.obs;
//   var isEditing = false.obs;
//
//   // Editing controllers
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final addressController = TextEditingController();
//   final bioController = TextEditingController();
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadProfile();
//   }
//
//   void _loadProfile() {
//     isLoading.value = true;
//
//     // Simulate loading
//     Future.delayed(const Duration(milliseconds: 300), () {
//       nameController.text = userProfile.value.name;
//       emailController.text = userProfile.value.email;
//       phoneController.text = userProfile.value.phone ?? '';
//       addressController.text = userProfile.value.additionalInfo?['address'] ?? '';
//       bioController.text = userProfile.value.additionalInfo?['bio'] ?? '';
//       isLoading.value = false;
//     });
//   }
//
//   void toggleEditMode() {
//     isEditing.value = !isEditing.value;
//   }
//
//   void saveProfile() {
//     final newProfile = UserProfile(
//       id: userProfile.value.id,
//       name: nameController.text,
//       email: emailController.text,
//       phone: phoneController.text.isNotEmpty ? phoneController.text : null,
//       avatarUrl: userProfile.value.avatarUrl,
//       role: userProfile.value.role,
//       joinDate: userProfile.value.joinDate,
//       additionalInfo: {
//         'address': addressController.text,
//         'bio': bioController.text,
//         'notifications': userProfile.value.additionalInfo?['notifications'] ?? true,
//         'darkMode': userProfile.value.additionalInfo?['darkMode'] ?? false,
//       },
//     );
//
//     userProfile.value = newProfile;
//     isEditing.value = false;
//
//     Get.snackbar(
//       'Success',
//       'Profile updated successfully',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
//
//   void changePassword() {
//     Get.defaultDialog(
//       title: 'Change Password',
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('Enter your new password'),
//           const SizedBox(height: 16),
//           TextField(
//             decoration: const InputDecoration(
//               labelText: 'Current Password',
//               border: OutlineInputBorder(),
//             ),
//             obscureText: true,
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             decoration: const InputDecoration(
//               labelText: 'New Password',
//               border: OutlineInputBorder(),
//             ),
//             obscureText: true,
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             decoration: const InputDecoration(
//               labelText: 'Confirm New Password',
//               border: OutlineInputBorder(),
//             ),
//             obscureText: true,
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: Get.back,
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Get.back();
//             Get.snackbar(
//               'Success',
//               'Password changed successfully',
//               snackPosition: SnackPosition.BOTTOM,
//             );
//           },
//           child: const Text('Change Password'),
//         ),
//       ],
//     );
//   }
//
//   void toggleNotification(bool value) {
//     final currentInfo = Map<String, dynamic>.from(userProfile.value.additionalInfo ?? {});
//     currentInfo['notifications'] = value;
//     userProfile.value = userProfile.value.copyWith(
//       additionalInfo: currentInfo,
//     );
//   }
//
//   void toggleDarkMode(bool value) {
//     final currentInfo = Map<String, dynamic>.from(userProfile.value.additionalInfo ?? {});
//     currentInfo['darkMode'] = value;
//     userProfile.value = userProfile.value.copyWith(
//       additionalInfo: currentInfo,
//     );
//   }
//
//   void logout() {
//     Get.defaultDialog(
//       title: 'Logout',
//       middleText: 'Are you sure you want to logout?',
//       textConfirm: 'Logout',
//       textCancel: 'Cancel',
//       onConfirm: () {
//         Get.back();
//         // Navigate to login screen
//         Get.offAllNamed('/login');
//       },
//     );
//   }
// }
//
// extension UserProfileCopyWith on UserProfile {
//   UserProfile copyWith({
//     String? id,
//     String? name,
//     String? email,
//     String? phone,
//     String? avatarUrl,
//     String? role,
//     DateTime? joinDate,
//     Map<String, dynamic>? additionalInfo,
//   }) {
//     return UserProfile(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       avatarUrl: avatarUrl ?? this.avatarUrl,
//       role: role ?? this.role,
//       joinDate: joinDate ?? this.joinDate,
//       additionalInfo: additionalInfo ?? this.additionalInfo,
//     );
//   }
// }