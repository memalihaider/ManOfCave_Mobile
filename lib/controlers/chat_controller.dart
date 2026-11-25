// controllers/chat_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../constants/app_colors.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../models/notification_model.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();
  NotificationController get _notificationController =>
      Get.find<NotificationController>();

  // Reactive state
  final RxList<ChatRoom> _chatRooms = <ChatRoom>[].obs;
  final RxMap<String, List<ChatMessage>> _roomMessages = <String, List<ChatMessage>>{}.obs;
  final Rx<ChatRoom?> _selectedRoom = Rx<ChatRoom?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxBool _isUploading = false.obs;
  final RxDouble _uploadProgress = 0.0.obs;
  final RxString _errorMessage = ''.obs;
  final RxMap<String, int> _unreadCounts = <String, int>{}.obs;

  // Stream controllers
  StreamSubscription<QuerySnapshot>? _roomsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  // Track sent message notifications to avoid duplicates
  final Set<String> _sentMessageNotifications = {};

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  Map<String, List<ChatMessage>> get roomMessages => _roomMessages;
  ChatRoom? get selectedRoom => _selectedRoom.value;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  bool get isUploading => _isUploading.value;
  double get uploadProgress => _uploadProgress.value;
  String get errorMessage => _errorMessage.value;
  int get totalUnreadCount => _unreadCounts.values.fold(0, (sum, count) => sum + count);

  // Auth getters
  bool get isAuthenticated => _auth.currentUser != null;
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _authController.currentUser.value?.name ?? 'User';
  String get currentUserRole => _authController.currentUser.value?.role ?? 'customer';
  String? get currentUserBranchId => _authController.currentUser.value?.branchId;
  String? get currentUserBranchName => _authController.currentUser.value?.branchName;

  // Role checks
  bool get isSuperAdmin => currentUserRole == 'super_admin';
  bool get isBranchAdmin => currentUserRole == 'admin' || currentUserRole == 'branch_admin';
  bool get isCustomer => currentUserRole == 'customer';
  bool get isStaff => currentUserRole == 'staff';

  bool _listening = false;

  @override
  void onInit() {
    super.onInit();
    // Chat streams start when chat UI opens (ensureListening).
  }

  @override
  void onClose() {
    _roomsSubscription?.cancel();
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    super.onClose();
  }

  /// Call from chat list / room screens — not at app cold start.
  Future<void> ensureListening() async {
    if (_listening) return;
    final userId = currentUserId;
    if (userId.isEmpty) return;
    _listening = true;
    await _loadUserChatRooms();
  }

  // Setup chat listeners based on user role
  Future<void> _setupChatListeners() async {
    await ensureListening();
  }

  // Load user's chat rooms
  Future<void> _loadUserChatRooms() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      if (isSuperAdmin) {
        await _loadSuperAdminRooms();
      } else if (isBranchAdmin) {
        await _loadBranchAdminRooms();
      } else if (isCustomer) {
        await _loadCustomerRooms();
      } else if (isStaff) {
        await _loadStaffRooms();
      }

    } catch (e) {
      _errorMessage.value = 'Failed to load chat rooms: $e';
      print('Error loading chat rooms: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Super Admin: Can chat with all branch admins
  Future<void> _loadSuperAdminRooms() async {
    final roomsQuery = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true);

    _roomsSubscription = roomsQuery.snapshots().listen((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      _chatRooms.assignAll(rooms);
      _updateUnreadCounts();
    });
  }

  // Branch Admin: Can chat with customers in their branch and super admin
  Future<void> _loadBranchAdminRooms() async {
    final roomsQuery = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true);

    _roomsSubscription = roomsQuery.snapshots().listen((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      _chatRooms.assignAll(rooms);
      _updateUnreadCounts();
    });
  }

  // Customer: Can chat only with their branch admin
  Future<void> _loadCustomerRooms() async {
    final roomsQuery = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true);

    _roomsSubscription = roomsQuery.snapshots().listen((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      _chatRooms.assignAll(rooms);
      _updateUnreadCounts();
    });
  }

  // Staff: Can chat with customers (if assigned) and branch admin
  Future<void> _loadStaffRooms() async {
    final roomsQuery = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true);

    _roomsSubscription = roomsQuery.snapshots().listen((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      _chatRooms.assignAll(rooms);
      _updateUnreadCounts();
    });
  }

  // Update unread counts
  void _updateUnreadCounts() {
    final counts = <String, int>{};
    for (final room in _chatRooms) {
      final hasRead = room.lastMessageSenderId == currentUserId ||
          room.readBy.contains(currentUserId);

      if (!hasRead && room.lastMessage.isNotEmpty) {
        counts[room.roomId] = room.unreadCount;
      }
    }
    _unreadCounts.assignAll(counts);
    update();
  }

  // Get unread count for specific room
  int getUnreadCount(String roomId) {
    return _unreadCounts[roomId] ?? 0;
  }

  // Select a chat room
  Future<void> selectRoom(ChatRoom room) async {
    _selectedRoom.value = room;
    await markRoomAsRead(room.roomId);
    await _loadRoomMessages(room.roomId);
  }

  // Load messages for a specific room
  Future<void> _loadRoomMessages(String roomId) async {
    if (_messageSubscriptions.containsKey(roomId)) {
      _messageSubscriptions[roomId]!.cancel();
      _messageSubscriptions.remove(roomId);
    }

    final messagesQuery = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50);

    _messageSubscriptions[roomId] = messagesQuery.snapshots().listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();

      // Check for new messages to show notification
      _checkForNewMessages(roomId, messages);

      _roomMessages[roomId] = messages;
      update();
    });
  }

  // Check for new messages and show notification
  void _checkForNewMessages(String roomId, List<ChatMessage> messages) {
    // Get previous messages
    final previousMessages = _roomMessages[roomId] ?? [];

    // If no previous messages, this is first load
    if (previousMessages.isEmpty) return;

    // Check for new messages (messages that are in current list but not in previous)
    for (final message in messages) {
      // Skip if message is from current user
      if (message.senderId == currentUserId) continue;

      // Check if this message is new (not in previous list)
      final isNew = !previousMessages.any((prev) => prev.messageId == message.messageId);

      if (isNew && !message.isDeleted) {
        // Show notification for new message
        _showNewMessageNotification(roomId, message);
      }
    }
  }

  // Show notification for new message
  void _showNewMessageNotification(String roomId, ChatMessage message) {
    // Prevent duplicate notifications for same message
    final notificationKey = 'chat_${message.messageId}';
    if (_sentMessageNotifications.contains(notificationKey)) return;
    _sentMessageNotifications.add(notificationKey);

    // Get room info
    final room = _chatRooms.where((r) => r.roomId == roomId).firstOrNull;
    if (room == null) return;

    // Get sender name
    final senderName = message.senderName.isNotEmpty
        ? message.senderName
        : room.participantNames[message.senderId] ?? 'Someone';

    // Format message preview
    String messagePreview = message.content;
    if (message.type == MessageType.image) {
      messagePreview = '📷 Image';
    } else if (message.type == MessageType.system) {
      messagePreview = 'ℹ️ System message';
    }

    // Truncate long messages
    if (messagePreview.length > 100) {
      messagePreview = '${messagePreview.substring(0, 100)}...';
    }

    // Show in-app notification
    _notificationController.showInAppNotification(
      title: '💬 New Message from $senderName',
      message: messagePreview,
      type: NotificationType.system,
      data: {
        'type': 'chat',
        'roomId': roomId,
        'messageId': message.messageId,
        'senderId': message.senderId,
        'senderName': senderName,
      },
    );

    // Also add to notifications collection for persistence
    _addChatToNotifications(roomId, message, senderName, messagePreview);

    print('🔔 New chat notification: $senderName: $messagePreview');
  }

  // Add chat message to user's notifications collection
  Future<void> _addChatToNotifications(String roomId, ChatMessage message, String senderName, String messagePreview) async {
    try {
      // Add to recipient's notifications collection
      final notificationRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc();

      await notificationRef.set({
        'type': 'chat',
        'title': 'New Message from $senderName',
        'message': messagePreview,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          'type': 'chat',
          'roomId': roomId,
          'messageId': message.messageId,
          'senderId': message.senderId,
          'senderName': senderName,
        },
        'imageUrl': null,
        'actionUrl': '/chat-room',
      });

    } catch (e) {
      print('Error adding chat to notifications: $e');
    }
  }

  // Get messages for a room
  List<ChatMessage> getMessages(String roomId) {
    return _roomMessages[roomId] ?? [];
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String roomId,
    required String content,
    String? replyToMessageId,
    String? replyToContent,
  }) async {
    try {
      _isSending.value = true;
      _errorMessage.value = '';

      final messageRef = _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        messageId: messageRef.id,
        roomId: roomId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentUserRole,
        content: content,
        type: MessageType.text,
        status: MessageStatus.sent,
        readBy: [currentUserId],
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
      );

      await messageRef.set(message.toFirestore());

      await _updateRoomAfterMessage(
        roomId: roomId,
        lastMessage: content,
        lastMessageSenderId: currentUserId,
        lastMessageSenderName: currentUserName,
        messageType: 'text',
      );

      _isSending.value = false;

    } catch (e) {
      _errorMessage.value = 'Failed to send message: $e';
      print('Error sending message: $e');
      _isSending.value = false;
    }
  }

  // Upload and send image message
  Future<void> sendImageMessage({
    required String roomId,
    required XFile imageFile,
    String? replyToMessageId,
    String? replyToContent,
  }) async {
    try {
      _isUploading.value = true;
      _uploadProgress.value = 0.0;
      _errorMessage.value = '';

      final messageRef = _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final tempMessageId = messageRef.id;

      // Create temporary message
      final tempMessage = ChatMessage(
        messageId: tempMessageId,
        roomId: roomId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentUserRole,
        content: '📷 Uploading image...',
        type: MessageType.image,
        status: MessageStatus.sending,
        readBy: [currentUserId],
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
        metadata: {'uploading': true},
      );

      await messageRef.set(tempMessage.toFirestore());

      // Add to local list for UI update
      final currentMessages = List<ChatMessage>.from(_roomMessages[roomId] ?? []);
      currentMessages.insert(0, tempMessage);
      _roomMessages[roomId] = currentMessages;
      update();

      final fileExtension = path.extension(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basenameWithoutExtension(imageFile.path)}$fileExtension';

      final storageRef = _storage
          .ref()
          .child('chat_images')
          .child(roomId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUserId,
          'roomId': roomId,
        },
      );

      final uploadTask = storageRef.putFile(File(imageFile.path), metadata);

      StreamSubscription<TaskSnapshot>? progressSubscription;
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        _uploadProgress.value = progress;

        final messages = List<ChatMessage>.from(_roomMessages[roomId] ?? []);
        final index = messages.indexWhere((m) => m.messageId == tempMessageId);
        if (index != -1) {
          final updatedMsg = messages[index].copyWith(
            metadata: {...?messages[index].metadata, 'uploadProgress': progress},
          );
          messages[index] = updatedMsg;
          _roomMessages[roomId] = messages;
          update();
        }
      });

      final snapshot = await uploadTask;
      await progressSubscription?.cancel();

      final imageUrl = await snapshot.ref.getDownloadURL();
      final fileSize = await File(imageFile.path).length();

      final finalMessage = ChatMessage(
        messageId: tempMessageId,
        roomId: roomId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentUserRole,
        content: '📷 Image',
        type: MessageType.image,
        status: MessageStatus.sent,
        readBy: [currentUserId],
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        replyToContent: replyToContent,
        fileUrl: imageUrl,
        fileSize: fileSize,
        metadata: {'uploading': false, 'uploadProgress': 100},
      );

      await messageRef.update(finalMessage.toFirestore());

      final finalMessages = List<ChatMessage>.from(_roomMessages[roomId] ?? []);
      final msgIndex = finalMessages.indexWhere((m) => m.messageId == tempMessageId);
      if (msgIndex != -1) {
        finalMessages[msgIndex] = finalMessage;
      } else {
        finalMessages.insert(0, finalMessage);
      }
      _roomMessages[roomId] = finalMessages;
      update();

      await _updateRoomAfterMessage(
        roomId: roomId,
        lastMessage: '📷 Image',
        lastMessageSenderId: currentUserId,
        lastMessageSenderName: currentUserName,
        messageType: 'image',
      );

      _isUploading.value = false;
      _uploadProgress.value = 0.0;

    } catch (e, stackTrace) {
      print('❌ Error uploading image: $e');
      print('📋 Stack trace: $stackTrace');

      _errorMessage.value = 'Failed to upload image: $e';
      _isUploading.value = false;
      _uploadProgress.value = 0.0;

      Get.snackbar(
        'Error',
        'Failed to upload image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Pick image from gallery
  Future<void> pickAndSendImage(String roomId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await sendImageMessage(roomId: roomId, imageFile: image);
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Pick image from camera
  Future<void> takeAndSendImage(String roomId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await sendImageMessage(roomId: roomId, imageFile: image);
      }
    } catch (e) {
      print('Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Update room after sending a message
  Future<void> _updateRoomAfterMessage({
    required String roomId,
    required String lastMessage,
    required String lastMessageSenderId,
    required String lastMessageSenderName,
    String messageType = 'text',
  }) async {
    try {
      final now = DateTime.now();
      final readBy = [lastMessageSenderId];

      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .update({
        'lastMessage': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageSenderName': lastMessageSenderName,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageType': messageType,
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': FieldValue.increment(1),
        'readBy': readBy,
      });

      final roomIndex = _chatRooms.indexWhere((r) => r.roomId == roomId);
      if (roomIndex != -1) {
        final updatedRoom = _chatRooms[roomIndex].copyWith(
          lastMessage: lastMessage,
          lastMessageSenderId: lastMessageSenderId,
          lastMessageSenderName: lastMessageSenderName,
          lastMessageTime: now,
          unreadCount: _chatRooms[roomIndex].unreadCount + 1,
          updatedAt: now,
          readBy: readBy,
        );
        _chatRooms[roomIndex] = updatedRoom;
        _updateUnreadCounts();
      }

    } catch (e) {
      print('Error updating room: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'This message was deleted',
        'type': MessageType.text.name,
        'fileUrl': null,
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Message deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting message: $e');
      Get.snackbar(
        'Error',
        'Failed to delete message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Edit a message
  Future<void> editMessage(String roomId, String messageId, String newContent) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Message edited',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error editing message: $e');
      Get.snackbar(
        'Error',
        'Failed to edit message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Copy message to clipboard
  Future<void> copyMessage(String content) async {
    try {
      await Get.defaultDialog(
        title: 'Copy Message',
        middleText: 'Message copied to clipboard',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primaryGold,
        onConfirm: () => Get.back(),
      );
      print('Copy to clipboard: $content');
    } catch (e) {
      print('Error copying message: $e');
    }
  }

  // Mark room as read
  Future<void> markRoomAsRead(String roomId) async {
    try {
      final roomDoc = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .get();

      if (roomDoc.exists) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        final currentReadBy = List<String>.from(roomData['readBy'] ?? []);

        if (!currentReadBy.contains(currentUserId)) {
          currentReadBy.add(currentUserId);

          await _firestore
              .collection('chatRooms')
              .doc(roomId)
              .update({
            'readBy': currentReadBy,
            'unreadCount': 0,
          });

          final roomIndex = _chatRooms.indexWhere((r) => r.roomId == roomId);
          if (roomIndex != -1) {
            final updatedRoom = _chatRooms[roomIndex].copyWith(
              readBy: currentReadBy,
              unreadCount: 0,
            );
            _chatRooms[roomIndex] = updatedRoom;
            _updateUnreadCounts();
          }
        }
      }

      // Mark all messages as read
      final unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        final messageData = doc.data();
        final readBy = List<String>.from(messageData['readBy'] ?? []);
        if (!readBy.contains(currentUserId)) {
          readBy.add(currentUserId);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }

    } catch (e) {
      print('Error marking room as read: $e');
    }
  }

  // Create a new chat room
  Future<ChatRoom?> createChatRoom({
    required String otherUserId,
    required String otherUserName,
    required String otherUserRole,
    String? branchId,
    String? branchName,
    String? customerId,
    String? customerName,
    required String roomType,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final existingRoom = await _findExistingRoom(
        otherUserId: otherUserId,
        roomType: roomType,
        branchId: branchId,
        customerId: customerId,
      );

      if (existingRoom != null) {
        _isLoading.value = false;
        return existingRoom;
      }

      final roomId = _firestore.collection('chatRooms').doc().id;
      final now = DateTime.now();

      final participants = [currentUserId, otherUserId];
      final participantNames = {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      };
      final participantRoles = {
        currentUserId: currentUserRole,
        otherUserId: otherUserRole,
      };
      final readBy = [currentUserId];

      final newRoom = ChatRoom(
        roomId: roomId,
        lastMessage: '',
        lastMessageSenderId: '',
        lastMessageSenderName: '',
        lastMessageTime: now,
        unreadCount: 0,
        participants: participants,
        participantNames: participantNames,
        participantRoles: participantRoles,
        roomType: roomType,
        branchId: branchId,
        branchName: branchName,
        customerId: customerId,
        customerName: customerName,
        adminId: isSuperAdmin ? currentUserId : otherUserId,
        adminName: isSuperAdmin ? currentUserName : otherUserName,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        readBy: readBy,
      );

      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .set(newRoom.toFirestore());

      final systemMessage = ChatMessage(
        messageId: _firestore.collection('messages').doc().id,
        roomId: roomId,
        senderId: 'system',
        senderName: 'System',
        senderRole: 'system',
        content: 'Chat started',
        type: MessageType.system,
        status: MessageStatus.sent,
        readBy: participants,
        timestamp: now,
      );

      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(systemMessage.messageId)
          .set(systemMessage.toFirestore());

      _chatRooms.add(newRoom);
      _updateUnreadCounts();

      _isLoading.value = false;
      return newRoom;

    } catch (e) {
      _errorMessage.value = 'Failed to create chat room: $e';
      print('Error creating chat room: $e');
      _isLoading.value = false;
      return null;
    }
  }

  // Find existing chat room
  Future<ChatRoom?> _findExistingRoom({
    required String otherUserId,
    required String roomType,
    String? branchId,
    String? customerId,
  }) async {
    try {
      Query query = _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: currentUserId)
          .where('roomType', isEqualTo: roomType)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        final room = ChatRoom.fromFirestore(doc);
        if (room.participants.contains(otherUserId)) {
          if (roomType == 'customer_branch') {
            if (room.customerId == customerId) return room;
          } else if (roomType == 'branch_super') {
            if (room.branchId == branchId) return room;
          } else {
            return room;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error finding existing room: $e');
      return null;
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String roomId, bool isTyping) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .update({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([currentUserId])
            : FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  // Get typing users for a room
  Stream<List<String>> getTypingUsers(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      final typingUsers = data?['typingUsers'] as List<dynamic>?;
      return typingUsers?.cast<String>() ?? [];
    });
  }

  // Clear all messages (for testing/debugging)
  Future<void> clearAllChats() async {
    try {
      _isLoading.value = true;

      final roomsQuery = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (final roomDoc in roomsQuery.docs) {
        await roomDoc.reference.delete();
      }

      _chatRooms.clear();
      _roomMessages.clear();
      _selectedRoom.value = null;
      _unreadCounts.clear();

      _isLoading.value = false;

    } catch (e) {
      print('Error clearing chats: $e');
      _isLoading.value = false;
    }
  }

  // Refresh chat data
  Future<void> refreshChats() async {
    await _roomsSubscription?.cancel();
    _roomsSubscription = null;
    _listening = false;
    await ensureListening();
  }

  // Get user's display name from room
  String getUserDisplayName(ChatRoom room) {
    if (room.participantNames.containsKey(currentUserId)) {
      return room.participantNames[currentUserId]!;
    }
    return currentUserName;
  }

  // Check if user has unread messages
  bool hasUnreadMessages() {
    return totalUnreadCount > 0;
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Get chat room by ID
  ChatRoom? getChatRoomById(String roomId) {
    return _chatRooms.where((room) => room.roomId == roomId).firstOrNull;
  }

  // Check if user can send message in room
  bool canSendMessage(String roomId) {
    final room = getChatRoomById(roomId);
    if (room == null) return false;
    return room.participants.contains(currentUserId) && room.isActive;
  }

  // Get other participant info
  Map<String, String> getOtherParticipantInfo(ChatRoom room) {
    final otherParticipantId = room.participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => room.participants.first,
    );

    return {
      'id': otherParticipantId,
      'name': room.participantNames[otherParticipantId] ?? 'Unknown',
      'role': room.participantRoles[otherParticipantId] ?? 'user',
    };
  }
}

// Keep only ONE extension
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}