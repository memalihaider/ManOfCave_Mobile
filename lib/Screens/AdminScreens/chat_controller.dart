// import 'package:get/get.dart';
//
// class ChatMessage {
//   final String id;
//   final String senderId;
//   final String senderName;
//   final String message;
//   final DateTime timestamp;
//   final bool isMe;
//   final MessageType type;
//
//   ChatMessage({
//     required this.id,
//     required this.senderId,
//     required this.senderName,
//     required this.message,
//     required this.timestamp,
//     required this.isMe,
//     this.type = MessageType.text,
//   });
// }
//
// enum MessageType {
//   text,
//   image,
// }
//
// class ChatContact {
//   final String id;
//   final String name;
//   final String? imageUrl;
//   final String lastMessage;
//   final DateTime lastMessageTime;
//   final bool isOnline;
//   final int unreadCount;
//
//   ChatContact({
//     required this.id,
//     required this.name,
//     this.imageUrl,
//     required this.lastMessage,
//     required this.lastMessageTime,
//     required this.isOnline,
//     required this.unreadCount,
//   });
// }
//
// class ChatController extends GetxController {
//   // Current user info
//   final currentUserId = 'user_1';
//   final currentUserName = 'Admin User';
//
//   // Reactive lists
//   var contacts = <ChatContact>[].obs;
//   var messages = <ChatMessage>[].obs;
//   var selectedContact = Rxn<ChatContact>();
//   var isLoading = false.obs;
//   var newMessage = ''.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadContacts();
//   }
//
//   void loadContacts() {
//     isLoading.value = true;
//
//     // Simulate API delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       contacts.assignAll([
//         ChatContact(
//           id: 'contact_1',
//           name: 'John Doe',
//           imageUrl: 'https://example.com/john.jpg',
//           lastMessage: 'Hi, I need to reschedule my appointment',
//           lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
//           isOnline: true,
//           unreadCount: 2,
//         ),
//         ChatContact(
//           id: 'contact_2',
//           name: 'Jane Smith',
//           imageUrl: 'https://example.com/jane.jpg',
//           lastMessage: 'Thanks for the great service!',
//           lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
//           isOnline: false,
//           unreadCount: 0,
//         ),
//         ChatContact(
//           id: 'contact_3',
//           name: 'Mike Wilson',
//           lastMessage: 'Can I book for tomorrow?',
//           lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
//           isOnline: true,
//           unreadCount: 1,
//         ),
//         ChatContact(
//           id: 'contact_4',
//           name: 'Sarah Johnson',
//           imageUrl: 'https://example.com/sarah.jpg',
//           lastMessage: 'The haircut was perfect!',
//           lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
//           isOnline: false,
//           unreadCount: 0,
//         ),
//         ChatContact(
//           id: 'contact_5',
//           name: 'Robert Brown',
//           lastMessage: 'Need to cancel my booking',
//           lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
//           isOnline: true,
//           unreadCount: 3,
//         ),
//       ]);
//
//       isLoading.value = false;
//     });
//   }
//
//   void selectContact(ChatContact contact) {
//     selectedContact.value = contact;
//     loadMessages(contact.id);
//   }
//
//   void loadMessages(String contactId) {
//     messages.assignAll([
//       ChatMessage(
//         id: '1',
//         senderId: 'contact_1',
//         senderName: 'John Doe',
//         message: 'Hello, I need to reschedule my appointment for tomorrow.',
//         timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
//         isMe: false,
//       ),
//       ChatMessage(
//         id: '2',
//         senderId: 'user_1',
//         senderName: 'Admin User',
//         message: 'Sure, John. What time works better for you?',
//         timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
//         isMe: true,
//       ),
//       ChatMessage(
//         id: '3',
//         senderId: 'contact_1',
//         senderName: 'John Doe',
//         message: 'Can we do 3 PM instead of 2 PM?',
//         timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
//         isMe: false,
//       ),
//       ChatMessage(
//         id: '4',
//         senderId: 'user_1',
//         senderName: 'Admin User',
//         message: 'Yes, 3 PM works perfectly. I\'ve updated your appointment.',
//         timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
//         isMe: true,
//       ),
//       ChatMessage(
//         id: '5',
//         senderId: 'contact_1',
//         senderName: 'John Doe',
//         message: 'Thank you so much!',
//         timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
//         isMe: false,
//       ),
//     ]);
//   }
//
//   void sendMessage() {
//     if (newMessage.value.trim().isEmpty) return;
//
//     final message = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       senderId: currentUserId,
//       senderName: currentUserName,
//       message: newMessage.value.trim(),
//       timestamp: DateTime.now(),
//       isMe: true,
//     );
//
//     messages.add(message);
//     newMessage.value = '';
//
//     // Simulate reply after 1 second
//     Future.delayed(const Duration(seconds: 1), () {
//       final reply = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         senderId: selectedContact.value!.id,
//         senderName: selectedContact.value!.name,
//         message: 'Thanks for your message!',
//         timestamp: DateTime.now(),
//         isMe: false,
//       );
//       messages.add(reply);
//     });
//   }
//
//   void clearChat() {
//     if (selectedContact.value != null) {
//       messages.clear();
//       Get.snackbar(
//         'Cleared',
//         'Chat history cleared',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   void refreshContacts() {
//     loadContacts();
//   }
// }