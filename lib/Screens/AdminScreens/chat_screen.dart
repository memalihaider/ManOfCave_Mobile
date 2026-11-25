// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../constants/app_sizes.dart';
// import '../../widgets/chat_card.dart';
// import '../../widgets/chat_message_bubble.dart';
// import 'chat_controller.dart';
//
// class ChatScreen extends StatelessWidget {
//   ChatScreen({super.key});
//
//   final ChatController controller = Get.put(ChatController());
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Get.theme;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Obx(() {
//           if (controller.selectedContact.value != null) {
//             return Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => controller.selectedContact.value = null,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(controller.selectedContact.value!.name),
//               ],
//             );
//           }
//           return const Text("Chat");
//         }),
//         centerTitle: false,
//         actions: [
//           if (controller.selectedContact.value != null) ...[
//             IconButton(
//               icon: const Icon(Icons.info_outline),
//               onPressed: () => _showContactInfo(),
//               tooltip: 'Contact Info',
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete_outline),
//               onPressed: controller.clearChat,
//               tooltip: 'Clear Chat',
//             ),
//           ],
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: controller.refreshContacts,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Obx(() {
//         // Show chat conversation
//         if (controller.selectedContact.value != null) {
//           return _buildChatConversation(theme);
//         }
//
//         // Show contacts list
//         return _buildContactsList(theme);
//       }),
//     );
//   }
//
//   Widget _buildContactsList(ThemeData theme) {
//     return Column(
//       children: [
//         // Search bar
//         Padding(
//           padding: AppSizes.paddingAll(16),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(AppSizes.radiusMedium12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 5,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search contacts...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 14,
//                 ),
//               ),
//               onChanged: (query) {
//                 // Implement search functionality
//               },
//             ),
//           ),
//         ),
//
//         // Online status summary
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               const Icon(Icons.circle, size: 8, color: Colors.green),
//               const SizedBox(width: 8),
//               Text(
//                 '${controller.contacts.where((c) => c.isOnline).length} online',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '${controller.contacts.length} total contacts',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // Contacts list
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: () async {
//               controller.refreshContacts();
//             },
//             child: Obx(() {
//               if (controller.isLoading.value) {
//                 return const Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }
//
//               if (controller.contacts.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.chat_bubble_outline,
//                         size: 60,
//                         color: theme.hintColor.withOpacity(0.5),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No contacts yet',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: theme.hintColor,
//                         ),
//                       ),
//                       Text(
//                         'Your chat contacts will appear here',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.hintColor.withOpacity(0.7),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               return ListView.builder(
//                 padding: AppSizes.paddingAll(16),
//                 itemCount: controller.contacts.length,
//                 itemBuilder: (context, index) {
//                   final contact = controller.contacts[index];
//                   return ChatContactCard(
//                     name: contact.name,
//                     imageUrl: contact.imageUrl,
//                     lastMessage: contact.lastMessage,
//                     lastMessageTime: contact.lastMessageTime,
//                     isOnline: contact.isOnline,
//                     unreadCount: contact.unreadCount,
//                     onTap: () => controller.selectContact(contact),
//                   );
//                 },
//               );
//             }),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildChatConversation(ThemeData theme) {
//     return Column(
//       children: [
//         // Contact header
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: theme.cardColor,
//             border: Border(
//               bottom: BorderSide(color: theme.dividerColor),
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: theme.primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Center(
//                   child: Text(
//                     controller.selectedContact.value!.name.substring(0, 1).toUpperCase(),
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       color: theme.primaryColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     controller.selectedContact.value!.name,
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: theme.primaryColorDark,
//                     ),
//                   ),
//                   Text(
//                     controller.selectedContact.value!.isOnline ? 'Online' : 'Last seen recently',
//                     style: theme.textTheme.labelSmall?.copyWith(
//                       color: controller.selectedContact.value!.isOnline
//                           ? Colors.green
//                           : theme.hintColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//
//         // Messages list
//         Expanded(
//           child: Obx(() => ListView.builder(
//             padding: AppSizes.paddingAll(16),
//             reverse: true,
//             itemCount: controller.messages.length,
//             itemBuilder: (context, index) {
//               final message = controller.messages[controller.messages.length - 1 - index];
//               return ChatMessageBubble(
//                 message: message.message,
//                 timestamp: message.timestamp,
//                 isMe: message.isMe,
//                 senderName: message.senderName,
//               );
//             },
//           )),
//         ),
//
//         // Message input
//         _buildMessageInput(theme),
//       ],
//     );
//   }
//
//   Widget _buildMessageInput(ThemeData theme) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         border: Border(
//           top: BorderSide(color: theme.dividerColor),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Attachment button
//           IconButton(
//             icon: Icon(Icons.attach_file, color: theme.primaryColor),
//             onPressed: () {
//               // Implement attachment
//             },
//           ),
//
//           // Message input field
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: TextField(
//                 controller: TextEditingController(text: controller.newMessage.value),
//                 onChanged: (value) => controller.newMessage.value = value,
//                 decoration: const InputDecoration(
//                   hintText: 'Type a message...',
//                   border: InputBorder.none,
//                 ),
//                 maxLines: null,
//                 textInputAction: TextInputAction.send,
//                 onSubmitted: (_) => controller.sendMessage(),
//               ),
//             ),
//           ),
//
//           // Send button
//           Obx(() => IconButton(
//             icon: Icon(
//               Icons.send,
//               color: controller.newMessage.value.trim().isNotEmpty
//                   ? theme.primaryColor
//                   : Colors.grey,
//             ),
//             onPressed: controller.newMessage.value.trim().isNotEmpty
//                 ? controller.sendMessage
//                 : null,
//           )),
//         ],
//       ),
//     );
//   }
//
//   void _showContactInfo() {
//     final contact = controller.selectedContact.value!;
//
//     Get.bottomSheet(
//       Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(AppSizes.radius(16)),
//           ),
//         ),
//         child: Padding(
//           padding: AppSizes.paddingAll(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Draggable handle
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Contact avatar
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Get.theme.primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(40),
//                   image: contact.imageUrl != null
//                       ? DecorationImage(
//                     image: NetworkImage(contact.imageUrl!),
//                     fit: BoxFit.cover,
//                   )
//                       : null,
//                 ),
//                 child: contact.imageUrl == null
//                     ? Center(
//                   child: Text(
//                     contact.name.substring(0, 1).toUpperCase(),
//                     style: Get.theme.textTheme.titleLarge?.copyWith(
//                       color: Get.theme.primaryColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 )
//                     : null,
//               ),
//
//               const SizedBox(height: 16),
//
//               Text(
//                 contact.name,
//                 style: Get.theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Get.theme.primaryColorDark,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.circle,
//                     size: 8,
//                     color: contact.isOnline ? Colors.green : Colors.grey,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     contact.isOnline ? 'Online' : 'Offline',
//                     style: Get.theme.textTheme.bodyMedium?.copyWith(
//                       color: Get.theme.hintColor,
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//
//               // Action buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildContactActionButton(
//                     icon: Icons.call,
//                     label: 'Call',
//                     onTap: () {
//                       Get.back();
//                       Get.snackbar(
//                         'Calling',
//                         'Call feature coming soon',
//                       );
//                     },
//                   ),
//                   _buildContactActionButton(
//                     icon: Icons.videocam,
//                     label: 'Video',
//                     onTap: () {
//                       Get.back();
//                       Get.snackbar(
//                         'Video Call',
//                         'Video call feature coming soon',
//                       );
//                     },
//                   ),
//                   _buildContactActionButton(
//                     icon: Icons.email,
//                     label: 'Email',
//                     onTap: () {
//                       Get.back();
//                       Get.snackbar(
//                         'Email',
//                         'Email feature coming soon',
//                       );
//                     },
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContactActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: Get.theme.primaryColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(25),
//           ),
//           child: IconButton(
//             icon: Icon(icon, color: Get.theme.primaryColor),
//             onPressed: onTap,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: Get.theme.textTheme.labelSmall?.copyWith(
//             color: Get.theme.hintColor,
//           ),
//         ),
//       ],
//     );
//   }
// }